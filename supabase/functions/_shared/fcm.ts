type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

export type FcmMessage = {
  topic: string;
  notification: { title: string; body: string };
  data: Record<string, string>;
  android?: Record<string, unknown>;
  apns?: Record<string, unknown>;
};

let cachedToken: { value: string; expiresAt: number; projectId: string } | null =
  null;

function base64Url(bytes: Uint8Array) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function jwtPart(value: unknown) {
  return base64Url(new TextEncoder().encode(JSON.stringify(value)));
}

function pemBytes(privateKey: string) {
  const binary = atob(
    privateKey.replace("-----BEGIN PRIVATE KEY-----", "")
      .replace("-----END PRIVATE KEY-----", "")
      .replaceAll(/\s/g, ""),
  );
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

async function accessToken(): Promise<{ token: string; projectId: string }> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is not configured");
  const account = JSON.parse(raw) as ServiceAccount;
  if (!account.project_id || !account.client_email || !account.private_key) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is incomplete");
  }

  const now = Math.floor(Date.now() / 1000);
  if (cachedToken != null && cachedToken.expiresAt > now + 60) {
    return { token: cachedToken.value, projectId: cachedToken.projectId };
  }

  const signingInput = `${jwtPart({ alg: "RS256", typ: "JWT" })}.${jwtPart({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemBytes(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
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
  cachedToken = {
    value: data.access_token,
    expiresAt: now + data.expires_in,
    projectId: account.project_id,
  };
  return { token: cachedToken.value, projectId: cachedToken.projectId };
}

export function topicFor(prefix: string, businessId: string) {
  const safe = businessId.replace(/[^A-Za-z0-9_.~-]/g, "");
  if (!safe) throw new Error("Invalid business id for FCM topic");
  return `${prefix}-${safe}`;
}

export async function sendFcm(message: FcmMessage) {
  const { token, projectId } = await accessToken();
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message }),
    },
  );
  if (!response.ok) {
    throw new Error(`FCM rejected send (${response.status}): ${await response.text()}`);
  }
}
