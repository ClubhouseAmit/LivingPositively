part of 'share_form.dart';

mixin _ShareFormExport on _ShareFormDreams {
  Widget buildDreamsAndGoalsSection(BuildContext context, String gender) {
    final userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    final dreamsSummaryIsReady = _dreamsAndGoalsSummaryIsReady(userInformation);
    final dreamsInformation = retrieveInformation(
      'PersonalPlan-DreamsAndGoals',
      gender,
      appLocale,
    );
    return SizedBox(
      width: formFieldWidth(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dreamsSummaryIsReady && !_isEditingDreamsAndGoals)
            MyPlanSection(
              key: const ValueKey('share-summary-5'),
              title: dreamsInformation['header'] ?? '',
              subTitle: dreamsInformation['subTitle'] ?? '',
              answers: userInformation.dreamsAndGoals,
              onEdit: widget.goToStep == null
                  ? () => unawaited(_toggleDreamsAndGoals())
                  : () => widget.goToStep!(5),
              onDelete: () => unawaited(
                _deleteBuiltInCategory('PersonalPlan-DreamsAndGoals'),
              ),
            ),
          KeyedSubtree(
            key: const Key('share-dreams-and-goals-toggle'),
            child: LinkButton(
              () {
                unawaited(_toggleDreamsAndGoals());
              },
              _isEditingDreamsAndGoals
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              appLocale.dreamsAndGoalsHeader(gender),
              Theme.of(context).colorScheme.primary,
              minHeight: 40,
            ),
          ),
          if (_isEditingDreamsAndGoals) ...[
            const SizedBox(height: AppSpacing.sm),
            FormPageTemplate(
              key: _dreamsAndGoalsStepKey,
              next: () {},
              prev: () {},
              collectionName: 'PersonalPlan-DreamsAndGoals',
              scrollable: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _shareExportButtons(
    BuildContext context,
    UserInformation userInfoProvider,
    AppInformation appInfoProvider,
    String gender,
  ) {
    const pad = _exportButtonPad;
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {
              unawaited(
                _runDreamsAndGoalsAction(userInfoProvider, () async {
                  if (!mounted) {
                    return;
                  }
                  await showShareDialog(
                    context,
                    memoryService: widget.memoryService,
                  );
                }),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(pad),
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadii.card),
                ),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            icon: Icon(
              Icons.share,
              color: Theme.of(context).colorScheme.primary,
            ),
            padding: const EdgeInsets.all(pad),
          ),
          IconButton(
            onPressed: () {
              unawaited(
                _runDreamsAndGoalsAction(userInfoProvider, () async {
                  await downloadPersonalPlanFile(
                    appLocale: appLocale,
                    gender: gender,
                    username: userInfoProvider.name,
                    appInformation: appInfoProvider,
                    userInformation: userInfoProvider,
                    fileService: fileService,
                    memoryService: widget.memoryService,
                  );
                }),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(pad),
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadii.card),
                ),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            icon: Icon(
              Icons.download,
              color: Theme.of(context).colorScheme.primary,
            ),
            padding: const EdgeInsets.all(pad),
          ),
        ],
      ),
    );
  }
}
