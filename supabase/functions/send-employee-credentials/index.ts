// Emails a newly-created employee their login credentials.
//
// Called by the app right after a manager creates an employee account. The
// password is only known client-side at creation time, so it is passed in the
// request body and relayed over HTTPS via the email provider (Resend).
//
// Required secrets (set with `supabase secrets set ...`):
//   RESEND_API_KEY      — Resend API key
//   EMPLOYEE_FROM_EMAIL — verified sender, e.g. "UPSENSO <no-reply@yourdomain>"
// Optional:
//   EMPLOYEE_LOGIN_URL  — link shown in the email (defaults to the web app)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

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

  // Only an authenticated caller (the manager) may trigger this. The platform
  // verifies the JWT when verify_jwt is enabled; we also require the header.
  if (!req.headers.get("Authorization")) {
    return json({ error: "Missing authorization" }, 401);
  }

  try {
    const { email, password, fullName, businessName, loginUrl } =
      (await req.json()) as Payload;

    if (!email || !password) {
      return json({ error: "email and password are required" }, 400);
    }

    const apiKey = Deno.env.get("RESEND_API_KEY");
    const fromEmail = Deno.env.get("EMPLOYEE_FROM_EMAIL");
    if (!apiKey || !fromEmail) {
      return json({ error: "Email provider not configured" }, 500);
    }

    const brand = businessName ?? "UPSENSO";
    const link = loginUrl ?? Deno.env.get("EMPLOYEE_LOGIN_URL") ??
      "https://upsenso.pages.dev";

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
      }),
    });

    if (!res.ok) {
      const detail = await res.text();
      console.error(`Resend rejected send: ${res.status} ${detail}`);
      return json({ error: "Email send failed", detail }, 502);
    }

    return json({ ok: true }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function buildHtml(args: {
  fullName?: string;
  email: string;
  password: string;
  brand: string;
  link: string;
}): string {
  const greeting = args.fullName ? `Hi ${escapeHtml(args.fullName)},` : "Hi,";
  return `
  <div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;color:#101828">
    <h2 style="color:#101828">Welcome to ${escapeHtml(args.brand)}</h2>
    <p>${greeting}</p>
    <p>An account has been created for you. Use the credentials below to sign in:</p>
    <div style="background:#f4f5f7;border-radius:10px;padding:16px;margin:16px 0">
      <p style="margin:0 0 8px"><strong>Email:</strong> ${escapeHtml(args.email)}</p>
      <p style="margin:0"><strong>Temporary password:</strong> ${escapeHtml(args.password)}</p>
    </div>
    <p>For your security, please change this password after your first sign-in.</p>
    <p><a href="${escapeHtml(args.link)}" style="color:#2563eb">Open ${escapeHtml(args.brand)}</a></p>
  </div>`;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
