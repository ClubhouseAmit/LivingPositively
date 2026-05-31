import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'thankYou.dart';
import 'thanksItemSug.dart';
import 'AddForm.dart';
import 'dart:math';

class Journal extends StatefulWidget {
  final Map<String, dynamic> fakeSharedPreferencesStorage;
  const Journal({super.key, required this.fakeSharedPreferencesStorage});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> {
  List<String> thanksSuggestionsList = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
  ];
  List<String> thankYous = [];
  List<FocusNode> focusNodes = [];
  List<String> dates = [];
  FocusNode myFocusNode = FocusNode();
  String journalMainTitle = '';
  String journalSubTitle = '';
  String sug1 = '';
  String sug2 = '';
  String sug3 = '';
  int counter = 0;

  void loadData() async {
    setState(() {
      thankYous = widget.fakeSharedPreferencesStorage['thankYous'] ?? [];
      dates = widget.fakeSharedPreferencesStorage['dates'] ?? [];
      // journalTitle = journalTitleTmp;
      for (var _ in thankYous) {
        focusNodes.add(FocusNode());
      }
      /* for (int i = 0; i < thankYous.length; i++) {
        focusNodes.add(FocusNode());
      }*/
    });
  }

  void changeThankYou(String text, int index) async {
    setState(() {
      thankYous[index] = text;
      widget.fakeSharedPreferencesStorage['thankYous'] = thankYous;
    });
  }

  void removeThankYou(int removeIndex) async {
    List<String> thankyousTemp =
        widget.fakeSharedPreferencesStorage['thankYous'] ?? [];
    List<String> datesTemp = widget.fakeSharedPreferencesStorage['dates'] ?? [];
    thankyousTemp.removeAt(removeIndex);
    datesTemp.removeAt(removeIndex);
    setState(() {
      widget.fakeSharedPreferencesStorage['thankYous'] = thankyousTemp;

      thankYous = thankyousTemp;
      focusNodes.removeAt(removeIndex);
      widget.fakeSharedPreferencesStorage['dates'] = datesTemp;
      dates = datesTemp;
    });
  }

  void addThankYou(String thankYou) async {
    counter = counter < 6 ? counter + 1 : counter;

    List<String> thankyousTemp =
        widget.fakeSharedPreferencesStorage['thankYous'] ?? [];
    List<String> datesTemp = widget.fakeSharedPreferencesStorage['dates'] ?? [];

    thankyousTemp.add(thankYou);

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    datesTemp.add(formattedDate);

    setState(() {
      widget.fakeSharedPreferencesStorage['thankYous'] = thankyousTemp;

      thankYous = thankyousTemp;
      focusNodes.add(FocusNode());
      widget.fakeSharedPreferencesStorage['dates'] = datesTemp;

      dates = datesTemp;
    });
    if (counter == 1) {
      showPopup();
    }
    //add at the end after fixing other issues
    // if(counter == 5){
    //   showPopup2();
    // }
  }

  void showPopup() {
    Future.delayed(Duration(seconds: 0), () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(''),
            content: Text(
              "פופ אפ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Close'),
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

  @override
  void initState() {
    super.initState();
    loadData();

    sug1 =
        thanksSuggestionsList[Random().nextInt(thanksSuggestionsList.length)];
    sug2 =
        thanksSuggestionsList[Random().nextInt(thanksSuggestionsList.length)];
    sug3 =
        thanksSuggestionsList[Random().nextInt(thanksSuggestionsList.length)];
  }

  void editNotification(String text, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddForm(
          add: addThankYou,
          index: index,
          edit: changeThankYou,
          text: text,
          formTitle: 'תודה',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardDismisser(
        gestures: const [
          GestureType.onTap,
          GestureType.onPanUpdateAnyDirection,
        ],
        child: Scaffold(
          backgroundColor: Colors.white,
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 40, 20, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          key: Key('addThankYouPlus'),
                          onPressed: () {
                            editNotification("", 0);
                          },
                          icon: const Icon(
                            Icons.add,
                            size: 50.0,
                            color: Colors.purple,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Text('תודו ליסט'),
                        ),
                      ],
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [Text('על מה אני מודה היום')],
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => ThankYou(
                  key: Key('ThankYou$index'),
                  text: thankYous[index],
                  number: (index + 1),
                  edit: editNotification,
                  remove: removeThankYou,
                  myFocusNode: focusNodes[index],
                  date: dates[index],
                  color: Colors.black,
                ),
                itemCount: thankYous.length,
              ),
              thankYous.isEmpty
                  ? Container()
                  : const Divider(
                      color: Colors.white,
                      indent: 30,
                      endIndent: 30,
                    ),
              ThanksItemSuggested(
                key: Key("Sug1"),
                add: addThankYou,
                inputText: sug1,
              ),
              ThanksItemSuggested(
                key: Key("Sug2"),
                add: addThankYou,
                inputText: sug2,
              ),
              ThanksItemSuggested(
                key: Key("Sug3"),
                add: addThankYou,
                inputText: sug3,
              ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    var indices = List<int>.generate(
                      thanksSuggestionsList.length,
                      (i) => i,
                    );
                    indices.shuffle();
                    sug1 = thanksSuggestionsList[indices[0]];
                    sug2 =
                        thanksSuggestionsList[indices[thanksSuggestionsList
                                    .length >
                                1
                            ? 1
                            : 0]];
                    sug3 =
                        thanksSuggestionsList[indices[thanksSuggestionsList
                                    .length >
                                2
                            ? 2
                            : 0]];
                  });
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'הצעות אחרות',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 1.0),
                    Icon(Icons.refresh, color: Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
