import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { evaluateAndPublishPlanAlerts } from "../_shared/plan_alerts.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);

  try {
    const body = await req.json() as { trigger?: string; deviceUid?: string };
    if (body.trigger !== "entitlement_changed" && body.trigger !== "device_registration") {
      return json({ error: "Invalid trigger" }, 400);
    }
    const deviceUid = String(body.deviceUid ?? "").trim().slice(0, 200);
    if (body.trigger === "device_registration" && !deviceUid) {
      return json({ error: "Missing deviceUid" }, 400);
    }

    const url = Deno.env.get("SUPABASE_URL")!;
    const userClient = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authorization } },
    });
    const { data: auth, error: authError } = await userClient.auth.getUser();
    if (authError || auth.user == null) return json({ error: "Unauthorized" }, 401);
    const { data: businessId, error: businessError } = await userClient.rpc(
      "get_my_business_id",
    );
    if (businessError || typeof businessId !== "string" || !businessId) {
      return json({ error: "Business access denied" }, 403);
    }

    const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const result = await evaluateAndPublishPlanAlerts(admin, businessId, {
      trigger: body.trigger,
      deviceUid: deviceUid || undefined,
    });
    return json({ ok: true, ...result });
  } catch (error) {
    console.error("send-plan-limit-fcm", error);
    return json({ error: "Could not evaluate plan alerts" }, 500);
  }
});
