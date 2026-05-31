// ignore_for_file: annotate_overrides, prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// MyPlan is a custom widget that displays a title, a subtitle, and a list of answers in a structured format.
// It is designed to present a section of a user's plan with clear and organized visual elements.

class MyPlanSection extends StatefulWidget {
  final String title; // Title of the section being displayed.
  final String subTitle; // Subtitle providing additional context to the title.
  final List<String>
  answers; // List of answers or points to display under the section.

  const MyPlanSection({
    super.key,
    required this.title,
    required this.subTitle,
    required this.answers,
  });

  @override
  State<MyPlanSection> createState() => _MyPlanSectionState();
}

class _MyPlanSectionState extends LPExtendedState<MyPlanSection> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      color: Colors
          .transparent, // The container wraps the entire content and provides padding.
      child: Column(
        children: [
          const SizedBox(height: 25),
          // Displays the title of the plan section.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: myAutoSizedText(
              widget.title,
              TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 2, 0, 5),
              ),
              TextAlign.center,
              40,
            ),
          ),
          // Displays the subtitle with additional context.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: myAutoSizedText(
              widget.subTitle,
              TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 116, 116, 113),
              ),
              TextAlign.center,
              30,
            ),
          ),
          // ListView.builder dynamically generates a list of answers with bullet points.
          ListView.builder(
            itemBuilder: (context, index) {
              widget.answers[index]; // Accesses each answer in the list.
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15, width: 15),
                      Container(
                        width: 20,
                        child: Icon(
                          Icons.circle,
                          color: primaryPurple,
                          size: 10,
                        ), // Bullet point icon.
                      ),
                      const SizedBox(height: 15, width: 15),
                      Expanded(
                        child: myAutoSizedText(
                          widget.answers[index],
                          TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12.sp,
                            color: Colors.black,
                          ),
                          appLocale.textDirection == "rtl"
                              ? TextAlign.right
                              : TextAlign.left,
                          40,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                ],
              );
            },
            itemCount: widget
                .answers
                .length, // Number of items to display in the list.
            shrinkWrap: true,
            physics:
                NeverScrollableScrollPhysics(), // Disables scrolling within this ListView.
          ),
        ],
      ),
    );
  }
}
