// Sends a tenant-scoped low-stock FCM notification.
//
// Required secret: FIREBASE_SERVICE_ACCOUNT_JSON, a service-account JSON for
// Firebase project `upsenso`, stored in Supabase Edge Function secrets.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Payload = {
  businessId?: string;
  branchId?: string;
  variantId?: string;
  productName?: string;
  quantity?: number;
  threshold?: number;
};
type ServiceAccount = { project_id: string; client_email: string; private_key: string };
let cachedToken: { value: string; expiresAt: number } | null = null;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function text(value: unknown, maxLength: number) {
  return String(value ?? "").trim().slice(0, maxLength);
}

function topicFor(businessId: string) {
  return `low-stock-${businessId.replace(/[^A-Za-z0-9_.~-]/g, "")}`;
}

function base64Url(bytes: Uint8Array) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function jwtPart(value: unknown) {
  return base64Url(new TextEncoder().encode(JSON.stringify(value)));
}

function pemBytes(privateKey: string) {
  const binary = atob(privateKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s/g, ""));
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

async function fcmToken(): Promise<{ token: string; projectId: string }> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is not configured");
  const account = JSON.parse(raw) as ServiceAccount;
  if (!account.project_id || !account.client_email || !account.private_key) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is incomplete");
  }
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken != null && cachedToken.expiresAt > now + 60) {
    return { token: cachedToken.value, projectId: account.project_id };
  }
  const signingInput = `${jwtPart({ alg: "RS256", typ: "JWT" })}.${jwtPart({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })}`;
  const key = await crypto.subtle.importKey(
    "pkcs8", pemBytes(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(signingInput),
  );
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${signingInput}.${base64Url(new Uint8Array(signature))}`,
    }),
  });
  if (!response.ok) throw new Error("Could not authenticate to FCM");
  const data = await response.json() as { access_token: string; expires_in: number };
  cachedToken = { value: data.access_token, expiresAt: now + data.expires_in };
  return { token: cachedToken.value, projectId: account.project_id };
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);

  try {
    const payload = await req.json() as Payload;
    const businessId = text(payload.businessId, 64);
    const variantId = text(payload.variantId, 64);
    const branchId = text(payload.branchId, 64);
    const productName = text(payload.productName, 120);
    const quantity = Number(payload.quantity);
    const threshold = Number(payload.threshold);
    if (!businessId || !variantId || !productName || !Number.isFinite(quantity) ||
        !Number.isFinite(threshold)) return json({ error: "Invalid payload" }, 400);

    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authorization } } },
    );
    const { data: auth, error: authError } = await userClient.auth.getUser();
    if (authError || auth.user == null) return json({ error: "Unauthorized" }, 401);
    const { data: callerBusinessId, error: businessError } = await userClient.rpc(
      "get_my_business_id",
    );
    if (businessError || callerBusinessId !== businessId) {
      return json({ error: "Business access denied" }, 403);
    }

    const { token, projectId } = await fcmToken();
    const display = (value: number) => Number.isInteger(value) ? String(value) : value.toFixed(2);
    const fcm = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ message: {
        topic: topicFor(businessId),
        notification: {
          title: `Low stock: ${productName}`,
          body: `${productName} is at ${display(quantity)}; reorder level is ${display(threshold)}.`,
        },
        data: {
          type: "low_stock", business_id: businessId, variant_id: variantId,
          branch_id: branchId, quantity: String(quantity), threshold: String(threshold),
        },
        android: { priority: "high", notification: { channel_id: "low_stock_alerts" } },
        apns: { payload: { aps: { sound: "default" } } },
      } }),
    });
    if (!fcm.ok) {
      console.error("FCM rejected send", fcm.status, await fcm.text());
      return json({ error: "FCM delivery failed" }, 502);
    }
    return json({ ok: true });
  } catch (error) {
    console.error("send-low-stock-fcm", error);
    return json({ error: "Could not send low-stock notification" }, 500);
  }
});
