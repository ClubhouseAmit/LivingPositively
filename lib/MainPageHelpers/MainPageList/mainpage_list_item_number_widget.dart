import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/styles.dart';
import 'dart:math';

class ListItemNumberWidget extends StatelessWidget {
  final int index;

  const ListItemNumberWidget({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: index + 1 < 10
            ? const EdgeInsets.symmetric(horizontal: 13, vertical: 7)
            : const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        color: primaryPurple,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: min(30, index + 1 < 10 ? (14.sp) : (10.sp)),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
