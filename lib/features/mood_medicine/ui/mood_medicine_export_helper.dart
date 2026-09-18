part of 'mood_medicine_page.dart';

Future<MoodMedicineReportBuildOutcome> _buildForCurrentPresentation(
  BuildContext sheetContext,
  MoodMedicineViewModel viewModel,
) async {
  while (sheetContext.mounted) {
    final outcome = await viewModel.buildReport();
    if (outcome is MoodMedicineReportBuildStalePresentationOutcome) continue;
    return outcome;
  }
  return const MoodMedicineReportBuildCancelledOutcome();
}

void _showReportBuildFailure(
  _MoodMedicinePageState state,
  BuildContext sheetContext,
  MoodMedicineViewModel viewModel, {
  required bool preview,
}) {
  final currentL10n = AppLocalizations.of(sheetContext)!;
  ScaffoldMessenger.of(sheetContext).showSnackBar(
    SnackBar(
      content: Text(
        state._reportBuildFailureMessage(
          currentL10n,
          viewModel,
          preview: preview,
        ),
      ),
    ),
  );
}

Future<void> _buildAndViewReport(
  _MoodMedicinePageState state,
  BuildContext context,
  BuildContext sheetContext,
  MoodMedicineViewModel viewModel,
) async {
  final outcome = await _buildForCurrentPresentation(sheetContext, viewModel);
  if (!sheetContext.mounted) return;
  switch (outcome) {
    case MoodMedicineReportBuiltOutcome(:final report):
      final currentL10n = AppLocalizations.of(sheetContext)!;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MoodMedicineReportPreviewPage(
            report: report,
            title: report.format == MoodMedicineReportFormat.pdf
                ? currentL10n.moodMedicinePreviewPdf
                : currentL10n.moodMedicinePreviewPng,
            pngPrintGuidance: currentL10n.moodMedicinePngPrintGuidance,
          ),
        ),
      );
    case MoodMedicineReportBuildFailedOutcome():
      _showReportBuildFailure(
        state,
        sheetContext,
        viewModel,
        preview: true,
      );
    case MoodMedicineReportBuildCancelledOutcome() ||
        MoodMedicineReportBuildStalePresentationOutcome():
      return;
  }
}

Future<void> _buildAndShareReport(
  _MoodMedicinePageState state,
  BuildContext sheetContext,
  MoodMedicineViewModel viewModel,
) async {
  if (viewModel.readyState?.export.report == null) {
    final outcome = await _buildForCurrentPresentation(sheetContext, viewModel);
    if (!sheetContext.mounted) return;
    switch (outcome) {
      case MoodMedicineReportBuiltOutcome():
        break;
      case MoodMedicineReportBuildFailedOutcome():
        _showReportBuildFailure(
          state,
          sheetContext,
          viewModel,
          preview: false,
        );
        return;
      case MoodMedicineReportBuildCancelledOutcome() ||
          MoodMedicineReportBuildStalePresentationOutcome():
        return;
    }
  }
  if (!sheetContext.mounted) return;
  final currentL10n = AppLocalizations.of(sheetContext)!;
  final shared = await viewModel.shareBuiltReport(
    shareText: currentL10n.moodMedicineExportReportTitle,
  );
  if (shared && sheetContext.mounted) Navigator.of(sheetContext).pop();
}

Future<void> buildMoodMedicineExportSheet(
  _MoodMedicinePageState state,
) async {
  final BuildContext context = state.context;
  final MoodMedicineViewModel viewModel = state._viewModel;
  final Future<void> sheet = showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) =>
        ChangeNotifierProvider<MoodMedicineViewModel>.value(
          value: viewModel,
          child: Consumer<MoodMedicineViewModel>(
            builder:
                (BuildContext context, MoodMedicineViewModel viewModel, _) {
                  final AppLocalizations l10n = AppLocalizations.of(context)!;
                  final MoodMedicineReadyState? ready = viewModel.readyState;
                  if (ready == null) {
                    return const SizedBox.shrink();
                  }
                  final MoodMedicineExportState export = ready.export;

                  return SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.xxl +
                            MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.moodMedicineExport,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '${l10n.moodMedicineExportRange}: '
                            '${state._rangeLabel(l10n, ready.selectedRange)}',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SegmentedButton<MoodMedicineReportFormat>(
                            segments: <ButtonSegment<MoodMedicineReportFormat>>[
                              ButtonSegment<MoodMedicineReportFormat>(
                                value: MoodMedicineReportFormat.pdf,
                                label: Text(l10n.moodMedicineExportPdf),
                                icon: const Icon(
                                  Icons.picture_as_pdf_outlined,
                                ),
                              ),
                              ButtonSegment<MoodMedicineReportFormat>(
                                value: MoodMedicineReportFormat.png,
                                label: Text(l10n.moodMedicineExportPng),
                                icon: const Icon(Icons.image_outlined),
                              ),
                            ],
                            selected: <MoodMedicineReportFormat>{
                              export.format,
                            },
                            onSelectionChanged: export.isWorking
                                ? null
                                : (Set<MoodMedicineReportFormat> selection) =>
                                      viewModel.setReportOptions(
                                        format: selection.first,
                                      ),
                          ),
                          if (export.format == MoodMedicineReportFormat.png)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                              ),
                              child: Text(
                                l10n.moodMedicinePngPrintGuidance,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          SwitchListTile.adaptive(
                            key: const Key('moodMedicineIncludeNotes'),
                            contentPadding: EdgeInsets.zero,
                            value: export.includeNotes,
                            onChanged: export.isWorking
                                ? null
                                : (bool value) => viewModel.setReportOptions(
                                    includeNotes: value,
                                  ),
                            title: Text(l10n.moodMedicineIncludeNotes),
                            subtitle: Text(l10n.moodMedicineNotesPrivacy),
                          ),
                          if (!export.includeNotes)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                              ),
                              child: Text(
                                l10n.moodMedicineNotesExcluded,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.sm,
                            children: <Widget>[
                              OutlinedButton.icon(
                                key: const Key('moodMedicineViewExport'),
                                onPressed: export.isWorking
                                    ? null
                                    : () => _buildAndViewReport(
                                        state,
                                        context,
                                        sheetContext,
                                        viewModel,
                                      ),
                                icon:
                                    export.phase ==
                                        MoodMedicineExportPhase.building
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.visibility_outlined),
                                label: Text(l10n.moodMedicineView),
                              ),
                              FilledButton.icon(
                                key: const Key('moodMedicineStartExport'),
                                onPressed: export.isWorking
                                    ? null
                                    : () => _buildAndShareReport(
                                        state,
                                        sheetContext,
                                        viewModel,
                                      ),
                                icon: export.isWorking
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.ios_share_outlined),
                                label: Text(
                                  export.isWorking
                                      ? l10n.moodMedicinePreparingExport
                                      : l10n.moodMedicineShare,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
          ),
        ),
  );
  try {
    await sheet;
  } finally {
    viewModel.endReportExportSession();
  }
}
