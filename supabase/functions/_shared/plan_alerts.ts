import { sendFcm, topicFor } from "./fcm.ts";

type Trigger = "entitlement_changed" | "device_registration";
type Evaluation = { sentKinds: string[] };

function displayCount(count: number, singular: string, plural: string) {
  return `${count} ${count === 1 ? singular : plural}`;
}

export function resourceAlertState(input: {
  branches: number;
  maxBranches: number | null;
  seats: number;
  maxSeats: number | null;
}) {
  const excessBranches = input.maxBranches == null
    ? 0
    : Math.max(0, input.branches - input.maxBranches);
  const excessSeats = input.maxSeats == null
    ? 0
    : Math.max(0, input.seats - input.maxSeats);
  const parts = [
    excessBranches > 0
      ? displayCount(excessBranches, "branch is", "branches are") + " read-only"
      : null,
    excessSeats > 0
      ? displayCount(excessSeats, "employee needs", "employees need") + " a seat"
      : null,
  ].filter(Boolean);
  return {
    active: excessBranches > 0 || excessSeats > 0,
    signature: `${input.branches}:${input.maxBranches}:${input.seats}:${input.maxSeats}`,
    body: `${parts.join(" and ")}. Nothing was deleted; upgrade to restore access.`,
  };
}

export function deviceAlertState(input: {
  isRegistered: boolean;
  devices: number;
  maxDevices: number | null;
}) {
  const active = !input.isRegistered && input.maxDevices != null &&
    input.devices >= input.maxDevices;
  return {
    active,
    signature: `${input.devices}:${input.maxDevices}`,
    body: active
      ? `A device could not start cloud backup because all ${input.maxDevices} device ${input.maxDevices === 1 ? "slot is" : "slots are"} in use.`
      : "",
  };
}

async function subjectHash(value: string) {
  const bytes = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(bytes))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

// deno-lint-ignore no-explicit-any
async function countRows(admin: any, table: string, businessId: string, activeOnly = false) {
  const keyColumn = table === "registered_devices" ? "device_uid" : "id";
  let query = admin
    .from(table)
    .select(keyColumn, { count: "exact", head: true })
    .eq("business_id", businessId);
  if (activeOnly) query = query.eq("is_active", true);
  if (table === "registered_devices") query = query.is("revoked_at", null);
  const { count, error } = await query;
  if (error) throw error;
  return Number(count ?? 0);
}

// deno-lint-ignore no-explicit-any
async function claim(admin: any, args: {
  businessId: string;
  kind: string;
  subject: string;
  active: boolean;
  signature: string;
}) {
  const { data, error } = await admin.rpc("claim_plan_alert_delivery", {
    p_business: args.businessId,
    p_alert_kind: args.kind,
    p_subject_key: args.subject,
    p_is_active: args.active,
    p_signature: args.signature,
  });
  if (error) throw error;
  return data === true;
}

// deno-lint-ignore no-explicit-any
async function markSent(admin: any, businessId: string, kind: string, subject: string) {
  const { error } = await admin.rpc("mark_plan_alert_sent", {
    p_business: businessId,
    p_alert_kind: kind,
    p_subject_key: subject,
  });
  if (error) throw error;
}

/// Recomputes all counts from Supabase and publishes only newly-active alerts.
// deno-lint-ignore no-explicit-any
export async function evaluateAndPublishPlanAlerts(
  admin: any,
  businessId: string,
  options: { trigger: Trigger; deviceUid?: string },
): Promise<Evaluation> {
  const { data: limitRows, error: limitsError } = await admin.rpc(
    "effective_limits_for",
    { p_business: businessId },
  );
  if (limitsError) throw limitsError;
  const limits = Array.isArray(limitRows) ? limitRows[0] : limitRows;
  if (!limits) throw new Error("No effective limits found");

  const [branches, seats, devices] = await Promise.all([
    countRows(admin, "branches", businessId),
    countRows(admin, "employees", businessId, true),
    countRows(admin, "registered_devices", businessId),
  ]);
  const maxBranches = limits.max_branches == null ? null : Number(limits.max_branches);
  const maxSeats = limits.max_seats == null ? null : Number(limits.max_seats);
  const maxDevices = limits.max_devices == null ? null : Number(limits.max_devices);
  const resources = resourceAlertState({
    branches,
    maxBranches,
    seats,
    maxSeats,
  });
  const sentKinds: string[] = [];

  const shouldSendResources = await claim(admin, {
    businessId,
    kind: "resource_over_cap",
    subject: "",
    active: resources.active,
    signature: resources.signature,
  });
  if (shouldSendResources) {
    await sendFcm({
      topic: topicFor("plan-alerts", businessId),
      notification: {
        title: "Plan limit exceeded",
        body: resources.body,
      },
      data: { type: "plan_limit", kind: "resource_over_cap" },
      android: { priority: "high", notification: { channel_id: "plan_alerts" } },
      apns: { payload: { aps: { sound: "default" } } },
    });
    await markSent(admin, businessId, "resource_over_cap", "");
    sentKinds.push("resource_over_cap");
  }

  if (options.trigger === "device_registration" && options.deviceUid) {
    const subject = await subjectHash(options.deviceUid);
    const { data: registered, error: registeredError } = await admin
      .from("registered_devices")
      .select("device_uid")
      .eq("business_id", businessId)
      .eq("device_uid", options.deviceUid)
      .is("revoked_at", null)
      .maybeSingle();
    if (registeredError) throw registeredError;
    const device = deviceAlertState({
      isRegistered: registered != null,
      devices,
      maxDevices,
    });
    const shouldSendDevice = await claim(admin, {
      businessId,
      kind: "device_cap",
      subject,
      active: device.active,
      signature: device.signature,
    });
    if (shouldSendDevice) {
      await sendFcm({
        topic: topicFor("plan-alerts", businessId),
        notification: {
          title: "Device limit reached",
          body: device.body,
        },
        data: { type: "plan_limit", kind: "device_cap" },
        android: { priority: "high", notification: { channel_id: "plan_alerts" } },
        apns: { payload: { aps: { sound: "default" } } },
      });
      await markSent(admin, businessId, "device_cap", subject);
      sentKinds.push("device_cap");
    }
  }

  return { sentKinds };
}
