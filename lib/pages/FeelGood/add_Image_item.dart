import 'package:flutter/material.dart';

import 'package:mazilon/pages/FeelGood/FeelGoodInheritedWidget.dart';
import 'package:mazilon/util/LP_extended_state.dart';

import 'package:dotted_border/dotted_border.dart';
import 'package:mazilon/util/userInformation.dart';

import 'package:provider/provider.dart';

class ImageAddItem extends StatefulWidget {
  const ImageAddItem({super.key});
  @override
  _ImageAddItemState createState() => _ImageAddItemState();
}

class _ImageAddItemState extends LPExtendedState<ImageAddItem> {
  void _showAddImageDialog(appLocale, gender, pickImage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocale!.addImageTitle(gender)),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton(
                key: Key('cameraButtonText'),
                child: Text(appLocale!.camera),
                onPressed: () {
                  pickImage("camera");
                },
              ),
              TextButton(
                key: Key('galleryButtonText'),
                child: Text(appLocale!.gallery),
                onPressed: () {
                  pickImage("gallery");
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void pickImage(String source) {
      Navigator.of(context).pop();
      FeelGoodInheritedWidget.of(context)?.getImage(source);
    }

    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    final gender = userInfoProvider.gender;
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(20),
        color: Colors.grey,
        strokeWidth: 2,
      ),
      child: Center(
        child: SizedBox.expand(
          child: TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            key: Key('addImgButtonText'),
            child: Text(
              appLocale.addImageButton(gender),
              style: const TextStyle(
                fontSize: 24.0,
              ), // adjust the font size as needed
            ),
            onPressed: () {
              _showAddImageDialog(appLocale, gender, pickImage);
            },
          ),
        ),
      ),
    );
  }
}
