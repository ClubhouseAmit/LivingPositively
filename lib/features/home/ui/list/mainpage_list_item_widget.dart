import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';

class MainpageListItemWidget extends StatelessWidget {
  final String item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MainpageListItemWidget({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 20,
        maxWidth: MediaQuery.sizeOf(context).width * 0.76,
      ),
      height: 80,
      width: MediaQuery.of(context).size.width > 1000
          ? 600
          : MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                maxLines: 2,
                item,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: "Rubix",
                  fontSize: min(30, 16.sp),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 15),
            SizedBox(
              width: 32,
              child: MaterialButton(
                onPressed: onEdit,
                splashColor: Colors.transparent,
                enableFeedback: false,
                child: const Icon(Icons.edit),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 32,
                child: MaterialButton(
                  onPressed: onDelete,
                  splashColor: Colors.transparent,
                  enableFeedback: false,
                  child: const Icon(Icons.delete),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
