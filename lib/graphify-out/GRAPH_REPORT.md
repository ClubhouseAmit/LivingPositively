# Graph Report - lib  (2026-09-19)

## Corpus Check
- 200 files · ~173,065 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 3 file(s) not represented in the graph (top: .arb 3)

## Summary
- 6959 nodes · 8909 edges · 141 communities (135 shown, 6 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `442a0326`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_localizations.dart
- app_localizations_ar.dart
- app_localizations_en.dart
- app_localizations_he.dart
- firebase_functions.dart
- breathing_view_model.dart
- appInformation.dart
- mood_medicine_view_model.dart
- userInformation.dart
- suffix_action.dart
- speech_recognition_service.dart
- mood_medicine_view_state.dart
- mood_medicine_page.dart
- package:flutter/material.dart
- user_settings_page.dart
- mood_medicine_models.dart
- list.dart
- main.dart
- personal_plan_widget.dart
- share_form.dart
- styles.dart
- UserInformation
- menu.dart
- package:mazilon/util/userInformation.dart
- personal_plan_editor_page.dart
- package:mazilon/l10n/app_localizations.dart
- form_page_template.dart
- onboarding_page.dart
- dashed_list_widget.dart
- package:mazilon/design_system/tokens/spacing.dart
- directional_widgets.dart
- mood_medicine_insights.dart
- mood_medicine_report_models.dart
- String?
- create_pdf.dart
- mood_medicine_report_renderer.dart
- mood_medicine_content.dart
- positive_page.dart
- package:mazilon/util/async/logger_service.dart
- phone_page.dart
- breathing_page.dart
- gratitude_section.dart
- colors.dart
- package:flutter/widgets.dart
- AddForm.dart
- player.dart
- country_selector.dart
- StatelessWidget
- package:mazilon/util/async/persistent_memory_service.dart
- editor.dart
- breathing_models.dart
- wellness_tools_page.dart
- List
- form.dart
- image_picker_repository.dart
- dreams_and_goals_models.dart
- phone_models.dart
- personal_plan_info_modal.dart
- notification_repository.dart
- main_menu_dialog.dart
- reminder_debug_panel.dart
- retrieveInformation.dart
- phoneTextAndIcon.dart
- Exception
- mainpage_list_widget.dart
- package:mazilon/features/shell/ui/LP_extended_state.dart
- PersistentMemoryService
- sos_location_service.dart
- home_page.dart
- spacing.dart
- sheet.dart
- breathing_widgets.dart
- mood_medicine_insights_helper.dart
- custom_categories_storage.dart
- list_utils.dart
- service_locator.dart
- mood_medicine_trend_chart.dart
- text_field.dart
- initial_form_page2.dart
- my_plan_page.dart
- warning_signs_section.dart
- mood_medicine_repository.dart
- spoken_phone_number_normalizer.dart
- personal_plan_download.dart
- VoidCallback
- thank_you.dart
- set_notification_widget.dart
- async_state_view.dart
- reminder_debug_recorder.dart
- step.dart
- emergency_numbers.dart
- breathing_photo_importer.dart
- add_step.dart
- mood_medicine_report_delivery_types.dart
- @immutable
- dialog.dart
- popover.dart
- select.dart
- text.dart
- tooltip.dart
- mood_medicine_report_preview_page.dart
- LP_share_alert_dialog.dart
- file_service.dart
- app_theme.dart
- type_scale.dart
- Map
- mood_medicine_report_exporter.dart
- PagePhoneItem.dart
- dart:async
- otp_field.dart
- personal_plan_share.dart
- slider.dart
- time_picker.dart
- my_plan_section.dart
- wizard_steps.dart
- AnalyticsService
- gender.dart
- custom_category/card.dart
- WizardStepState
- package:mazilon/features/wizard/ui/wizard_step.dart
- package:flutter/foundation.dart
- mood_medicine_misc_helpers.dart
- locale_service.dart
- return
- circular_action_button.dart
- font_weight.dart
- shadows.dart
- AppLocalizations
- IncidentLoggerService
- class
- dart:ui
- video_player_page_factory.dart
- @Deprecated
- type_utils.dart
- _PhonePageListState
- file_save_utils.dart
- callbackDispatcher
- _ActivityEditorDialog
- MoodMedicinePage
- _PlanWizardHeader
- SpeechRecognitionService

## God Nodes (most connected - your core abstractions)
1. `UserInformation` - 186 edges
2. `LPExtendedState` - 38 edges
3. `AppInformation` - 26 edges
4. `IncidentLoggerService` - 21 edges
5. `PhonePageData` - 20 edges
6. `WizardStepState` - 17 edges
7. `PersistentMemoryService` - 17 edges
8. `AppLocalizations` - 14 edges
9. `AnalyticsService` - 14 edges
10. `WizardStep` - 11 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `UserInformation`  [EXTRACTED]
  lib/features/feel_good/ui/add_image_item.dart → lib/util/userInformation.dart
- `build` --references--> `UserInformation`  [EXTRACTED]
  lib/features/feel_good/ui/image_display_item.dart → lib/util/userInformation.dart
- `build` --references--> `UserInformation`  [EXTRACTED]
  lib/features/home/ui/dashed_list_widget.dart → lib/util/userInformation.dart
- `didChangeDependencies` --references--> `UserInformation`  [EXTRACTED]
  lib/features/home/ui/list/mainpage_list_widget.dart → lib/util/userInformation.dart
- `build` --references--> `UserInformation`  [EXTRACTED]
  lib/features/home/ui/list/mainpage_list_widget.dart → lib/util/userInformation.dart

## Import Cycles
- None detected.

## Communities (141 total, 6 thin omitted)

### Community 0 - "app_localizations.dart"
Cohesion: 0.00
Nodes (742): app_localizations_ar.dart, app_localizations_en.dart, app_localizations_he.dart, aboutPage1, aboutPage2, aboutTitle1, aboutTitle2, aboutVersionLabel (+734 more)

### Community 1 - "app_localizations_ar.dart"
Cohesion: 0.00
Nodes (730): app_localizations.dart, aboutPage1, aboutPage2, aboutTitle1, aboutTitle2, aboutVersionLabel, addFormEdit, addFormPageTemplateAdd (+722 more)

### Community 2 - "app_localizations_en.dart"
Cohesion: 0.00
Nodes (729): aboutPage1, aboutPage2, aboutTitle1, aboutTitle2, aboutVersionLabel, addFormEdit, addFormPageTemplateAdd, addFormPageTemplateAddOwn (+721 more)

### Community 3 - "app_localizations_he.dart"
Cohesion: 0.00
Nodes (729): aboutPage1, aboutPage2, aboutTitle1, aboutTitle2, aboutVersionLabel, addFormEdit, addFormPageTemplateAdd, addFormPageTemplateAddOwn (+721 more)

### Community 4 - "firebase_functions.dart"
Cohesion: 0.01
Nodes (144): CollectionReference, DocumentSnapshot, File, FirebaseAuth, package:cloud_firestore/cloud_firestore.dart, package:firebase_auth/firebase_auth.dart, QuerySnapshot, a (+136 more)

### Community 5 - "breathing_view_model.dart"
Cohesion: 0.02
Nodes (107): BreathingPattern get, BreathingPhase get, BreathingScreen get, BreathingSession? get, BreathingSettings get, Duration get, _acceptSnapshot, _active (+99 more)

### Community 6 - "appInformation.dart"
Cohesion: 0.02
Nodes (106): aboutPageText, addFormPageTemplateStrings, addFormStrings, addThanksFormStrings, appVersion, DifficultEventsSug, disclaimerNext, disclaimerText (+98 more)

### Community 7 - "mood_medicine_view_model.dart"
Cohesion: 0.02
Nodes (84): _activeReportBuildGeneration, _activeReportBuildInvalidation, _activeReportDeliveryGeneration, _activeReportDeliveryInvalidated, addCustomActivity, apply, buildReport, _buildReportInput (+76 more)

### Community 8 - "userInformation.dart"
Cohesion: 0.02
Nodes (84): _activeDreamsAndGoalsSavesCount, age, binary, customCategories, _customCategoriesSaveInProgress, _customCategoriesSaveRevision, darkModeEndHour, darkModeEndMinute (+76 more)

### Community 9 - "suffix_action.dart"
Cohesion: 0.03
Nodes (79): _handleStartResult, appLocale, service, _activeLocaleId, _applyFinalTranscript, _awaitingSessionStart, build, _cancelPendingStart (+71 more)

### Community 10 - "speech_recognition_service.dart"
Cohesion: 0.03
Nodes (74): Completer, package:speech_to_text/speech_to_text.dart, SpeechToText, Timer?, _activeSession, _ActiveSpeechRecognitionSession, cancel, _cancellation (+66 more)

### Community 11 - "mood_medicine_view_state.dart"
Cohesion: 0.03
Nodes (73): activityIds, activityLabelForDay, activityLabelForRange, associations, buildFailureKind, canRetry, canSave, checkInForm (+65 more)

### Community 12 - "mood_medicine_page.dart"
Cohesion: 0.03
Nodes (72): Locale?, MoodMedicineViewModel get, package:mazilon/design_system/widgets/sheet.dart, package:mazilon/features/mood_medicine/ui/mood_medicine_trend_chart.dart, package:mazilon/pages/mood_medicine_report_preview_page.dart, _activities, activity, _ActivityChip (+64 more)

### Community 13 - "package:flutter/material.dart"
Cohesion: 0.04
Nodes (60): dart:math, bottomNavigationItem, build, index, ListItemNumberWidget, add, build, createState (+52 more)

### Community 14 - "user_settings_page.dart"
Cohesion: 0.03
Nodes (67): _actionButton, _actionSection, age, ages, _ageSetting, _applyGenderInBackground, _attemptReset, _attemptResetAndReturnSuccess (+59 more)

### Community 15 - "mood_medicine_models.dart"
Cohesion: 0.03
Nodes (63): activityIds, candidate, cause, copyWith, customActivities, customActivityForId, customActivityLabelSnapshots, day (+55 more)

### Community 16 - "list.dart"
Cohesion: 0.03
Nodes (59): build, validateName, validateNumber, _cancelDraft, _cancelExistingEdit, _confirmDelete, _countryPickerWidth, createState (+51 more)

### Community 17 - "main.dart"
Cohesion: 0.03
Nodes (57): app, appInfo, _backgroundWorkerSentryDsn, bootstrapApp, changeLocale, checkboxCollectionNames, createState, didChangeAppLifecycleState (+49 more)

### Community 18 - "personal_plan_widget.dart"
Cohesion: 0.04
Nodes (53): build, _buildEmptyState, _buildItemsList, _buildSeeAllButton, enableTitleTap, fileService, _handleMenuSelection, items (+45 more)

### Community 19 - "share_form.dart"
Cohesion: 0.04
Nodes (56): createState, dispose, _exportButtonPad, initState, memoryService, onPrimaryAction, persistBeforeExit, prev (+48 more)

### Community 20 - "styles.dart"
Cohesion: 0.04
Nodes (54): ButtonStyle, appBlue, appGreen, appWhite, asset, availableWidth, backgroundGray, button (+46 more)

### Community 21 - "UserInformation"
Cohesion: 0.07
Nodes (52): ListWidget, _ListWidgetState, build, createState, greetingString, icons, NameBar, NameBarState (+44 more)

### Community 22 - "menu.dart"
Cohesion: 0.04
Nodes (51): AutoSizeGroup, _bottomNavigationButton, _bottomNavigationCenterGap, _bottomNavigationLabelGroup, _breathingAvailable, _breathingListener, _breathingModel, BreathingViewModelFactory (+43 more)

### Community 23 - "package:mazilon/util/userInformation.dart"
Cohesion: 0.04
Nodes (49): build, createState, ImageAddItem, _ImageAddItemState, _showAddImageDialog, build, controller, _focusOnPicture (+41 more)

### Community 24 - "personal_plan_editor_page.dart"
Cohesion: 0.04
Nodes (51): build, currentStep, _headerNavigationInFlight, steps, package:mazilon/features/personal_plan/ui/wizard_steps.dart, _addCustomCategory, changeLocale, createState (+43 more)

### Community 25 - "package:mazilon/l10n/app_localizations.dart"
Cohesion: 0.04
Nodes (44): build, createState, InitialFormPage1, _InitialFormPage1State, next, onPrimaryAction, prev, primaryActionLabel (+36 more)

### Community 26 - "form_page_template.dart"
Cohesion: 0.04
Nodes (48): build, collectionName, _completePrimaryAction, createState, _gapBetweenBlocks, _gapLabelToCaption, _gapWithinBlock, _gapWithinGroup (+40 more)

### Community 27 - "onboarding_page.dart"
Cohesion: 0.04
Nodes (46): package:mazilon/features/onboarding/ui/initial_form_page1.dart, package:mazilon/features/onboarding/ui/initial_form_page2.dart, package:mazilon/features/onboarding/ui/to_form_page.dart, package:mazilon/features/wizard/ui/wizard_actions.dart, package:mazilon/menu.dart, package:mazilon/pages/disclaimer_page.dart, package:mazilon/pages/onboarding_page.dart, build (+38 more)

### Community 28 - "dashed_list_widget.dart"
Cohesion: 0.05
Nodes (45): Animation, AnimationController, build, _collapseController, _collapseHeight, _collapseOpacity, _collapsingIndex, createState (+37 more)

### Community 29 - "package:mazilon/design_system/tokens/spacing.dart"
Cohesion: 0.05
Nodes (42): Axis, BoxBorder?, Color?, border, build, Card, child, color (+34 more)

### Community 30 - "directional_widgets.dart"
Cohesion: 0.04
Nodes (46): BoxFit?, CustomClipper, CustomPainter, _DoubleQuotePainter, _MoodMedicineTrendPainter, actionIcon, actionLabel, actionWidget (+38 more)

### Community 31 - "mood_medicine_insights.dart"
Cohesion: 0.04
Nodes (45): dart:collection, double get, activityId, activityIds, add, associations, _average, averageMood (+37 more)

### Community 32 - "mood_medicine_report_models.dart"
Cohesion: 0.04
Nodes (45): activities, activitiesLabel, activityLabel, _activityLines, associationDisclaimer, _associationLine, associations, associationsLabel (+37 more)

### Community 33 - "String?"
Cohesion: 0.05
Nodes (38): Alert, AlertVariant, build, color, _SeverityMark, subtitle, title, variant (+30 more)

### Community 34 - "create_pdf.dart"
Cohesion: 0.05
Nodes (40): ByteData, showToast, package:flutter/services.dart, package:fluttertoast/fluttertoast.dart, package:pdf/widgets.dart, alignment, approvedHosts, buildLinkWidget (+32 more)

### Community 35 - "mood_medicine_report_renderer.dart"
Cohesion: 0.05
Nodes (41): a4PortraitAspectRatio, bottomSpacing, breakAfterRunes, buffer, _buildContentPlan, _buildLines, _buildPdfHeader, _buildPdfSection (+33 more)

### Community 36 - "mood_medicine_content.dart"
Cohesion: 0.05
Nodes (40): activities, activityColors, activityFor, _activityPalette, actsOfKindnessId, _cdcConnectionUri, _cdcSleepUri, color (+32 more)

### Community 37 - "positive_page.dart"
Cohesion: 0.05
Nodes (39): package:keyboard_dismisser/keyboard_dismisser.dart, package:mazilon/features/journal/ui/thank_you.dart, package:mazilon/features/journal/ui/thanksItemSug.dart, package:mazilon/features/positive/ui/positiveTraitItemSug.dart, addThankYou, build, createState, editThanks (+31 more)

### Community 38 - "package:mazilon/util/async/logger_service.dart"
Cohesion: 0.07
Nodes (33): dart:io, dart:typed_data, deliverMoodMedicineReport, bytes, _deliverMoodMedicineIoReport, deliverMoodMedicineReport, deliverMoodMedicineReportThroughShare, fileName (+25 more)

### Community 39 - "phone_page.dart"
Cohesion: 0.05
Nodes (37): package:mazilon/features/phone/ui/EmergencyPhones.dart, _canonicalPersonalContactNumber, contactsTitle, createState, _deliveryOption, emergencyNumbersTitle, _internationalWhatsAppNumber, _isSosDeliveryInProgress (+29 more)

### Community 40 - "breathing_page.dart"
Cohesion: 0.06
Nodes (35): AppLocalizations get, BreathingViewModel get, BreathingScreen, package:mazilon/features/remember_to_breathe/ui/breathing_view_state.dart, package:mazilon/features/remember_to_breathe/ui/breathing_widgets.dart, _backgroundChoices, _beforeRating, _body (+27 more)

### Community 41 - "gratitude_section.dart"
Cohesion: 0.06
Nodes (35): build, createState, didChangeDependencies, _eligibleSuggestions, GratitudeSectionWidget, _GratitudeSectionWidgetState, _homeSuggestions, onOpenSection (+27 more)

### Community 42 - "colors.dart"
Cohesion: 0.06
Nodes (34): AppColors, darkError, darkLogoOutline, darkNavBackground, darkOnError, darkOnPrimary, darkOnSecondary, darkOnSuccess (+26 more)

### Community 43 - "package:flutter/widgets.dart"
Cohesion: 0.07
Nodes (30): _Box, build, Checkbox, label, onChanged, value, build, controller (+22 more)

### Community 44 - "AddForm.dart"
Cohesion: 0.06
Nodes (33): _actionLabel, _actions, add, AddForm, _AddFormState, build, _controller, createState (+25 more)

### Community 45 - "player.dart"
Cohesion: 0.06
Nodes (34): build, _clearPendingLoad, controller, _controllerInitialized, _controllerSubscription, createState, _cueInitialVideo, didChangeDependencies (+26 more)

### Community 46 - "country_selector.dart"
Cohesion: 0.06
Nodes (31): BoxDecoration?, double?, build, changeVisible, CountrySelectorWidget, _CountrySelectorWidgetState, createState, didChangeDependencies (+23 more)

### Community 47 - "StatelessWidget"
Cohesion: 0.07
Nodes (31): Avatar, build, child, _FallbackMark, initials, CardContainer, DashedPillAddSlot, LivingPositivelyLogo (+23 more)

### Community 48 - "package:mazilon/util/async/persistent_memory_service.dart"
Cohesion: 0.06
Nodes (29): breathing_photo_importer.dart, breathing_repository.dart, discardUnreadableSnapshot, loadSnapshot, _memoryService, mutateSnapshot, _pendingOperation, _readSnapshot (+21 more)

### Community 49 - "editor.dart"
Cohesion: 0.06
Nodes (31): _actionRow, _alignmentFor, build, cancelLabel, createState, CustomCategoryEditor, CustomCategoryEditorState, descriptionController (+23 more)

### Community 50 - "breathing_models.dart"
Cohesion: 0.06
Nodes (31): background, BreathingBackground, BreathingPattern, BreathingPhase, BreathingSession, BreathingSnapshot, completedCycles, copyWith (+23 more)

### Community 51 - "wellness_tools_page.dart"
Cohesion: 0.07
Nodes (30): bool?, package:mazilon/features/wellness_tools/ui/more_videos_item.dart, package:mazilon/features/wellness_tools/ui/video_player_inherited_widget.dart, build, changeVideo, createState, didUpdateWidget, dispose (+22 more)

### Community 52 - "List"
Cohesion: 0.07
Nodes (27): build, createState, ListBodyWidget, _ListBodyWidgetState, listItems, actions, build, createState (+19 more)

### Community 53 - "form.dart"
Cohesion: 0.07
Nodes (30): addItem, appLocale, build, controller1, controller2, createState, _disclaimerBottom, _disclaimerHPad (+22 more)

### Community 54 - "image_picker_repository.dart"
Cohesion: 0.07
Nodes (28): AnalyticsService? get, analyticsService, deleteImage, deleteImages, displayImage, downloadImage, _effectiveAnalyticsService, _effectiveLoggerService (+20 more)

### Community 55 - "dreams_and_goals_models.dart"
Cohesion: 0.07
Nodes (28): contains, customSelections, _dreamsAndGoalsCatalogueGenders, dreamsAndGoalsCatalogueIds, dreamsAndGoalsCatalogueSelectionSourceForIndex, _dreamsAndGoalsCatalogueSelectionSourcePrefix, dreamsAndGoalsCustomItems, dreamsAndGoalsCustomSelectionSource (+20 more)

### Community 56 - "phone_models.dart"
Cohesion: 0.07
Nodes (27): addItem, canonicalizePhoneNumber, fromJson, _hasDialablePhoneNumber, header, _isValidContact, key, loadItemsFromPrefs (+19 more)

### Community 57 - "personal_plan_info_modal.dart"
Cohesion: 0.07
Nodes (27): build, _close, createState, _createVideoController, _cueVideo, dispose, l10n, _openExternalLink (+19 more)

### Community 58 - "notification_repository.dart"
Cohesion: 0.07
Nodes (26): @visibleForTesting, deliverMoodMedicineIoReportForTesting, deliverMoodMedicineWebReportForTesting, buildContentPlanForTesting, calculateTime, cancelNotifications, _flutterLocalNotificationsPlugin, init (+18 more)

### Community 59 - "main_menu_dialog.dart"
Cohesion: 0.07
Nodes (26): age, build, buildMainMenuItems, changeLocale, child, _contactUsUrl, _englishContactUsUrl, _englishShareAppUrl (+18 more)

### Community 60 - "reminder_debug_panel.dart"
Cohesion: 0.08
Nodes (25): _batteryOptStatus, build, _busy, _clearHistory, _copyDiagnostics, createState, initState, _isAndroid (+17 more)

### Community 61 - "retrieveInformation.dart"
Cohesion: 0.08
Nodes (25): difficultEventsList, distractionsList, feelBetterList, header, inspirationalQuotes, list, makeSaferList, midSubTitle (+17 more)

### Community 62 - "phoneTextAndIcon.dart"
Cohesion: 0.08
Nodes (25): compact, dialPhone, _dialPhoneUri, digits, getTextIconWidget, launched, _launchUriWithLogging, launchWithFeedback (+17 more)

### Community 63 - "Exception"
Cohesion: 0.08
Nodes (23): breathing_models.dart, Exception, MoodMedicineSnapshotDecodeException, errorType, logMoodMedicineReportFailure, _MoodMedicineReportFailureLog, MoodMedicineReportFailureStage, stage (+15 more)

### Community 64 - "mainpage_list_widget.dart"
Cohesion: 0.08
Nodes (24): addItemFunction, build, buildPositiveTraitItemSug, buildSuggestion, buildThanksItemSug, createState, didChangeDependencies, editThanks (+16 more)

### Community 65 - "package:mazilon/features/shell/ui/LP_extended_state.dart"
Cohesion: 0.09
Nodes (23): build, createState, icon, icons, SectionBarHome, SectionBarHomeState, subHeader, textWidget (+15 more)

### Community 66 - "PersistentMemoryService"
Cohesion: 0.08
Nodes (23): _buildAndShareReport, _buildAndViewReport, _buildForCurrentPresentation, buildMoodMedicineExportSheet, context, currentL10n, outcome, shared (+15 more)

### Community 67 - "sos_location_service.dart"
Cohesion: 0.09
Nodes (24): canRetry, _captureUnexpectedFailure, _geolocatorPlatform, GeolocatorSosLocationService, _incidentLoggerService, _isLocationSharingSupported, _isWeb, kind (+16 more)

### Community 68 - "home_page.dart"
Cohesion: 0.08
Nodes (24): package:mazilon/features/home/ui/header_widget.dart, package:mazilon/features/home/ui/quote_card_widget.dart, package:mazilon/features/home/ui/reminders_section.dart, package:mazilon/features/journal/ui/gratitude_section.dart, package:mazilon/features/mood_medicine/ui/mood_medicine_home_insights_section.dart, package:mazilon/features/personal_plan/ui/personal_plan_section.dart, package:mazilon/features/positive/ui/virtues_section.dart, package:mazilon/main_menu_dialog.dart (+16 more)

### Community 69 - "spacing.dart"
Cohesion: 0.08
Nodes (23): AppRadii, AppSpacing, badge, betweenBlocks, button, card, dashedAddSlot, hairline (+15 more)

### Community 70 - "sheet.dart"
Cohesion: 0.08
Nodes (23): arguments, barrierDismissible, build, child, _chrome, _maxHeightFactor, _maxWidth, navigator (+15 more)

### Community 71 - "breathing_widgets.dart"
Cohesion: 0.09
Nodes (23): Duration, BreathingSettings, BreathingBackgroundImage, _BreathingBackgroundImageState, breathingBackgroundLabel, BreathingDurationButtons, breathingPatternLabel, BreathingRatingInput (+15 more)

### Community 72 - "mood_medicine_insights_helper.dart"
Cohesion: 0.09
Nodes (21): BuildContext, activityChips, buildMoodMedicineCheckIn, context, form, theme, viewModel, activityFallback (+13 more)

### Community 73 - "custom_categories_storage.dart"
Cohesion: 0.09
Nodes (22): dart:convert, customCategoriesKey, customCategoriesLegacyCommitKey, customCategoryDescriptionsKey, customCategoryTitlesKey, _decodeCustomCategories, decoded, descriptions (+14 more)

### Community 74 - "list_utils.dart"
Cohesion: 0.09
Nodes (22): DateTime?, addPositiveTrait, addThankYou, datesTemp, editPositiveTrait, editThankYou, formattedDate, getListItems (+14 more)

### Community 75 - "service_locator.dart"
Cohesion: 0.10
Nodes (21): ChangeNotifier, MoodMedicineRepository, MoodMedicineStore, MoodMedicineViewModel, BreathingRepository, BreathingStore, BreathingViewModel, package:mazilon/features/mood_medicine/data/mood_medicine_report_exporter.dart (+13 more)

### Community 76 - "mood_medicine_trend_chart.dart"
Cohesion: 0.09
Nodes (21): activityColors, activityIds, build, emptyLabel, fallbackActivityColor, gridColor, highlightedActivityId, label (+13 more)

### Community 77 - "text_field.dart"
Cohesion: 0.10
Nodes (20): build, controller, createState, dispose, _editor, enabled, error, _focus (+12 more)

### Community 78 - "initial_form_page2.dart"
Cohesion: 0.10
Nodes (20): ages, _applyGenderInBackground, build, createState, dispose, _fieldGroup, _formKey, _formLabel (+12 more)

### Community 79 - "my_plan_page.dart"
Cohesion: 0.10
Nodes (20): package:flutter/gestures.dart, package:mazilon/features/personal_plan/ui/my_plan_section.dart, changeLocale, createState, _editPlanButton, fieldNames, getUserAnswers, hasFilled (+12 more)

### Community 80 - "warning_signs_section.dart"
Cohesion: 0.10
Nodes (18): build, iconAsset, ReminderItemData, reminders, RemindersSectionWidget, subtitle, title, _AddWarningCard (+10 more)

### Community 81 - "mood_medicine_repository.dart"
Cohesion: 0.12
Nodes (19): MoodMedicineSnapshot, discardUnreadableSnapshot, exceptionType, failure, kind, loadSnapshot, MoodMedicineLoadedSnapshot, MoodMedicineLoadFailure (+11 more)

### Community 82 - "spoken_phone_number_normalizer.dart"
Cohesion: 0.10
Nodes (19): _arabicDigitWords, _asciiDigitFor, candidate, _decimalZeroCodePoints, digitWords, _digitWordsFor, _englishDigitWords, _hebrewDigitWords (+11 more)

### Community 83 - "personal_plan_download.dart"
Cohesion: 0.10
Nodes (19): _activePersonalPlanDownloads, approvedPdfHosts, _computeMapHashCode, contextKey, downloadFuture, downloadPersonalPlanFile, _executeDownloadPersonalPlanFile, existingDownload (+11 more)

### Community 84 - "VoidCallback"
Cohesion: 0.11
Nodes (17): build, Button, _ButtonState, ButtonVariant, createState, fullWidth, label, onPressed (+9 more)

### Community 85 - "thank_you.dart"
Cohesion: 0.11
Nodes (18): _actionButton, build, color, _confirmDelete, createState, date, dispose, edit (+10 more)

### Community 86 - "set_notification_widget.dart"
Cohesion: 0.11
Nodes (18): build, createState, _currentHour, _currentMinute, _customMessageField, _debugPanel, dispose, initializeNotification (+10 more)

### Community 87 - "async_state_view.dart"
Cohesion: 0.11
Nodes (17): AsyncDataBuilder, AsyncEmptyPredicate, AsyncErrorRetry, AsyncLoadingIndicator, AsyncStateView, build, emptyBuilder, errorMessage (+9 more)

### Community 88 - "reminder_debug_recorder.dart"
Cohesion: 0.11
Nodes (17): clearReminderDebugEvents, loadReminderDebugPanelUnlocked, next, recordReminderDebugEvent, reminderDebugLastErrorKey, reminderDebugLastFireAtKey, reminderDebugLastStatusKey, reminderDebugLastTaskKey (+9 more)

### Community 89 - "step.dart"
Cohesion: 0.12
Nodes (17): build, category, createState, CustomCategorySave, CustomCategoryStep, CustomCategoryStepState, _delete, editorKey (+9 more)

### Community 90 - "emergency_numbers.dart"
Cohesion: 0.12
Nodes (16): Country get, countries, Country, countryCodes, countryPickerCodes, defaultEmergencyCountry, defaultPickerCountry, elemSupportOption (+8 more)

### Community 91 - "breathing_photo_importer.dart"
Cohesion: 0.12
Nodes (16): ImagePickerService, ImagePickerServiceImpl, BreathingPhotoImporter, maximumDimension, maximumInputBytes, maximumOutputBytes, _normalize, _picker (+8 more)

### Community 92 - "add_step.dart"
Cohesion: 0.12
Nodes (16): AddCustomCategoryStep, AddCustomCategoryStepState, build, createState, editorKey, index, next, onPrimaryAction (+8 more)

### Community 93 - "mood_medicine_report_delivery_types.dart"
Cohesion: 0.12
Nodes (15): _bytes, didDeliver, errorMessage, fileName, format, mimeType, moodMedicineDeliveryForShareHandoffStatus, MoodMedicineReportDelivery (+7 more)

### Community 94 - "@immutable"
Cohesion: 0.13
Nodes (15): @immutable, MoodMedicineReportAssociation, MoodMedicineReportDay, MoodMedicineReportInput, MoodMedicineReportLabels, MoodMedicineReportSection, MoodMedicineReportSource, MoodMedicinePdfContentCard (+7 more)

### Community 95 - "dialog.dart"
Cohesion: 0.13
Nodes (14): arguments, barrierDismissible, body, build, Dialog, of, onPrimary, onSecondary (+6 more)

### Community 96 - "popover.dart"
Cohesion: 0.14
Nodes (14): build, child, createState, dispose, _entry, _Layer, left, onDismiss (+6 more)

### Community 97 - "select.dart"
Cohesion: 0.13
Nodes (14): build, _Field, label, _menu, onChanged, onTap, _Option, options (+6 more)

### Community 98 - "text.dart"
Cohesion: 0.13
Nodes (14): AppTextStyle, build, color, data, maxLines, overflow, style, Text (+6 more)

### Community 99 - "tooltip.dart"
Cohesion: 0.14
Nodes (14): build, child, createState, dispose, _entry, _hide, left, message (+6 more)

### Community 100 - "mood_medicine_report_preview_page.dart"
Cohesion: 0.13
Nodes (14): MoodMedicineBuiltReport, package:mazilon/features/mood_medicine/data/mood_medicine_report_delivery_types.dart, package:mazilon/features/mood_medicine/data/mood_medicine_report_models.dart, package:pdf/pdf.dart, package:printing/printing.dart, build, MoodMedicineReportPreviewPage, _PdfReportPreview (+6 more)

### Community 101 - "LP_share_alert_dialog.dart"
Cohesion: 0.13
Nodes (14): appInfoProvider, appLocale, createState, fileService, gender, LPShareAlertDialog, memoryService, shareFile (+6 more)

### Community 102 - "file_service.dart"
Cohesion: 0.13
Nodes (14): package:file_picker/file_picker.dart, package:mazilon/features/personal_plan/data/custom_categories_storage.dart, package:mazilon/util/file_save_utils.dart, package:mazilon/util/type_utils.dart, checkEmptyMessage, download, filterEmptyData, formatPhonesText (+6 more)

### Community 103 - "app_theme.dart"
Cohesion: 0.14
Nodes (13): ColorScheme, InputDecorationThemeData, TextTheme, appDarkColorScheme, appLightColorScheme, _appTextTheme, border, buildDarkTheme (+5 more)

### Community 104 - "type_scale.dart"
Cohesion: 0.14
Nodes (13): AppTypeScale, bodyLarge, bodySmall, _family, headlineLarge, headlineMedium, labelLarge, labelSmall (+5 more)

### Community 105 - "Map"
Cohesion: 0.14
Nodes (12): FeelGoodInheritedWidget, imagePaths, imageRotations, of, updateShouldNotify, isFullScreen, of, updateShouldNotify (+4 more)

### Community 106 - "mood_medicine_report_exporter.dart"
Cohesion: 0.15
Nodes (13): build, deliver, export, _incidentLoggerService, MoodMedicineReportExporter, MoodMedicineReportExportService, _pdfRenderer, _pngRenderer (+5 more)

### Community 107 - "PagePhoneItem.dart"
Cohesion: 0.17
Nodes (12): AutomaticKeepAliveClientMixin, bool get, build, createState, icon, PagePhoneItem, _PagePhoneItemState, phoneDescription (+4 more)

### Community 108 - "dart:async"
Cohesion: 0.15
Nodes (11): dart:async, actionKey, build, PersonalPlanInfoButton, appLocale, messenger, showPersistenceRetrySnackBar, Key? (+3 more)

### Community 109 - "otp_field.dart"
Cohesion: 0.17
Nodes (12): build, _cell, _controllers, createState, dispose, initState, length, _nodes (+4 more)

### Community 110 - "personal_plan_share.dart"
Cohesion: 0.15
Nodes (12): appLocale, buildPersonalPlanExportMetadata, gender, prepareAndBuildPersonalPlanExportMetadata, sharePersonalPlanFile, username, package:mazilon/features/personal_plan/ui/share/personal_plan_export_metadata.dart, package:mazilon/util/appInformation.dart (+4 more)

### Community 111 - "slider.dart"
Cohesion: 0.17
Nodes (11): _at, build, max, min, onChanged, Slider, t, _Track (+3 more)

### Community 112 - "time_picker.dart"
Cohesion: 0.18
Nodes (11): build, calculateTime, createState, currentHour, currentMinute, initState, setTime, TimePicker (+3 more)

### Community 113 - "my_plan_section.dart"
Cohesion: 0.18
Nodes (11): answers, build, createState, _directionFor, initiallyExpanded, MyPlanSection, _MyPlanSectionState, onDelete (+3 more)

### Community 114 - "wizard_steps.dart"
Cohesion: 0.17
Nodes (11): buildWizardSteps, customCategories, planStep, steps, package:mazilon/features/personal_plan/data/phone_models.dart, package:mazilon/features/personal_plan/ui/custom_category/add_step.dart, package:mazilon/features/personal_plan/ui/custom_category/step.dart, package:mazilon/features/personal_plan/ui/form_page_template/form_page_template.dart (+3 more)

### Community 115 - "AnalyticsService"
Cohesion: 0.18
Nodes (11): Mixpanel, Mixpanel get, package:mixpanel_flutter/mixpanel_flutter.dart, AnalyticsService, init, _isInitialized, key, _mixpanel (+3 more)

### Community 116 - "gender.dart"
Cohesion: 0.18
Nodes (10): String get, applyTo, code, fromCode, fromLabel, Gender, label, labels (+2 more)

### Community 117 - "custom_category/card.dart"
Cohesion: 0.20
Nodes (9): build, category, CustomCategoryCard, _directionFor, index, onDelete, onEdit, MapEntry (+1 more)

### Community 118 - "WizardStepState"
Cohesion: 0.36
Nodes (10): FormPageTemplate, _FormPageTemplateState, ShareForm, _ShareFormState, WizardStepState, _FormPageBlocks, _FormPagePersist, _ShareFormCategories (+2 more)

### Community 119 - "package:mazilon/features/wizard/ui/wizard_step.dart"
Cohesion: 0.22
Nodes (9): _actionInFlight, build, createState, _run, step, WizardActions, _WizardActionsState, package:mazilon/design_system/widgets/button.dart (+1 more)

### Community 120 - "package:flutter/foundation.dart"
Cohesion: 0.20
Nodes (9): package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions, android, dbUsers, DefaultFirebaseOptions, ios, macos (+1 more)

### Community 121 - "mood_medicine_misc_helpers.dart"
Cohesion: 0.22
Nodes (8): MoodMedicineActivityContent, buildMoodMedicineActivityManager, buildMoodMedicineEducation, context, doseItems, l10n, selfCareSource, viewModel

### Community 122 - "locale_service.dart"
Cohesion: 0.25
Nodes (8): package:language_code/language_code.dart, static String?, getLocale, getLocaleName, locale, LocaleService, LocaleServiceImpl, setLocale

### Community 123 - "return"
Cohesion: 0.22
Nodes (8): return, canonicalLanguageCodeForLocale, code, getDirectionOfText, languageCode, languageName, regex, regexHebrew

### Community 124 - "circular_action_button.dart"
Cohesion: 0.25
Nodes (7): circularActionButton, colorScheme, diameter, iconSize, tapTargetDiameter, visual, Widget? child,
  double

### Community 125 - "font_weight.dart"
Cohesion: 0.29
Nodes (6): AppFontWeight, bold, medium, regular, semiBold, static const

### Community 126 - "shadows.dart"
Cohesion: 0.29
Nodes (6): active, AppShadows, card, sheet, package:flutter/painting.dart, static const List

### Community 127 - "AppLocalizations"
Cohesion: 0.29
Nodes (7): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsAr, AppLocalizationsEn, AppLocalizationsHe, of, LocalizationsDelegate

### Community 128 - "IncidentLoggerService"
Cohesion: 0.33
Nodes (6): package:sentry_flutter/sentry_flutter.dart, captureLog, IncidentLoggerService, initializeSentry, _sentryDsn, SentryServiceImpl

### Community 129 - "class"
Cohesion: 0.40
Nodes (5): class, MoodMedicineSourceLinkService, openExternal, UrlLauncherMoodMedicineSourceLinkService, package:url_launcher/url_launcher.dart

### Community 130 - "dart:ui"
Cohesion: 0.40
Nodes (4): dart:ui, all, L10n, static final

### Community 131 - "video_player_page_factory.dart"
Cohesion: 0.50
Nodes (4): create, VideoPlayerPageFactory, VideoPlayerPageFactoryImpl, package:mazilon/features/wellness_tools/ui/player.dart

### Community 132 - "@Deprecated"
Cohesion: 0.50
Nodes (4): @Deprecated, load, myAutoSizedText, myText

### Community 133 - "type_utils.dart"
Cohesion: 0.50
Nodes (3): castToString, castToStringList, TypeUtils

### Community 134 - "_PhonePageListState"
Cohesion: 1.00
Nodes (3): PhonePageList, _PhonePageListState, _PhonePageListSync

## Knowledge Gaps
- **5936 isolated node(s):** `AppColors`, `primary`, `onPrimary`, `secondary`, `onSecondary` (+5931 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 6123 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `UserInformation` connect `UserInformation` to `_PhonePageListState`, `userInformation.dart`, `package:flutter/material.dart`, `user_settings_page.dart`, `list.dart`, `main.dart`, `personal_plan_widget.dart`, `share_form.dart`, `menu.dart`, `package:mazilon/util/userInformation.dart`, `personal_plan_editor_page.dart`, `package:mazilon/l10n/app_localizations.dart`, `form_page_template.dart`, `onboarding_page.dart`, `dashed_list_widget.dart`, `positive_page.dart`, `phone_page.dart`, `gratitude_section.dart`, `AddForm.dart`, `country_selector.dart`, `form.dart`, `main_menu_dialog.dart`, `reminder_debug_panel.dart`, `mainpage_list_widget.dart`, `package:mazilon/features/shell/ui/LP_extended_state.dart`, `home_page.dart`, `service_locator.dart`, `initial_form_page2.dart`, `my_plan_page.dart`, `warning_signs_section.dart`, `thank_you.dart`, `set_notification_widget.dart`, `step.dart`, `add_step.dart`, `LP_share_alert_dialog.dart`, `WizardStepState`?**
  _High betweenness centrality (0.042) - this node is a cross-community bridge._
- **Why does `AppLocalizations` connect `AppLocalizations` to `app_localizations.dart`, `package:flutter/widgets.dart`, `dart:async`, `mood_medicine_page.dart`, `form.dart`, `mood_medicine_misc_helpers.dart`, `personal_plan_info_modal.dart`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `IncidentLoggerService` connect `IncidentLoggerService` to `firebase_functions.dart`, `mood_medicine_view_model.dart`, `userInformation.dart`, `main.dart`, `personal_plan_widget.dart`, `share_form.dart`, `package:mazilon/util/userInformation.dart`, `personal_plan_editor_page.dart`, `form_page_template.dart`, `image_picker_repository.dart`, `notification_repository.dart`, `PersistentMemoryService`, `sos_location_service.dart`, `list_utils.dart`, `service_locator.dart`, `personal_plan_download.dart`, `file_service.dart`, `mood_medicine_report_exporter.dart`, `personal_plan_share.dart`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **What connects `AppColors`, `primary`, `onPrimary` to the rest of the system?**
  _5936 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_localizations.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0026917900403768506 - nodes in this community are weakly interconnected._
- **Should `app_localizations_ar.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0027359781121751026 - nodes in this community are weakly interconnected._
- **Should `app_localizations_en.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0027397260273972603 - nodes in this community are weakly interconnected._