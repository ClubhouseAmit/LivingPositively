import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/pages/FeelGood/FeelGoodInheritedWidget.dart';
import 'package:mazilon/pages/FeelGood/add_Image_item.dart';
import 'package:mazilon/pages/FeelGood/image_display_item.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/async/async_state_view.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';

class FeelGood extends StatefulWidget {
  const FeelGood({super.key});

  @override
  _FeelGoodPageState createState() => _FeelGoodPageState();
}

class _FeelGoodPageState extends LPExtendedState<FeelGood> {
  late ImagePickerService pickerService;
  List<String> imagePaths = [];
  late Future<List<String>> _loadImagesFuture;
  //final picker = ImagePicker();
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
    return imagePaths;
  }

  // Phase E: retry hook for the shared error state — re-arms the future so
  // the FutureBuilder re-runs the load.
  void _retryLoadImages() {
    setState(() {
      _loadImagesFuture = _loadImagePaths();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    final gender = userInfoProvider.gender;

    return FeelGoodInheritedWidget(
      displayImage: pickerService.displayImage,
      imagePaths: [...imagePaths],
      getImage: (source) async {
        await pickerService.getImage(source, imagePaths);
        setState(() {});
      },
      deleteImage: (index) {
        setState(() {
          pickerService.deleteImage(index, imagePaths);
        });
      },
      child: PageLayoutWrapper(
        sliverAppBar: PremiumGlassAppBar(
          variant: AppBarVariant.rootTab,
          titleText: appLocale.homePageFeelGood(gender),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Spacing.md),
            Text(
              appLocale.feelGoodTitle(gender),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: Spacing.xs),
            Text(
              appLocale.feelGoodSubTitle(gender),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            SizedBox(height: Spacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  child: Scrollbar(
                    //images uploaded from phone grid view:
                    // Phase E (ADR-005 §Decision step 5): the bare
                    // FutureBuilder here showed a spinner only while waiting
                    // and rendered an empty grid on failure with no recovery
                    // (UX_GAPS.md §3.10). Routed through the shared
                    // AsyncStateView so loading is screen-reader announced and
                    // a failed load surfaces a retry affordance.
                    child: AsyncStateView<List<String>>(
                      future: _loadImagesFuture,
                      onRetry: _retryLoadImages,
                      // The data builder reads the live `imagePaths` field
                      // (mutated by add/delete) rather than the resolved
                      // snapshot, so the grid stays in sync after edits.
                      onData: (context, _) {
                        return GridView.builder(
                          shrinkWrap:
                              true, // Ensures GridView works inside SingleChildScrollView
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              imagePaths.length +
                              1, // +1 for the camera/upload icon
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2 items per row
                                crossAxisSpacing: 10, // horizontal spacing
                                mainAxisSpacing: 10, // vertical spacing
                              ),
                          itemBuilder: (context, index) {
                            // If this is the last item, return a grid item with the camera and upload icons
                            if (index == imagePaths.length) {
                              return const ImageAddItem();
                            }
                            return ImageDisplay(
                              imagePath: imagePaths[index],
                              index: index,
                              imagePaths: imagePaths,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.bottomPadding),
            ],
          ),
        ),
    );
  }
}
