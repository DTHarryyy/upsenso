import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { deviceAlertState, resourceAlertState } from "./plan_alerts.ts";

Deno.test("resource alert stays inactive inside unlimited or sufficient caps", () => {
  assertEquals(resourceAlertState({
    branches: 5,
    maxBranches: null,
    seats: 3,
    maxSeats: 3,
  }).active, false);
});

Deno.test("resource alert combines excess branch and employee counts", () => {
  const state = resourceAlertState({
    branches: 3,
    maxBranches: 1,
    seats: 5,
    maxSeats: 2,
  });
  assert(state.active);
  assertStringIncludes(state.body, "2 branches are read-only");
  assertStringIncludes(state.body, "3 employees need a seat");
});

Deno.test("device alert requires an unregistered device at the cap", () => {
  assert(deviceAlertState({
    isRegistered: false,
    devices: 1,
    maxDevices: 1,
  }).active);
  assertEquals(deviceAlertState({
    isRegistered: true,
    devices: 1,
    maxDevices: 1,
  }).active, false);
});
