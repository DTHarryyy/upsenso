// Emails a newly-created employee their login credentials.
//
// Called by the app right after create_employee_auth_account succeeds
// (employees_remote_ds.dart → sendCredentialsEmail). The account already
// exists at that point, so the client treats this call as best-effort: a
// delivery failure here must not roll back or block employee creation.
//
// AUTHENTICATION — re-derives the caller's business + permission server-side
// (get_my_business_id / has_permission), same pattern as verify-play-purchase.
// A prior version of this function only checked that *a* JWT was present,
// which let any signed-in user (not just employees.create holders) send mail
// through our Resend domain to any address with attacker-chosen content —
// closed here.
//
// Deploy WITH jwt verification (the caller is a signed-in owner/manager):
//   supabase functions deploy send-employee-credentials
//
// Required secrets (supabase secrets set ...):
//   RESEND_API_KEY      — Resend API key, "Sending access" scoped to upsenso.com
//   EMPLOYEE_FROM_EMAIL — verified sender, e.g. "UPSENSO <welcome@upsenso.com>"
// Optional:
//   EMPLOYEE_LOGIN_URL  — link shown in the email (defaults to app.upsenso.com)
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY (platform-provided)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function failure(stage: string, detail: string, status: number): Response {
  console.error(`send-employee-credentials [${stage}] ${detail}`);
  return json({ error: "Could not send credentials email", stage }, status);
}

interface Payload {
  email?: string;
  password?: string;
  fullName?: string;
  businessName?: string;
  loginUrl?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Missing authorization" }, 401);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const apiKey = Deno.env.get("RESEND_API_KEY");
  const fromEmail = Deno.env.get("EMPLOYEE_FROM_EMAIL");
  if (!apiKey || !fromEmail) {
    return failure(
      "secrets",
      `missing ${!apiKey ? "RESEND_API_KEY" : ""}${
        !apiKey && !fromEmail ? " and " : ""
      }${!fromEmail ? "EMPLOYEE_FROM_EMAIL" : ""}`,
      500,
    );
  }

  try {
    const { email, password, fullName, businessName, loginUrl } =
      (await req.json()) as Payload;

    if (!email || !password) {
      return json({ error: "email and password are required" }, 400);
    }

    // Caller's business + permission — derived server-side, never trusted
    // from the body, so this can't be used to mail-bomb arbitrary addresses.
    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: bizId, error: bizErr } = await userClient.rpc(
      "get_my_business_id",
    );
    if (bizErr || !bizId) return json({ error: "No active business" }, 403);
    const { data: mayCreate, error: permErr } = await userClient.rpc(
      "has_permission",
      { permission_code: "employees.create" },
    );
    if (permErr || mayCreate !== true) {
      return json({ error: "Not allowed to create employees" }, 403);
    }

    let brand = businessName?.trim() || null;
    if (!brand) {
      const admin = createClient(url, serviceKey);
      const { data: biz } = await admin
        .from("businesses")
        .select("name")
        .eq("id", bizId)
        .maybeSingle();
      brand = biz?.name ?? null;
    }
    brand = brand ?? "UPSENSO";

    const link = loginUrl ?? Deno.env.get("EMPLOYEE_LOGIN_URL") ??
      "https://app.upsenso.com";

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [email],
        subject: `Your ${brand} account is ready`,
        html: buildHtml({ fullName, email, password, brand, link }),
        text: buildText({ fullName, email, password, brand, link }),
      }),
    });

    if (!res.ok) {
      const detail = await res.text();
      return failure("resend_send", `${res.status} ${detail}`, 502);
    }

    return json({ ok: true }, 200);
  } catch (e) {
    return failure("unhandled", e instanceof Error ? e.message : String(e), 500);
  }
});

// Mirrors the look of the Supabase Auth OTP email (card, wordmark header,
// mono credential box) so every email the platform sends reads as one
// product. Table-based layout — Outlook/Gmail strip <style> blocks and flex
// layouts, so inline styles on <table>/<td> are the only reliable way to get
// consistent rendering across clients.
function buildHtml(args: {
  fullName?: string;
  email: string;
  password: string;
  brand: string;
  link: string;
}): string {
  const brand = escapeHtml(args.brand);
  const email = escapeHtml(args.email);
  const password = escapeHtml(args.password);
  const link = escapeHtml(args.link);
  const greeting = args.fullName ? `Hi ${escapeHtml(args.fullName)},` : "Hi,";

  return `<!doctype html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Your ${brand} account is ready</title>
</head>
<body style="margin:0;padding:0;background:#f6f8fb;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;">

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:40px 20px;">
<tr>
<td align="center">

<table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background:#ffffff;border:1px solid #e5e7eb;border-radius:16px;overflow:hidden;">

<!-- HEADER -->
<tr>
<td style="padding:40px 40px 24px 40px;">
<div style="font-size:24px;font-weight:700;">
  <span style="color:#0057FF;">Upsenso</span><span style="color:#22C55E;">.</span>
</div>
</td>
</tr>

<!-- TITLE -->
<tr>
<td style="padding:0 40px;">
<h1 style="margin:0;font-size:26px;color:#111827;font-weight:700;">Welcome to ${brand}</h1>
<p style="margin:16px 0 0 0;font-size:15px;line-height:1.6;color:#4b5563;">${greeting} An account has been created for you on ${brand}. Use the credentials below to sign in.</p>
</td>
</tr>

<!-- CREDENTIALS -->
<tr>
<td style="padding:32px 40px;">
<div style="background:#f8fafc;border:1px solid #dbe3ee;border-radius:14px;padding:20px 24px;">
  <p style="margin:0 0 4px 0;font-size:12px;font-weight:600;letter-spacing:0.4px;text-transform:uppercase;color:#6b7280;">Email</p>
  <p style="margin:0 0 16px 0;font-size:16px;color:#111827;font-weight:600;">${email}</p>
  <p style="margin:0 0 4px 0;font-size:12px;font-weight:600;letter-spacing:0.4px;text-transform:uppercase;color:#6b7280;">Temporary password</p>
  <p style="margin:0;font-size:20px;font-weight:700;letter-spacing:1.5px;color:#111827;font-family:Consolas,Monaco,'Courier New',monospace;">${password}</p>
</div>
</td>
</tr>

<!-- CTA -->
<tr>
<td align="center" style="padding:0 40px 8px 40px;">
<a href="${link}" style="display:inline-block;background:#0057FF;color:#ffffff;text-decoration:none;font-size:15px;font-weight:600;padding:14px 32px;border-radius:10px;">Open ${brand}</a>
</td>
</tr>

<!-- INFO -->
<tr>
<td style="padding:24px 40px 0 40px;">
<p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">For your security, please change this password after your first sign-in.</p>
</td>
</tr>

<!-- FOOTER -->
<tr>
<td style="padding:32px 40px 40px 40px;">
<div style="height:1px;background:#e5e7eb;margin-bottom:20px;"></div>
<p style="margin:0;font-size:12px;line-height:1.6;color:#9ca3af;">If you weren't expecting this email, you can ignore it — the account stays inactive until someone signs in with it.</p>
<p style="margin:12px 0 0 0;font-size:12px;color:#9ca3af;">© ${new Date().getFullYear()} Upsenso</p>
</td>
</tr>

</table>

</td>
</tr>
</table>

</body>
</html>`;
}

// Plain-text alternative — improves deliverability/spam scoring and covers
// clients that render text/plain instead of the HTML part.
function buildText(args: {
  fullName?: string;
  email: string;
  password: string;
  brand: string;
  link: string;
}): string {
  const greeting = args.fullName ? `Hi ${args.fullName},` : "Hi,";
  return [
    `Welcome to ${args.brand}`,
    "",
    greeting,
    `An account has been created for you on ${args.brand}. Use the credentials below to sign in:`,
    "",
    `Email: ${args.email}`,
    `Temporary password: ${args.password}`,
    "",
    "For your security, please change this password after your first sign-in.",
    "",
    `Open ${args.brand}: ${args.link}`,
  ].join("\n");
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
