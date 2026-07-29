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

/// Which step of the Google round trip failed, and whether retrying can help.
///
/// The distinction matters to the CLIENT: a transient fault deserves the
/// "retrying automatically" path, but a config fault (bad key, missing Play
/// Console grant, wrong package) will answer the same way forever — telling the
/// user to wait for a retry that can never succeed is how a charged purchase
/// silently rots until Google refunds it.
export type PlayStage =
  | "parse_sa"
  | "google_token"
  | "google_get_sub"
  | "google_app_access"
  | "google_ack";

export class PlayApiError extends Error {
  readonly stage: PlayStage;

  /// Upstream HTTP status; 0 when the call never got a response.
  readonly status: number;

  constructor(stage: PlayStage, status: number, message: string) {
    super(message);
    this.name = "PlayApiError";
    this.stage = stage;
    this.status = status;
  }

  /// 401/403/404 from Google mean our credentials or package name are wrong.
  /// No amount of retrying fixes that — it needs a human in a console.
  get isConfigFault(): boolean {
    return this.stage === "parse_sa" ||
      this.status === 401 || this.status === 403 || this.status === 404;
  }
}

/// One retry for faults that are plausibly transient (5xx, transport). Config
/// faults short-circuit — re-asking Google the same broken question is waste.
async function withRetry<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (e) {
    if (e instanceof PlayApiError && e.isConfigFault) throw e;
    await new Promise((r) => setTimeout(r, 400));
    return await fn();
  }
}

export interface PlaySubscription {
  raw: Record<string, unknown>;
  subscriptionState: string; // SUBSCRIPTION_STATE_*
  productId: string | null; // lineItems[0].productId
  basePlanId: string | null; // lineItems[0].offerDetails.basePlanId
  expiryTime: string | null; // ISO 8601
  acknowledgementState: string; // ACKNOWLEDGEMENT_STATE_*
  autoRenewing: boolean;

  /// What the BUYER passed to Play at purchase time — our sha256(business_id).
  /// Google echoing it back is the only proof that the account presenting a
  /// token is the account that paid for it. Null for purchases made before the
  /// client started sending it.
  obfuscatedAccountId: string | null;

  /// The subscription this one replaced (upgrade / downgrade / re-signup).
  /// Present only on the FIRST fetch after a plan change, which is what lets us
  /// mark the old token superseded instead of treating it as a live purchase.
  linkedPurchaseToken: string | null;
}

// Google's subscriptionState → our access decision.
export type PlayAccessDecision =
  | "grant_active"
  | "grant_canceled"
  | "expire"
  | "ignore";

// ── Pub/Sub push authentication ─────────────────────────────────────────────

/// Google's OIDC signing keys. Cached because a push subscription delivers one
/// notification per event and re-fetching the key set every time would put a
/// Google round trip in front of every renewal.
let jwksCache: { at: number; keys: Record<string, CryptoKey> } | null = null;
const JWKS_TTL_MS = 60 * 60 * 1000;
const GOOGLE_JWKS_URL = "https://www.googleapis.com/oauth2/v3/certs";

async function googleJwks(): Promise<Record<string, CryptoKey>> {
  if (jwksCache && Date.now() - jwksCache.at < JWKS_TTL_MS) {
    return jwksCache.keys;
  }
  const res = await fetch(GOOGLE_JWKS_URL);
  if (!res.ok) {
    throw new Error(`jwks fetch failed: ${res.status}`);
  }
  const body = await res.json();
  const keys: Record<string, CryptoKey> = {};
  for (const jwk of body.keys ?? []) {
    if (jwk.kty !== "RSA" || !jwk.kid) continue;
    keys[jwk.kid] = await crypto.subtle.importKey(
      "jwk",
      { kty: jwk.kty, n: jwk.n, e: jwk.e, alg: "RS256", ext: true },
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["verify"],
    );
  }
  jwksCache = { at: Date.now(), keys };
  return keys;
}

function b64urlToBytes(s: string): Uint8Array {
  const pad = s.replace(/-/g, "+").replace(/_/g, "/");
  const padded = pad + "=".repeat((4 - (pad.length % 4)) % 4);
  return Uint8Array.from(atob(padded), (c) => c.charCodeAt(0));
}

/// Verify the `Authorization: Bearer <jwt>` that Pub/Sub attaches to a push when
/// the subscription is configured with `--push-auth-service-account`.
///
/// Checks signature against Google's JWKS, issuer, expiry, and that the token
/// was minted for OUR service account. Without this the endpoint's only defence
/// was a secret in the URL — logged in plaintext on every request, and enough on
/// its own to revoke any tenant's subscription.
export async function verifyGooglePushToken(
  authHeader: string | null,
  expectedEmail: string,
): Promise<{ ok: boolean; reason?: string }> {
  const raw = authHeader?.replace(/^Bearer\s+/i, "").trim();
  if (!raw) return { ok: false, reason: "no bearer token" };

  const parts = raw.split(".");
  if (parts.length !== 3) return { ok: false, reason: "malformed jwt" };

  let header: Record<string, unknown>;
  let claims: Record<string, unknown>;
  try {
    header = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[0])));
    claims = JSON.parse(new TextDecoder().decode(b64urlToBytes(parts[1])));
  } catch (_) {
    return { ok: false, reason: "undecodable jwt" };
  }

  if (header.alg !== "RS256") return { ok: false, reason: `alg ${header.alg}` };
  const keys = await googleJwks();
  const key = keys[header.kid as string];
  if (!key) return { ok: false, reason: "unknown kid" };

  const signed = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
  const valid = await crypto.subtle.verify(
    { name: "RSASSA-PKCS1-v1_5" },
    key,
    b64urlToBytes(parts[2]),
    signed,
  );
  if (!valid) return { ok: false, reason: "bad signature" };

  const iss = claims.iss as string | undefined;
  if (iss !== "https://accounts.google.com" && iss !== "accounts.google.com") {
    return { ok: false, reason: `issuer ${iss}` };
  }
  const exp = Number(claims.exp ?? 0);
  if (!exp || exp * 1000 < Date.now()) return { ok: false, reason: "expired" };

  // The identity Pub/Sub was told to sign as. Anyone can obtain a Google-signed
  // token; only our push subscription can obtain one for THIS service account.
  const email = claims.email as string | undefined;
  if (!email || email !== expectedEmail) {
    return { ok: false, reason: `subject ${email ?? "none"}` };
  }
  if (claims.email_verified === false) {
    return { ok: false, reason: "email not verified" };
  }
  return { ok: true };
}

/// Lowercase hex sha256 — must match the client's
/// `sha256.convert(utf8.encode(businessId)).toString()` exactly, because the
/// result is compared against what Google echoes back as the buyer's
/// obfuscatedExternalAccountId.
export async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

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

/// Undo the ways a shell, CI runner, or dashboard paste mangles a JSON secret.
///
/// The service-account key is a multi-line JSON blob containing a PEM, which is
/// exactly the shape that survives transport badly: quotes get backslash-escaped,
/// the whole value gets wrapped in another pair of quotes, or a here-doc adds
/// them. Accepting base64 sidesteps all of it — that is the recommended way to
/// set this secret.
function normaliseSecretJson(raw: string): string {
  let s = raw.trim();

  // Base64 (no braces at all) — decode first. Preferred form: quoting-proof.
  if (s.length > 0 && !s.startsWith("{")) {
    try {
      const decoded = atob(s.replace(/\s+/g, ""));
      if (decoded.trimStart().startsWith("{")) return decoded;
    } catch (_) {
      // Not base64; fall through and let the quote repairs below have a go.
    }
  }

  // Wrapped in an extra pair of quotes by the setter.
  if (
    (s.startsWith('"') && s.endsWith('"')) ||
    (s.startsWith("'") && s.endsWith("'"))
  ) {
    s = s.slice(1, -1).trim();
  }

  // Escaped quotes with no outer quotes: {\"type\": \"service_account\", …}.
  // Only unescape when the value is NOT already valid JSON, so a correctly-set
  // secret is never touched.
  if (s.startsWith("{") && s.includes('\\"')) {
    try {
      JSON.parse(s);
    } catch (_) {
      s = s.replace(/\\"/g, '"');
    }
  }
  return s;
}

export function parseServiceAccount(jsonStr: string): ServiceAccount {
  const normalised = normaliseSecretJson(jsonStr);
  let sa: Record<string, unknown>;
  try {
    sa = JSON.parse(normalised);
  } catch (e) {
    // Shape hints only — never the key material itself.
    const head = normalised.slice(0, 2).replace(/[^\x20-\x7E]/g, "?");
    throw new PlayApiError(
      "parse_sa",
      0,
      `service account secret is not valid JSON (${e}). ` +
        `Length ${jsonStr.length}, starts with "${head}". Re-set ` +
        `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON to the raw key file, or to its ` +
        `base64 encoding to avoid shell quoting.`,
    );
  }
  if (typeof sa !== "object" || sa === null) {
    throw new PlayApiError(
      "parse_sa",
      0,
      "service account secret decoded to a JSON value that is not an object",
    );
  }
  if (!sa.client_email || !sa.private_key) {
    throw new PlayApiError("parse_sa", 0, "service account JSON missing client_email/private_key");
  }
  // Secrets set through a shell often arrive with the PEM newlines escaped, which
  // makes the base64 decode below fail with a message that says nothing about the
  // real cause. Normalise instead of letting it surface as a mystery 500.
  const privateKey = String(sa.private_key).replace(/\\n/g, "\n");
  if (!privateKey.includes("-----BEGIN PRIVATE KEY-----")) {
    throw new PlayApiError("parse_sa", 0, "private_key is not a PKCS#8 PEM block");
  }
  return { client_email: String(sa.client_email), private_key: privateKey };
}

/// Access tokens live an hour; a warm instance re-using one saves a round trip
/// on every verify. Refreshed early so an in-flight call can't race the expiry.
let cachedToken: { value: string; expiresAt: number } | null = null;

export async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const nowMs = Date.now();
  if (cachedToken && cachedToken.expiresAt > nowMs) return cachedToken.value;
  const token = await withRetry(() => fetchAccessToken(sa));
  cachedToken = { value: token, expiresAt: nowMs + 55 * 60 * 1000 };
  return token;
}

// OAuth2 access token for the Android Publisher scope via a signed JWT bearer.
async function fetchAccessToken(sa: ServiceAccount): Promise<string> {
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

  let assertion: string;
  try {
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
    assertion = `${unsigned}.${b64url(new Uint8Array(sig))}`;
  } catch (e) {
    // A key that won't import is a broken secret, not a flaky network.
    throw new PlayApiError("parse_sa", 0, `private_key could not be imported: ${e}`);
  }

  let res: Response;
  try {
    res = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    });
  } catch (e) {
    throw new PlayApiError("google_token", 0, `token endpoint unreachable: ${e}`);
  }
  const body = await res.json().catch(() => ({}));
  if (!res.ok || !body.access_token) {
    throw new PlayApiError(
      "google_token",
      res.status,
      `token exchange failed: ${res.status} ${JSON.stringify(body)}`,
    );
  }
  return body.access_token as string;
}

// purchases.subscriptionsv2.get — the authoritative subscription snapshot.
export function getSubscription(
  accessToken: string,
  packageName: string,
  purchaseToken: string,
): Promise<PlaySubscription> {
  return withRetry(() => fetchSubscription(accessToken, packageName, purchaseToken));
}

async function fetchSubscription(
  accessToken: string,
  packageName: string,
  purchaseToken: string,
): Promise<PlaySubscription> {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptionsv2/tokens/${
      encodeURIComponent(purchaseToken)
    }`;
  let res: Response;
  try {
    res = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
  } catch (e) {
    throw new PlayApiError("google_get_sub", 0, `androidpublisher unreachable: ${e}`);
  }
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new PlayApiError(
      "google_get_sub",
      res.status,
      `subscriptionsv2.get failed: ${res.status} ${JSON.stringify(body)}`,
    );
  }
  const lineItems = Array.isArray(body.lineItems) ? body.lineItems : [];
  const first = (lineItems[0] ?? {}) as Record<string, unknown>;
  const offer = (first.offerDetails ?? {}) as Record<string, unknown>;
  const autoRenew = (first.autoRenewingPlan ?? {}) as Record<string, unknown>;
  const ids = (body.externalAccountIdentifiers ?? {}) as Record<string, unknown>;
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
    obfuscatedAccountId:
      (ids.obfuscatedExternalAccountId as string | undefined) ?? null,
    linkedPurchaseToken: (body.linkedPurchaseToken as string | undefined) ??
      null,
  };
}

/// monetization.subscriptions.list — the cheapest read that proves Play actually
/// knows this service account for this package.
///
/// A purchase token is not needed, which is the whole point: it turns "is billing
/// configured?" into a question answerable without spending real money. A 401/403
/// here means the SA was never invited to Play Console (or lacks app access), and
/// a 404 means the package name is wrong — the two setup mistakes that otherwise
/// only surface when a paying user hits them.
export function listSubscriptionProductIds(
  accessToken: string,
  packageName: string,
): Promise<string[]> {
  return withRetry(() => fetchSubscriptionProductIds(accessToken, packageName));
}

async function fetchSubscriptionProductIds(
  accessToken: string,
  packageName: string,
): Promise<string[]> {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/subscriptions?pageSize=100`;
  let res: Response;
  try {
    res = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
  } catch (e) {
    throw new PlayApiError("google_app_access", 0, `androidpublisher unreachable: ${e}`);
  }
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new PlayApiError(
      "google_app_access",
      res.status,
      `subscriptions.list failed: ${res.status} ${JSON.stringify(body)}`,
    );
  }
  const rows = Array.isArray(body.subscriptions) ? body.subscriptions : [];
  return rows
    .map((s: Record<string, unknown>) => s.productId as string | undefined)
    .filter((id: string | undefined): id is string => typeof id === "string");
}

// purchases.subscriptions.acknowledge (v1) — stops Google's 3-day auto-refund.
// Only "already acknowledged" is a benign no-op; every other 400 is a real
// request fault and must not be reported as a successful acknowledgement.
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
  let res: Response;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: "{}",
    });
  } catch (e) {
    throw new PlayApiError("google_ack", 0, `acknowledge unreachable: ${e}`);
  }
  if (res.ok) return;
  const detail = await res.text();
  // Google reports an already-acknowledged token as a 400. Swallowing every 400
  // hid genuinely malformed requests behind a "success" — and an ack that never
  // happened means Google refunds the user in three days.
  if (res.status === 400 && /already\s*acknowledged/i.test(detail)) return;
  throw new PlayApiError(
    "google_ack",
    res.status,
    `acknowledge failed: ${res.status} ${detail}`,
  );
}

// subscriptionState → grant / expire / ignore.
//
// Hold and pause revoke access, per Google's own guidance — they are not
// terminal though: a recovery/restart notification re-fetches this state and
// re-applies, so access returns without a new purchase.
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
    case "SUBSCRIPTION_STATE_PENDING":
    case "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED":
      return "ignore";
    default:
      // Unmapped states must be visible — a silent no-op here is how a new
      // Play state would quietly stop updating entitlement.
      console.error(`decideFromState: unmapped subscriptionState "${state}"`);
      return "ignore";
  }
}
