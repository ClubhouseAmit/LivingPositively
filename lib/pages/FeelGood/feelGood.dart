import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';

import 'package:mazilon/pages/FeelGood/FeelGoodInheritedWidget.dart';
import 'package:mazilon/pages/FeelGood/add_Image_item.dart';
import 'package:mazilon/pages/FeelGood/image_display_item.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/l10n/app_localizations.dart';

class FeelGood extends StatefulWidget {
  const FeelGood({super.key});

  @override
  _FeelGoodPageState createState() => _FeelGoodPageState();
}

class _FeelGoodPageState extends LPExtendedState<FeelGood> {
  late ImagePickerService pickerService;
  List<String> imagePaths = [];
  late Future<void> _loadImagesFuture;
  //final picker = ImagePicker();
  AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
  @override
  void initState() {
    super.initState();
    pickerService = GetIt.instance<ImagePickerService>();

    _loadImagesFuture = _loadImagePaths();
  }

  Future<void> _loadImagePaths() async {
    await pickerService.loadImagePaths(imagePaths);
    setState(() {});
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
            child: Container(
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
                    appLocale!.feelGoodTitle(gender),
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
                    appLocale!.feelGoodSubTitle(gender),
                    TextStyle(fontSize: 18.sp),
                    null,
                    18,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Scrollbar(
                    //images uploaded from phone grid view:
                    child: FutureBuilder<void>(
                      future: _loadImagesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

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
