import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//Widget for the name of the user in the home page
class NameBar extends StatefulWidget {
  const NameBar({required this.icons, required this.greetingString, super.key});
  final List<Widget> icons;

  final String greetingString;

  @override
  State<NameBar> createState() => NameBarState();
}

class NameBarState extends LPExtendedState<NameBar> {
  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: AutoSizeText(
                      appLocale.greetings(userInfoProvider.name),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ),
                Row(children: widget.icons),
              ],
            ),
            Semantics(
              header: true,
              child: Text(
                widget.greetingString,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
