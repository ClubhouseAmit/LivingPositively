import 'package:flutter/material.dart';

import 'sectionBarHometest.dart';
import 'thanksItemSugtest.dart';

class ThanksListWidget extends StatefulWidget {
  final List<String> thanks;
  final Function add;
  final Function edit;
  final Function remove;
  final int thanksListLength;
  final Function addSuggested;
  final Function(int) onTabTapped;
  const ThanksListWidget({
    super.key,
    required this.thanks,
    required this.add,
    required this.edit,
    required this.remove,
    required this.thanksListLength,
    required this.addSuggested,
    required this.onTabTapped,
  });

  @override
  State<ThanksListWidget> createState() => _ThanksListWidgetState();
}

class _ThanksListWidgetState extends State<ThanksListWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: MediaQuery.of(context).size.width > 1000
              ? 800
              : MediaQuery.of(context).size.width * 1,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: [
                SectionBarHome(
                  text: '',
                  textWidget: TextButton(
                    onPressed: () {
                      widget.onTabTapped(3);
                    },
                    child: Text('1'),
                  ),
                  icon: Icons.add,
                  icons: [
                    IconButton(
                      key: Key("addButton"),
                      icon: Icon(Icons.add, size: 30),
                      onPressed: () {
                        setState(() {
                          widget.add("Test Text");
                        });
                      },
                    ),
                  ],
                  subHeader: '2',
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 315), //max height
                  child: SingleChildScrollView(
                    child: Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8.0, // gap between adjacent chips
                      runSpacing: 4.0, // gap between lines
                      children: widget.thanks.asMap().entries.map((entry) {
                        int index = entry.key;
                        String thank = entry.value;
                        return Container(
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  minHeight: 20,
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * 0.76,
                                ),
                                height: 50,
                                width: MediaQuery.of(context).size.width > 1000
                                    ? 600
                                    : MediaQuery.of(context).size.width * 0.8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(95),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        child: MaterialButton(
                                          key: Key('deleteButton_$index'),
                                          onPressed: () {
                                            setState(() {
                                              widget.remove(index);
                                            });
                                          },
                                          splashColor: Colors.transparent,
                                          enableFeedback: false,
                                          child: Icon(Icons.delete),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 32,
                                        child: MaterialButton(
                                          key: Key('editButton_$index'),
                                          onPressed: () {
                                            setState(() {
                                              widget.edit('Edit Text', index);
                                            });
                                          },
                                          splashColor: Colors.transparent,
                                          enableFeedback: false,
                                          child: Icon(Icons.edit),
                                        ),
                                      ),
                                      SizedBox(width: 15),
                                      Expanded(
                                        child: Container(
                                          child: Directionality(
                                            textDirection: TextDirection.rtl,
                                            child: Text(thank),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 15),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 5,
                                  ),
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
                    padding: EdgeInsets.all(0.0),
                    child: ThanksItemSuggested(
                      add: () => {
                        setState(() {
                          widget.addSuggested();
                        }),
                      },
                      inputText: "",
                    ),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        widget.onTabTapped(3);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.arrow_back_ios, size: 12),
                          Text('3'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
