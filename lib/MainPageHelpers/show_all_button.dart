import 'package:flutter/material.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class ShowAllButton extends StatefulWidget {
  const ShowAllButton({
    required this.onTabTapped, required this.pageCode, super.key,
  });
  final Function(BuildContext, PagesCode) onTabTapped;
  final PagesCode pageCode;

  @override
  State<ShowAllButton> createState() => _ShowAllButtonState();
}

class _ShowAllButtonState extends LPExtendedState<ShowAllButton> {
  @override
  Widget build(BuildContext context) {
    final userInfoProvider =
        Provider.of<UserInformation>(context, listen: false);

    final gender = userInfoProvider.gender;
    return Row(
      children: [
        TextButton(
          onPressed: () {
            widget.onTabTapped(context, widget.pageCode);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                appLocale.showAll(gender),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
