import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/pages/thankYou.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/Thanks/thanksItemSug.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//Journal page, where the user can write thank you notes (add , edit, remove notes)
//the user can also see suggested thank you notes and refresh them
//(the code here is not related to todo list in home page, its the thank you notes page)
class Journal extends StatefulWidget {
  const Journal({
    required this.fullSuggestionList,
    this.onBackPressed,
    super.key,
  });
  final List<String> fullSuggestionList;
  final VoidCallback? onBackPressed;

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends LPExtendedState<Journal> {
  List<String> thankYous = []; //list of thank you notes
  List<FocusNode> focusNodes = []; //list of focus nodes for each thank you note
  List<String> dates = []; //list of dates for each thank you note
  FocusNode myFocusNode = FocusNode(); //focus node for the text field
  String journalMainTitle = ''; //journal main title
  String journalSubTitle = ''; //journal sub title
  String sug1 = ''; //suggested thank you note 1
  String sug2 = ''; //suggested thank you note 2
  String sug3 = ''; //suggested thank you note 3
  int counter =
      0; //counter for the number of thank you notes you added (reset to 0 every time you enter the journal page again)
  List<String> thanksSuggestionList = []; //list of thank you notes suggestions

  void _syncFocusNodes(int count) {
    while (focusNodes.length < count) {
      focusNodes.add(FocusNode());
    }
    while (focusNodes.length > count) {
      focusNodes.removeLast().dispose();
    }
  }

  void _refreshSuggestions() {
    final tempThanksSuggestionList = List<String>.from(
      widget.fullSuggestionList,
    );
    thanksSuggestionList = List<String>.from(tempThanksSuggestionList);

    for (final suggestion in tempThanksSuggestionList) {
      if (thanksSuggestionList.length > 3 && thankYous.contains(suggestion)) {
        thanksSuggestionList.remove(suggestion);
      }
    }

    if (thanksSuggestionList.isEmpty) {
      sug1 = '';
      sug2 = '';
      sug3 = '';
      return;
    }

    final indices = List<int>.generate(thanksSuggestionList.length, (i) => i);
    indices.shuffle();
    sug1 = thanksSuggestionList[indices[0]];
    sug2 =
        thanksSuggestionList[indices[thanksSuggestionList.length > 1 ? 1 : 0]];
    sug3 =
        thanksSuggestionList[indices[thanksSuggestionList.length > 2 ? 2 : 0]];
  }

  List<String> todayThankYousFunc(List<String> thankYous, List<String> dates) {
    final todayThankYous = <String>[];
    final now = DateTime.now();
    final formattedDate = intl.DateFormat('yyyy-MM-dd – kk:mm').format(now);

    for (var i = 0; i < dates.length; i++) {
      if (dates[i].substring(0, 10) == formattedDate.substring(0, 10)) {
        todayThankYous.add(thankYous[i]);
      }
    }
    return todayThankYous;
  }

  //load the thank you notes and suggestions from the shared preferences
  void loadData(BuildContext context) {
    debugPrint('loading journal');
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );

    thankYous = List<String>.from(userInfoProvider.thanks['thanks'] ?? []);
    dates = List<String>.from(userInfoProvider.thanks['dates'] ?? []);
    _syncFocusNodes(thankYous.length);
    _refreshSuggestions();
  }

  // change the thank you note text at the index to the new text
  void editThankYou(String text, int index, UserInformation userinfoProvider) {
    setState(() {
      thankYous[index] = text;
      userinfoProvider.updateThanks({
        'thanks': thankYous,
        'dates': userinfoProvider.thanks['dates'] ?? [],
      });
    });
  }

  // remove the thank you note at the index
  void removeThankYou(int removeIndex, UserInformation userInfoProvider) {
    final thankyousTemp = userInfoProvider.thanks['thanks'] ?? [];
    final datesTemp = userInfoProvider.thanks['dates'] ?? [];
    thankyousTemp.removeAt(removeIndex);
    datesTemp.removeAt(removeIndex);
    setState(() {
      userInfoProvider.updateThanks({
        'thanks': thankyousTemp,
        'dates': datesTemp,
      });
      thankYous = thankyousTemp;
      focusNodes.removeAt(removeIndex);
      dates = datesTemp;
    });
  }

  // add the thank you note to the list
  void addThankYou(String thankYou, UserInformation userInfoProvider) {
    counter = counter < 6 ? counter + 1 : counter;
    final thankyousTemp = userInfoProvider.thanks['thanks'] ?? [];
    final datesTemp = userInfoProvider.thanks['dates'] ?? [];
    thankyousTemp.add(thankYou);
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    datesTemp.add(formattedDate);
    setState(() {
      userInfoProvider.updateThanks({
        'thanks': thankyousTemp,
        'dates': datesTemp,
      });
      thankYous = thankyousTemp;
      focusNodes.add(FocusNode());

      dates = datesTemp;
    });
    //show the popup after adding the first thank you note (every time you enter the journal page)
    if (todayThankYousFunc(
          userInfoProvider.thanks['thanks'] ?? [],
          userInfoProvider.thanks['dates'] ?? [],
        ).length ==
        1) {
      showThankYouPopup(userInfoProvider);
    }
    final mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent('Item added to Gratitude Journal');
    //you can show the popup after adding the i-th thank you note (every time you enter the journal page)
    // if(counter == i){
    //   showPopupFunction();
    // }
  }

  //show the popup with the text from the shared preferences
  void showThankYouPopup(UserInformation userInfoProvider) {
    Future.delayed(const Duration(), () {
      if (!mounted) {
        return;
      }
      final gender = userInfoProvider.gender;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(''),
            content: Text(
              appLocale.homePageThankyouPopup(gender),
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15.sp),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  appLocale.confirmButton(gender),
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  //load the data when the page is opened
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData(context);
  }

  @override
  void dispose() {
    for (final focusNode in focusNodes) {
      focusNode.dispose();
    }
    myFocusNode.dispose();
    super.dispose();
  }

  // function we call when we want to add/edit a thank you note (to open the popup with the text field which is AddForm widget)
  void editThanks(String title, [String text = '', int index = 0]) {
    showDialog(
      context: context,
      builder: (context) {
        return AddForm(
          add: addThankYou,
          index: index,
          edit: editThankYou,
          text: text,
          formTitle: title,
        );
      },
    );
  }

  // build the journal page
  @override
  Widget build(BuildContext context) {
    // get the app and user information providers

    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    final gender = userInfoProvider.gender;
    final colorScheme = Theme.of(context).colorScheme;
    return KeyboardDismisser(
      gestures: const [GestureType.onTap, GestureType.onPanUpdateAnyDirection],
      child: PageLayoutWrapper(
        sliverAppBar: PremiumGlassAppBar(
          variant: AppBarVariant.detailScreen,
          onBackPressed: widget.onBackPressed,
          titleText: appLocale.homePageThanksMainTitle(gender),
          actions: [
            IconButton(
              onPressed: () {
                editThanks(appLocale.thanks);
              },
              tooltip: appLocale.addItemTooltip,
              icon: Icon(
                Icons.add,
                size: 28,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: Spacing.sm),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Spacing.md),
            Text(
              appLocale.homePageThanksMainTitle(gender),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: Spacing.xs),
            Text(
              appLocale.homePageThanksSecondaryTitle(gender),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            SizedBox(height: Spacing.lg),
            //the list of thank you notes
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => ThankYou(
                text: thankYous[index],
                number: index + 1,
                edit: (String text, int index) {
                  editThanks(appLocale.thanks, text, index);
                },
                remove: (int index) => removeThankYou(index, userInfoProvider),
                myFocusNode: focusNodes[index],
                date: dates[index],
                color: colorScheme.onSurface,
              ),
              itemCount: thankYous.length,
            ),
            if (thankYous.isEmpty) Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: AutoSizeText(
                      appLocale.journalEmptyGuidance,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                            fontWeight: FontWeight.normal,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ) else Divider(
                    color: colorScheme.outline,
                    indent: 30,
                    endIndent: 30,
                  ),
            //the suggested thank you notes
            if (sug1.isNotEmpty)
              ThanksItemSuggested(
                stopShowing: 3,
                add: addThankYou,
                inputText: sug1,
                fullSuggestionList: retrieveThanksList(
                  appLocale,
                  gender == '' ? 'other' : gender,
                ),
              ),
            if (sug2.isNotEmpty && sug1 != sug2)
              ThanksItemSuggested(
                stopShowing: 2,
                add: addThankYou,
                inputText: sug2,
                fullSuggestionList: retrieveThanksList(
                  appLocale,
                  gender == '' ? 'other' : gender,
                ),
              ),
            if (sug3.isNotEmpty && sug1 != sug3)
              ThanksItemSuggested(
                stopShowing: 1,
                add: addThankYou,
                inputText: sug3,
                fullSuggestionList: retrieveThanksList(
                  appLocale,
                  gender == '' ? 'other' : gender,
                ),
              ),
            //the button to refresh the suggested thank you notes and get 3 new suggestions
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: TextButton(
                onPressed: () async {
                  setState(_refreshSuggestions);
                },
                //the text of the refresh button
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      appLocale.otherSuggestions(gender),
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 1),
                    Icon(LucideIcons.wand2, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
