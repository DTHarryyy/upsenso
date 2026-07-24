// Shared Google Play Developer API helpers for the billing edge functions.
// Used by verify-play-purchase (first purchase) and google-play-rtdn (lifecycle).
//
// Auth is a service-account JWT assertion → OAuth2 access token for the
// androidpublisher scope. Nothing here trusts the client; the token is verified
// against Google, and Google's reported state is authoritative.

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

export interface PlaySubscription {
  raw: Record<string, unknown>;
  subscriptionState: string; // SUBSCRIPTION_STATE_*
  productId: string | null; // lineItems[0].productId
  basePlanId: string | null; // lineItems[0].offerDetails.basePlanId
  expiryTime: string | null; // ISO 8601
  acknowledgementState: string; // ACKNOWLEDGEMENT_STATE_*
  autoRenewing: boolean;
}

// Google's subscriptionState → our access decision.
export type PlayAccessDecision =
  | "grant_active"
  | "grant_canceled"
  | "expire"
  | "ignore";

function b64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function b64urlJson(obj: unknown): string {
  return b64url(new TextEncoder().encode(JSON.stringify(obj)));
}

function pemToPkcs8(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
}

export function parseServiceAccount(jsonStr: string): ServiceAccount {
  const sa = JSON.parse(jsonStr);
  if (!sa.client_email || !sa.private_key) {
    throw new Error("Service account JSON missing client_email/private_key");
  }
  return { client_email: sa.client_email, private_key: sa.private_key };
}

// OAuth2 access token for the Android Publisher scope via a signed JWT bearer.
export async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${b64urlJson(header)}.${b64urlJson(claim)}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToPkcs8(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const assertion = `${unsigned}.${b64url(new Uint8Array(sig))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const body = await res.json();
  if (!res.ok || !body.access_token) {
    throw new Error(
      `Google token exchange failed: ${res.status} ${JSON.stringify(body)}`,
    );
  }
  return body.access_token as string;
}

// purchases.subscriptionsv2.get — the authoritative subscription snapshot.
export async function getSubscription(
  accessToken: string,
  packageName: string,
  purchaseToken: string,
): Promise<PlaySubscription> {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptionsv2/tokens/${
      encodeURIComponent(purchaseToken)
    }`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  const body = await res.json();
  if (!res.ok) {
    throw new Error(
      `subscriptionsv2.get failed: ${res.status} ${JSON.stringify(body)}`,
    );
  }
  const lineItems = Array.isArray(body.lineItems) ? body.lineItems : [];
  const first = (lineItems[0] ?? {}) as Record<string, unknown>;
  const offer = (first.offerDetails ?? {}) as Record<string, unknown>;
  const autoRenew = (first.autoRenewingPlan ?? {}) as Record<string, unknown>;
  return {
    raw: body,
    subscriptionState: (body.subscriptionState as string) ??
      "SUBSCRIPTION_STATE_UNSPECIFIED",
    productId: (first.productId as string) ?? null,
    basePlanId: (offer.basePlanId as string) ?? null,
    expiryTime: (first.expiryTime as string) ?? null,
    acknowledgementState: (body.acknowledgementState as string) ??
      "ACKNOWLEDGEMENT_STATE_UNSPECIFIED",
    autoRenewing: Boolean(autoRenew.autoRenewEnabled),
  };
}

// purchases.subscriptions.acknowledge (v1) — stops Google's 3-day auto-refund.
// A 400 ("already acknowledged") is a benign no-op and is swallowed.
export async function acknowledgeSubscription(
  accessToken: string,
  packageName: string,
  productId: string,
  purchaseToken: string,
): Promise<void> {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptions/${productId}/tokens/${
      encodeURIComponent(purchaseToken)
    }:acknowledge`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: "{}",
  });
  if (!res.ok && res.status !== 400) {
    throw new Error(`acknowledge failed: ${res.status} ${await res.text()}`);
  }
}

// subscriptionState → grant / expire / ignore.
export function decideFromState(state: string): PlayAccessDecision {
  switch (state) {
    case "SUBSCRIPTION_STATE_ACTIVE":
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
      return "grant_active";
    case "SUBSCRIPTION_STATE_CANCELED": // auto-renew off, still paid to expiry
      return "grant_canceled";
    case "SUBSCRIPTION_STATE_ON_HOLD":
    case "SUBSCRIPTION_STATE_PAUSED":
    case "SUBSCRIPTION_STATE_EXPIRED":
      return "expire";
    default:
      return "ignore";
  }
}
