import 'package:flutter/material.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class ShowAllButton extends StatefulWidget {
  final Function(BuildContext, PagesCode) onTabTapped;
  final PagesCode pageCode;
  final int? count;

  const ShowAllButton({
    super.key,
    required this.onTabTapped,
    required this.pageCode,
    this.count,
  });

  @override
  State<ShowAllButton> createState() => _ShowAllButtonState();
}

class _ShowAllButtonState extends LPExtendedState<ShowAllButton> {
  @override
  Widget build(BuildContext context) {
    final userInfoProvider =
        Provider.of<UserInformation>(context, listen: true);

    final gender = userInfoProvider.gender;

    // Build the label: "Show all (N) →" if count is provided
    final countSuffix = widget.count != null ? ' (${widget.count})' : '';
    final label = '${appLocale.showAll(gender)}$countSuffix';

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
                label,
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
