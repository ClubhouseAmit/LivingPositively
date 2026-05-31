import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';

import 'package:mazilon/pages/FeelGood/FeelGoodInheritedWidget.dart';
import 'package:mazilon/pages/FeelGood/add_Image_item.dart';
import 'package:mazilon/pages/FeelGood/image_display_item.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/async/async_state_view.dart';
import 'package:mazilon/util/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      getImage: (String source) async {
        await pickerService.getImage(source, imagePaths);
        setState(() {});
      },
      deleteImage: (int index) {
        setState(() {
          pickerService.deleteImage(index, imagePaths);
        });
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(150.0),
          child: SafeArea(
            child: SizedBox(
              height: 130.0,
              child: Image.asset(
                'assets/images/Logo.png',
                width: MediaQuery.of(context).size.width * 0.4 > 1000
                    ? 500
                    : MediaQuery.of(context).size.width * 0.2,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.topCenter,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  child: myAutoSizedText(
                    appLocale.feelGoodTitle(gender),
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      // .sp so the heading scales with system text-scale.
                      fontSize: 30.sp,
                    ),
                    TextAlign.center,
                    60,
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: myAutoSizedText(
                    appLocale.feelGoodSubTitle(gender),
                    TextStyle(fontSize: 18.sp),
                    null,
                    18,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
