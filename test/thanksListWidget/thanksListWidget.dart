import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';

import 'AddForm.dart';
import 'sectionBarHome.dart';
//import 'package:mazilon/util/Thanks/thanksItem.dart';
import 'thanksItemSug.dart';

class ThanksListWidget extends StatefulWidget {
  const ThanksListWidget({
    required this.thanks, required this.add, required this.edit, required this.remove, required this.thanksListLength, required this.addSuggested, required this.onTabTapped, super.key,
    this.journalMainTitle = 'Journal',
    this.journalSubTitle = 'Journal entries',
  });
  final List<String> thanks;
  final Function add;
  final Function edit;
  final Function remove;
  final int thanksListLength;
  final Function addSuggested;
  final Function(int) onTabTapped;
  final String journalMainTitle;
  final String journalSubTitle;

  @override
  State<ThanksListWidget> createState() => _ThanksListWidgetState();
}

class _ThanksListWidgetState extends State<ThanksListWidget> {
  @override
  void initState() {
    super.initState();
  }

  void addThanks(thank) {
    setState(() {
      widget.add(thank);
    });
  }

  void editThanks(thank, index) {
    setState(() {
      widget.edit(thank, index);
    });
  }

  void removeThank(index) {
    setState(() {
      widget.remove(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    void addThanksNotification() {
      setState(() {
        showDialog(
          context: context,
          builder: (context) {
            return AddForm(
              add: addThanks,
              index: 0,
              edit: editThanks,
              text: '',
              formTitle: 'תודה',
            );
          },
        );
      });
    }

    void editThanksNotification(String text, int index) {
      showDialog(
        context: context,
        builder: (context) {
          return AddForm(
            add: addThanks,
            index: index,
            edit: editThanks,
            text: text,
            formTitle: 'תודה',
          );
        },
      );
    }

    return SizedBox(
      width: 800 > 1000
          ? 800
          : 800 * 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            SectionBarHome(
              text: '',
              textWidget: TextButton(
                key: const Key('tab3'),
                onPressed: () {
                  setState(() {
                    widget.onTabTapped(3);
                  });
                },
                child: Text(widget.journalMainTitle),
              ),
              icon: FontAwesome5.praying_hands,
              icons: [
                IconButton(
                  key: const Key('addButton'),
                  icon: const Icon(Icons.add, color: Colors.purple, size: 30),
                  onPressed: () {
                    setState(addThanksNotification);
                  },
                ),
              ],
              subHeader: widget.journalSubTitle,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 315), //max height
              child: SingleChildScrollView(
                child: Wrap(
                  textDirection: TextDirection.rtl,
                  spacing: 8, // gap between adjacent chips
                  runSpacing: 4, // gap between lines
                  children: widget.thanks.asMap().entries.map((entry) {
                    final index = entry.key;

                    final thank = entry.value;
                    return Container(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            constraints: const BoxConstraints(
                              minHeight: 20,
                              maxWidth: 800 * 0.76,
                            ),
                            height: 50,
                            width: 800 > 1000
                                ? 600
                                : 800 * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(95),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: MaterialButton(
                                      key: Key('removeButton$index'),
                                      onPressed: () {
                                        setState(() {
                                          removeThank(
                                            widget.thanksListLength -
                                                widget.thanks.length +
                                                index,
                                          );
                                        });
                                      },
                                      splashColor: Colors.transparent,
                                      enableFeedback: false,
                                      child: const Icon(Icons.delete),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: MaterialButton(
                                      key: Key('editButton$index'),
                                      onPressed: () {
                                        setState(() {
                                          editThanksNotification(
                                            widget.thanks[index],
                                            widget.thanksListLength -
                                                widget.thanks.length +
                                                index,
                                          );
                                        });
                                      },
                                      splashColor: Colors.transparent,
                                      enableFeedback: false,
                                      child: const Icon(Icons.edit),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Container(
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(thank),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 5,
                              ),
                              color: Colors.purple,
                              child: Text('${index + 1}'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: ThanksItemSuggested(
                  key: const ValueKey('Sug'),
                  add: widget.addSuggested,
                  inputText: '',
                ),
              ),
            ),
            Row(
              children: [
                TextButton(
                  key: const Key('tab4'),
                  onPressed: () {
                    setState(() {
                      widget.onTabTapped(4);
                    });
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.arrow_back_ios, size: 12),
                      Text('ראה.י הכל'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
