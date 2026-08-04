export type ExpectedNotificationMutationVersion =
  | { kind: "legacy" }
  | { kind: "versioned"; version: number }
  | { kind: "invalid" };

export type NotificationMutationDecision =
  | "apply"
  | "stale"
  | "overflow"
  | "legacyBlocked"
  | "invalid";

export type StoredNotificationMutationVersionDecision =
  | { kind: "use"; version: number }
  | { kind: "repair" }
  | { kind: "reject" };

export function isNonNegativeNotificationMutationVersion(
  value: unknown,
): value is number {
  return (
    typeof value === "number" &&
    Number.isSafeInteger(value) &&
    value >= 0
  );
}

export function storedNotificationMutationVersionDecision(
  value: unknown,
  allowInvalidVersionRepair: boolean,
): StoredNotificationMutationVersionDecision {
  if (value === undefined) return { kind: "use", version: 0 };
  if (isNonNegativeNotificationMutationVersion(value)) {
    return { kind: "use", version: value };
  }
  return allowInvalidVersionRepair ? { kind: "repair" } : { kind: "reject" };
}

export function parseExpectedNotificationMutationVersion(
  value: unknown,
): ExpectedNotificationMutationVersion {
  if (value === undefined) return { kind: "legacy" };
  if (isNonNegativeNotificationMutationVersion(value)) {
    return { kind: "versioned", version: value };
  }
  return { kind: "invalid" };
}

export function isValidResetFenceMutation(
  resetFence: boolean | undefined,
  expected: ExpectedNotificationMutationVersion,
): boolean {
  return resetFence !== true || expected.kind === "versioned";
}

export function notificationMutationDecision(
  expected: ExpectedNotificationMutationVersion,
  currentVersion: number | undefined,
  stateExists = currentVersion !== undefined,
): NotificationMutationDecision {
  if (expected.kind === "invalid") return "invalid";
  if (expected.kind === "legacy") {
    return stateExists ? "legacyBlocked" : "apply";
  }
  if (expected.version !== (currentVersion ?? 0)) return "stale";
  return expected.version === Number.MAX_SAFE_INTEGER ? "overflow" : "apply";
}

export function notificationMutationStatePath(
  uid: string,
  typeId: string,
): string {
  return `notification_mutation_state/${uid}/types/${typeId}`;
}

export function hasActiveDeliveryPermit(
  state: Record<string, unknown> | undefined,
  nowMillis = Date.now(),
): boolean {
  return (
    typeof state?.deliveryPermitKey === "string" &&
    state.deliveryPermitKey.length > 0 &&
    typeof state.deliveryPermitExpiresAtMillis === "number" &&
    Number.isFinite(state.deliveryPermitExpiresAtMillis) &&
    state.deliveryPermitExpiresAtMillis > nowMillis
  );
}

export function hasEffectiveNotificationMutationState(
  state: Record<string, unknown> | undefined,
  nowMillis = Date.now(),
): boolean {
  return (
    isNonNegativeNotificationMutationVersion(state?.version) ||
    hasActiveDeliveryPermit(state, nowMillis)
  );
}
