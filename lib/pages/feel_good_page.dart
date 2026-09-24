import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/async/analytics_service.dart';
import 'package:mazilon/util/async/logger_service.dart';

import 'package:mazilon/features/feel_good/ui/feel_good_inherited_widget.dart';
import 'package:mazilon/features/feel_good/ui/add_image_item.dart';
import 'package:mazilon/features/feel_good/ui/image_display_item.dart';
import 'package:mazilon/features/feel_good/data/image_picker_repository.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/features/shell/ui/async_state_view.dart';
import 'package:mazilon/features/shell/ui/directional_widgets.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class FeelGood extends StatefulWidget {
  const FeelGood({super.key});

  @override
  _FeelGoodPageState createState() => _FeelGoodPageState();
}

class _FeelGoodPageState extends LPExtendedState<FeelGood> {
  late ImagePickerService pickerService;
  List<String> imagePaths = [];
  Map<String, int> imageRotations = {};
  late Future<List<String>> _loadImagesFuture;
  final ScrollController _scrollController = ScrollController();
  AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();

  @override
  void initState() {
    super.initState();
    pickerService = GetIt.instance<ImagePickerService>();
    _loadImagesFuture = _loadImagePaths();
  }

  // Phase E (ADR-005 §Decision step 5): returns the loaded paths so the
  // shared [AsyncStateView] can drive loading/error/data states. Clears
  // first so a retry does not append duplicates onto a partial load.
  Future<List<String>> _loadImagePaths() async {
    imagePaths.clear();
    await pickerService.loadImagePaths(imagePaths);
    imageRotations = await pickerService.loadImageRotations();
    return imagePaths;
  }

  void _saveImageRotationsInBackground() {
    final snapshot = Map<String, int>.from(imageRotations);
    unawaited(_saveImageRotations(snapshot));
  }

  Future<void> _saveImageRotations(Map<String, int> snapshot) async {
    try {
      await pickerService.saveImageRotations(snapshot);
    } catch (error, stackTrace) {
      debugPrint('Unable to save image rotations: $error\n$stackTrace');
      if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
        try {
          await GetIt.instance<IncidentLoggerService>().captureLog(
            error,
            stackTrace: stackTrace,
          );
        } catch (_) {
          // The failed write has already been observed above.
        }
      }
    }
  }

  void _rotateImage(int index) {
    if (index >= 0 && index < imagePaths.length) {
      final path = imagePaths[index];
      final current = imageRotations[path] ?? 0;
      final next = (current + 1) % 4;
      setState(() {
        imageRotations[path] = next;
      });
      _saveImageRotationsInBackground();
    }
  }

  int _getImageRotation(String path) {
    return imageRotations[path] ?? 0;
  }

  // Phase E: retry hook for the shared error state — re-arms the future so
  // the FutureBuilder re-runs the load.
  void _retryLoadImages() {
    setState(() {
      _loadImagesFuture = _loadImagePaths();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gender = Provider.of<UserInformation>(context, listen: false).gender;

    return FeelGoodInheritedWidget(
      displayImage: pickerService.displayImage,
      imagePaths: [...imagePaths],
      imageRotations: Map.unmodifiable(imageRotations),
      getImage: (String source) async {
        await pickerService.getImage(source, imagePaths);
        setState(() {});
      },
      deleteImage: _deleteImage,
      rotateImage: _rotateImage,
      getImageRotation: _getImageRotation,
      child: _page(gender),
    );
  }

  void _deleteImage(int index) {
    if (index < 0 || index >= imagePaths.length) return;
    final path = imagePaths[index];
    try {
      pickerService.deleteImage(index, imagePaths);
      setState(() {
        imageRotations.remove(path);
      });
      _saveImageRotationsInBackground();
    } catch (error, stackTrace) {
      if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
        GetIt.instance<IncidentLoggerService>()
            .captureLog(error, stackTrace: stackTrace);
      }
    }
  }

  Widget _page(String gender) {
    final logoWidth = MediaQuery.of(context).size.width * 0.4 > 1000
        ? 500.0
        : MediaQuery.of(context).size.width * 0.2;
    return Scaffold(
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                children: [
                  LivingPositivelyLogo(width: logoWidth),
                  _title(gender),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: myAutoSizedText(
                      appLocale.feelGoodSubTitle(gender),
                      TextStyle(fontSize: 18.sp),
                      null,
                      18,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: _imageGrid(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String gender) {
    return Container(
      alignment: Alignment.topCenter,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: myAutoSizedText(
        appLocale.feelGoodTitle(gender),
        TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 30.sp,
        ),
        TextAlign.center,
        60,
      ),
    );
  }

  Widget _imageGrid() {
    // Images stay shrink-wrapped so the page scroll view owns scrolling.
    return AsyncStateView<List<String>>(
      future: _loadImagesFuture,
      onRetry: _retryLoadImages,
      // Read live `imagePaths` (mutated by add/delete), not the snapshot.
      onData: (context, _) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: imagePaths.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemBuilder: (context, index) {
            if (index == imagePaths.length) {
              return ImageAddItem();
            }
            return ImageDisplay(
              imagePath: imagePaths[index],
              index: index,
              imagePaths: imagePaths,
            );
          },
        );
      },
    );
  }
}
