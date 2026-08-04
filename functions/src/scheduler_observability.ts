export type SchedulerRecoveryWindow = {
  requestedCandidateMinutes: number;
  processedCandidateMinutes: number;
  wasClamped: boolean;
};

export type ScheduledNotificationCounts = {
  sent: number;
  failed: number;
  alreadyClaimed: number;
  notCurrent: number;
  claimFailed: number;
  staleDevicesCleaned: number;
  staleCleanupFailed: number;
};

export function schedulerRecoveryWindow(
  scheduleTime: Date,
  lastProcessedAt: Date | undefined,
): SchedulerRecoveryWindow {
  const requestedCandidateMinutes = lastProcessedAt === undefined
    ? 1
    : Math.max(
      1,
      Math.floor((scheduleTime.getTime() - lastProcessedAt.getTime()) / 60_000),
    );
  const processedCandidateMinutes = Math.min(121, requestedCandidateMinutes);

  return {
    requestedCandidateMinutes,
    processedCandidateMinutes,
    wasClamped: processedCandidateMinutes < requestedCandidateMinutes,
  };
}

export function scheduledNotificationSummary(
  counts: ScheduledNotificationCounts,
  recoveryWindow: SchedulerRecoveryWindow,
): ScheduledNotificationCounts & {
  recoveryCandidateMinutes: number;
  requestedRecoveryCandidateMinutes: number;
  recoveryClamped: boolean;
} {
  return {
    ...counts,
    recoveryCandidateMinutes: recoveryWindow.processedCandidateMinutes,
    requestedRecoveryCandidateMinutes:
      recoveryWindow.requestedCandidateMinutes,
    recoveryClamped: recoveryWindow.wasClamped,
  };
}
