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
  | { kind: "repair" };

export type NotificationMutationAuthorizationDecision =
  | { kind: "apply"; nextVersion: number | undefined }
  | { kind: "conflict"; message: string };

export type NotificationMutationAuthorizationInput = {
  storedVersion: unknown;
  expectedVersion: ExpectedNotificationMutationVersion;
  rejectActiveDeliveryPermit: boolean;
  hasActiveDeliveryPermit: boolean;
  hasEffectiveState: boolean;
};

export type NotificationMutationOperation =
  | { kind: "register"; scheduleData: Record<string, unknown> }
  | { kind: "cancel" };

export type NotificationMutationTransaction<TReference> = {
  get(reference: TReference): Promise<{
    data(): Record<string, unknown> | undefined;
  }>;
  set(
    reference: TReference,
    data: Record<string, unknown>,
    options?: { merge: boolean },
  ): unknown;
  delete(reference: TReference): unknown;
};

export type NotificationMutationExecutionInput<TReference> = {
  stateRef: TReference;
  scheduleRef: TReference;
  expectedVersion: ExpectedNotificationMutationVersion;
  rejectActiveDeliveryPermit: boolean;
  operation: NotificationMutationOperation;
};

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
): StoredNotificationMutationVersionDecision {
  if (value === undefined) return { kind: "use", version: 0 };
  if (isNonNegativeNotificationMutationVersion(value)) {
    return { kind: "use", version: value };
  }
  return { kind: "repair" };
}

export function notificationMutationAuthorizationDecision(
  input: NotificationMutationAuthorizationInput,
): NotificationMutationAuthorizationDecision {
  if (input.rejectActiveDeliveryPermit && input.hasActiveDeliveryPermit) {
    return {
      kind: "conflict",
      message: "Scheduled delivery is already authorized",
    };
  }

  const storedVersionDecision = storedNotificationMutationVersionDecision(
    input.storedVersion,
  );

  const currentVersion = storedVersionDecision.kind === "repair"
    ? 0
    : storedVersionDecision.version;
  const decision = notificationMutationDecision(
    input.expectedVersion,
    currentVersion,
    input.hasEffectiveState,
  );
  if (decision === "overflow") {
    return {
      kind: "conflict",
      message: "Notification mutation version overflow",
    };
  }
  if (decision !== "apply") {
    return { kind: "conflict", message: "Stale notification mutation" };
  }

  return {
    kind: "apply",
    nextVersion: input.expectedVersion.kind === "versioned"
      ? currentVersion + 1
      : undefined,
  };
}

export async function executeNotificationMutation<TReference>(
  transaction: NotificationMutationTransaction<TReference>,
  input: NotificationMutationExecutionInput<TReference>,
): Promise<NotificationMutationAuthorizationDecision> {
  const stateData = (await transaction.get(input.stateRef)).data();
  const decision = notificationMutationAuthorizationDecision({
    storedVersion: stateData?.version,
    expectedVersion: input.expectedVersion,
    rejectActiveDeliveryPermit: input.rejectActiveDeliveryPermit,
    hasActiveDeliveryPermit: hasActiveDeliveryPermit(stateData),
    hasEffectiveState: hasEffectiveNotificationMutationState(stateData),
  });
  if (decision.kind === "conflict") return decision;

  if (input.operation.kind === "register") {
    if (decision.nextVersion !== undefined) {
      transaction.set(
        input.stateRef,
        { version: decision.nextVersion },
        { merge: true },
      );
    }
    transaction.set(
      input.scheduleRef,
      decision.nextVersion === undefined
        ? input.operation.scheduleData
        : {
          ...input.operation.scheduleData,
          mutationVersion: decision.nextVersion,
        },
    );
    return decision;
  }

  transaction.delete(input.scheduleRef);
  if (decision.nextVersion !== undefined) {
    transaction.set(
      input.stateRef,
      { version: decision.nextVersion },
      { merge: true },
    );
  }
  return decision;
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
