// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/LP_extended_state.dart';

// MyPlan is a custom widget that displays a title, a subtitle, and a list of answers in a structured format.
// It is designed to present a section of a user's plan with clear and organized visual elements.

class MyPlanSection extends StatefulWidget {
  // List of answers or points to display under the section.

  const MyPlanSection({
    required this.title,
    required this.subTitle,
    required this.answers,
    super.key,
  });
  final String title; // Title of the section being displayed.
  final String subTitle; // Subtitle providing additional context to the title.
  final List<String> answers;

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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Padding(
        padding: EdgeInsets.all(Spacing.md),
        child: Column(
          children: [
            // Displays the title of the plan section.
            Semantics(
              header: true,
              child: Padding(
                padding: EdgeInsets.all(Spacing.sm),
                child: AutoSizeText(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Displays the subtitle with additional context.
            Padding(
              padding: EdgeInsets.all(Spacing.sm),
              child: AutoSizeText(
                widget.subTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // ListView.builder dynamically generates a list of answers with bullet points.
            ListView.builder(
              itemBuilder: (context, index) {
                widget.answers[index]; // Accesses each answer in the list.
                return Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(height: Spacing.md, width: Spacing.md),
                        Container(
                          width: 20,
                          child: Icon(
                            Icons.circle,
                            color: colorScheme.primary,
                            size: 10,
                          ), // Bullet point icon.
                        ),
                        SizedBox(height: Spacing.md, width: Spacing.md),
                        Expanded(
                          child: AutoSizeText(
                            widget.answers[index],
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Spacing.xs),
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
      ),
    );
  }
}
