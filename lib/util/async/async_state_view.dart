// Phase E (ADR-005 §Decision step 5) — shared async / loading-error contract.
//
// Before Phase E the app had no shared loading/error affordance. Async
// flows each rolled their own `FutureBuilder` that showed a bare
// `CircularProgressIndicator` only for `ConnectionState.waiting` and
// silently rendered nothing on error (see `docs/UX_GAPS.md §1.5, §3.10`).
// The bare spinners also carried no `Semantics` label (§1.5,
// `introduction.dart`).
//
// This file introduces the single async widget the audit asked for:
//   * [AsyncLoadingIndicator] — a Semantics-labelled centred spinner that
//     the bare loaders (`main.dart`, `introduction.dart`) can also reuse.
//   * [AsyncErrorRetry] — the error state, with a visible message and a
//     retry action (the missing "error-with-retry" branch).
//   * [AsyncStateView] — a `FutureBuilder` wrapper that routes every async
//     state through one place: loading → error-with-retry → empty → data.
//
// House-style discipline carried over from earlier phases:
//   * Phase B: every spinner is wrapped in `Semantics(label:)`; font sizes
//     use `.sp` so they honour the user's system text-scale.
//   * Phase C: layout leans on `Directionality` (inherited from the
//     `MaterialApp` locale) rather than branching on `isRtl`.
//   * Phase D: colours read from `AppColors` / `Theme.of(context)` tokens
//     rather than raw `Colors.*`.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/app_theme.dart';

/// Builds the data UI once the future resolves with a value.
typedef AsyncDataBuilder<T> = Widget Function(BuildContext context, T data);

/// Returns `true` when resolved [data] should render the empty state instead
/// of the data state (e.g. an empty list).
typedef AsyncEmptyPredicate<T> = bool Function(T data);

/// A centred [CircularProgressIndicator] that announces itself to screen
/// readers.
///
/// [semanticLabel] is optional: when omitted it reads
/// `AppLocalizations.asyncLoadingLabel`, and if no localizations are in scope
/// (e.g. the very first `MaterialApp` in `main.dart`, built before the
/// delegates are wired) it falls back to a plain English label so the spinner
/// is never silent to TalkBack/VoiceOver.
class AsyncLoadingIndicator extends StatelessWidget {
  final String? semanticLabel;

  const AsyncLoadingIndicator({super.key, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel ??
        AppLocalizations.of(context)?.asyncLoadingLabel ??
        'Loading';
    return Center(
      child: Semantics(
        label: label,
        liveRegion: true,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

/// The error state for an async flow: an error glyph, a human message, and a
/// retry button.
///
/// This is the "error-with-retry" branch the audit found missing. When
/// [onRetry] is null the button is hidden (some flows have nothing to retry),
/// but the message is still shown so the failure is never silent.
class AsyncErrorRetry extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;
  final String? retryLabel;

  const AsyncErrorRetry({
    super.key,
    this.onRetry,
    this.message,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final text = message ?? locale?.asyncErrorMessage ?? 'Something went wrong.';
    final retryText = retryLabel ?? locale?.asyncRetryButton ?? 'Try again';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              // Phase D: destructive/error semantics read from the token layer.
              color: AppColors.error,
              size: 40.sp,
              semanticLabel: text,
            ),
            SizedBox(height: 12.h),
            myAutoSizedText(
              text,
              TextStyle(fontSize: 16.sp),
              TextAlign.center,
              20,
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16.h),
              Semantics(
                button: true,
                child: TextButton(
                  onPressed: onRetry,
                  style: myButtonStyle,
                  child: myAutoSizedText(
                    retryText,
                    myTextStyle,
                    TextAlign.center,
                    20,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Routes a [future] through the four async states the audit asked for:
/// loading → error-with-retry → empty → data.
///
/// * **loading** while the future is pending — [AsyncLoadingIndicator].
/// * **error-with-retry** if the future rejects, or completes with `null` for
///   a non-nullable [T] — [AsyncErrorRetry] wired to [onRetry].
/// * **empty** when [isEmpty] returns true for the resolved data —
///   [emptyBuilder] if provided, otherwise the data builder is used.
/// * **data** otherwise — [onData].
///
/// Callers own the retry wiring: typically `onRetry` calls `setState` to
/// re-assign the future field so the builder re-runs.
class AsyncStateView<T> extends StatelessWidget {
  final Future<T> future;
  final AsyncDataBuilder<T> onData;
  final VoidCallback? onRetry;
  final AsyncEmptyPredicate<T>? isEmpty;
  final WidgetBuilder? emptyBuilder;
  final String? loadingLabel;
  final String? errorMessage;
  final String? retryLabel;

  const AsyncStateView({
    super.key,
    required this.future,
    required this.onData,
    this.onRetry,
    this.isEmpty,
    this.emptyBuilder,
    this.loadingLabel,
    this.errorMessage,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AsyncLoadingIndicator(semanticLabel: loadingLabel);
        }

        // Treat both an outright rejection and a null result for a
        // non-nullable T as the error state — the previous code rendered
        // an empty grid in exactly these cases (`UX_GAPS.md §3.10`).
        final resolvedToNull = snapshot.data == null && null is! T;
        if (snapshot.hasError || resolvedToNull) {
          return AsyncErrorRetry(
            onRetry: onRetry,
            message: errorMessage,
            retryLabel: retryLabel,
          );
        }

        final data = snapshot.data as T;
        if (isEmpty != null && isEmpty!(data)) {
          return emptyBuilder?.call(context) ?? onData(context, data);
        }
        return onData(context, data);
      },
    );
  }
}
