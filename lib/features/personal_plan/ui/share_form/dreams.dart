part of 'share_form.dart';

sealed class _DreamsAndGoalsActionPreparation {
  const _DreamsAndGoalsActionPreparation();
}

final class _DreamsAndGoalsActionReady
    extends _DreamsAndGoalsActionPreparation {
  const _DreamsAndGoalsActionReady();
}

/// A preparation failure with the revision safe to retry.
///
/// [retryRevision] is captured before each persistence await so a retry never
/// replays an older snapshot over a newer edit.
final class _DreamsAndGoalsActionFailed
    extends _DreamsAndGoalsActionPreparation {
  const _DreamsAndGoalsActionFailed(
    this.retryRevision,
    this.error,
    this.stackTrace,
  );

  final int retryRevision;
  final Object error;
  final StackTrace stackTrace;
}

mixin _ShareFormDreams on _ShareFormCategories {
  Future<void> _persistInlineDreamsAndGoals(
    UserInformation userInformation, {
    bool retry = false,
  }) {
    final WizardStepState? inlineStep = _dreamsAndGoalsStepKey.currentState;
    if (inlineStep != null) {
      return retry
          ? inlineStep.retryPersistBeforeExit()
          : inlineStep.persistBeforeExit();
    }
    return retry
        ? userInformation.retryDreamsAndGoalsSave(
            userInformation.dreamsAndGoalsSaveRevision,
          )
        : userInformation.pendingDreamsAndGoalsSave;
  }

  /// Prepares Dreams and Goals state for a Share action.
  ///
  /// The returned outcome keeps persistence failures separate from the action
  /// that follows, and records the current revision before each await that can
  /// fail. A retry therefore replays the latest prepared snapshot rather than
  /// an earlier state.
  Future<_DreamsAndGoalsActionPreparation> _prepareDreamsAndGoalsAction(
    UserInformation userInformation, {
    required bool retry,
    required int initialRetryRevision,
  }) async {
    int retryRevision = initialRetryRevision;
    if (!_dreamsAndGoalsSourcesAreAligned(userInformation) && mounted) {
      setState(() {
        _hideDreamsAndGoalsSummaryUntilRepair = true;
      });
    }
    try {
      while (true) {
        final bool hadInlineStep = _dreamsAndGoalsStepKey.currentState != null;
        await _persistInlineDreamsAndGoals(userInformation, retry: retry);
        retryRevision = userInformation.dreamsAndGoalsSaveRevision;
        await userInformation.pendingDreamsAndGoalsSave;
        await userInformation.pendingCustomCategoriesSave;

        final int revisionBeforeRepair =
            userInformation.dreamsAndGoalsSaveRevision;
        await userInformation.repairDreamsAndGoalsSelectionSources();
        await userInformation.pendingDreamsAndGoalsSave;
        await userInformation.pendingCustomCategoriesSave;

        // If no inline editor persisted this snapshot and repair left the revision
        // unchanged, queue the save now so in-memory state is durable in storage.
        if (!retry &&
            !hadInlineStep &&
            userInformation.dreamsAndGoalsSaveRevision ==
                revisionBeforeRepair) {
          await userInformation.queueDreamsAndGoalsSave();
          await userInformation.pendingDreamsAndGoalsSave;
          await userInformation.pendingCustomCategoriesSave;
        }

        final int expectedRevision = userInformation.dreamsAndGoalsSaveRevision;
        retryRevision = expectedRevision;
        if (userInformation.dreamsAndGoalsSaveRevision == expectedRevision) {
          await userInformation.pendingDreamsAndGoalsSave;
          await userInformation.pendingCustomCategoriesSave;
          if (mounted) {
            setState(() {
              _hideDreamsAndGoalsSummaryUntilRepair = false;
            });
          }
          break;
        }
      }
      return const _DreamsAndGoalsActionReady();
    } catch (error, stackTrace) {
      return _DreamsAndGoalsActionFailed(retryRevision, error, stackTrace);
    }
  }

  Future<void> _toggleDreamsAndGoals({bool retry = false}) async {
    final UserInformation userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    if (!_isEditingDreamsAndGoals) {
      if (_isOpeningDreamsAndGoals) {
        return;
      }
      _isOpeningDreamsAndGoals = true;
      if (mounted) {
        setState(() {
          _hideDreamsAndGoalsSummaryUntilRepair = true;
        });
      }
      try {
        if (retry) {
          await userInformation.retryDreamsAndGoalsSave(
            userInformation.dreamsAndGoalsSaveRevision,
          );
        } else {
          // The editor requires one source token per selected row. Repair the
          // model-owned snapshot before mounting FormPageTemplate so legacy
          // selections cannot reach its edit path with unaligned sources.
          await userInformation.repairDreamsAndGoalsSelectionSources();
        }
        if (mounted) {
          setState(() {
            _isEditingDreamsAndGoals = true;
            _hideDreamsAndGoalsSummaryUntilRepair = false;
          });
        }
      } catch (error, stackTrace) {
        if (retry) {
          await _captureDreamsAndGoalsFailure(error, stackTrace);
        }
        if (mounted) {
          setState(() {
            _hideDreamsAndGoalsSummaryUntilRepair = true;
          });
          _showDreamsAndGoalsSaveFailure(
            () => _toggleDreamsAndGoals(retry: true),
          );
        }
      } finally {
        _isOpeningDreamsAndGoals = false;
      }
      return;
    }

    try {
      await _persistInlineDreamsAndGoals(userInformation, retry: retry);
      if (mounted) {
        setState(() {
          _isEditingDreamsAndGoals = false;
          _hideDreamsAndGoalsSummaryUntilRepair = false;
        });
      }
    } catch (error, stackTrace) {
      if (retry) {
        await _captureDreamsAndGoalsFailure(error, stackTrace);
      }
      if (mounted) {
        _showDreamsAndGoalsSaveFailure(
          () => _toggleDreamsAndGoals(retry: true),
        );
      }
    }
  }

  Future<void> _runDreamsAndGoalsAction(
    UserInformation userInformation,
    FutureOr<void> Function() action,
  ) => _runGuardedDreamsAndGoalsAction(
    userInformation,
    action,
    retry: false,
    retryRevision: userInformation.dreamsAndGoalsSaveRevision,
  );

  Future<void> _retryDreamsAndGoalsAction(
    UserInformation userInformation,
    int capturedRevision,
    FutureOr<void> Function() action,
  ) => _runGuardedDreamsAndGoalsAction(
    userInformation,
    action,
    retry: true,
    retryRevision: capturedRevision,
  );

  /// Runs one Dreams-dependent action at a time for this Share form.
  ///
  /// The guard spans preparation, persistence retry UI, and the final action
  /// so rapid taps cannot duplicate an export or finish.
  Future<void> _runGuardedDreamsAndGoalsAction(
    UserInformation userInformation,
    FutureOr<void> Function() action, {
    required bool retry,
    required int retryRevision,
  }) async {
    if (_isRunningDreamsAndGoalsAction) {
      return;
    }
    _isRunningDreamsAndGoalsAction = true;
    try {
      final _DreamsAndGoalsActionPreparation preparation =
          await _prepareDreamsAndGoalsAction(
            userInformation,
            retry: retry,
            initialRetryRevision: retryRevision,
          );
      switch (preparation) {
        case _DreamsAndGoalsActionFailed(
          :final int retryRevision,
          :final Object error,
          :final StackTrace stackTrace,
        ):
          await _captureDreamsAndGoalsFailure(error, stackTrace);
          if (mounted) {
            _showDreamsAndGoalsSaveFailure(
              () => _retryDreamsAndGoalsAction(
                userInformation,
                retryRevision,
                action,
              ),
            );
          }
          return;
        case _DreamsAndGoalsActionReady():
          if (!retry && mounted) {
            await action();
          } else if (retry) {
            await _runRetriedDreamsAndGoalsAction(action);
          }
      }
    } finally {
      _isRunningDreamsAndGoalsAction = false;
    }
  }

  void _showDreamsAndGoalsSaveFailure(Future<void> Function() retry) {
    showPersistenceRetrySnackBar(context, retry);
  }

  Future<void> _runRetriedDreamsAndGoalsAction(
    FutureOr<void> Function() action,
  ) async {
    if (!mounted) {
      return;
    }
    try {
      await action();
    } catch (error, stackTrace) {
      await _captureDreamsAndGoalsFailure(error, stackTrace);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'ShareForm',
          context: ErrorDescription('while retrying a Dreams and Goals action'),
        ),
      );
    }
  }

  bool _dreamsAndGoalsSourcesAreAligned(UserInformation userInformation) {
    return listEquals(
      userInformation.dreamsAndGoalsSelectionSources,
      normalizeDreamsAndGoalsSelectionSources(
        userInformation.dreamsAndGoals,
        userInformation.dreamsAndGoalsSelectionSources,
      ),
    );
  }

  bool _dreamsAndGoalsSummaryIsReady(UserInformation userInformation) {
    if (_hideDreamsAndGoalsSummaryUntilRepair ||
        userInformation.dreamsAndGoals.isEmpty) {
      return false;
    }
    return _dreamsAndGoalsSourcesAreAligned(userInformation);
  }
}
