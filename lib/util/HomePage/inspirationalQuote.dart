import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'dart:math';
import 'package:mazilon/util/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

//Display a random Inspirational Quote
class InspirationalQuote extends StatefulWidget {
  final List<String> quotes;
  const InspirationalQuote({super.key, required this.quotes});
  @override
  _InspirationalQuoteState createState() => _InspirationalQuoteState();
}

class _InspirationalQuoteState extends LPExtendedState<InspirationalQuote> {
  bool showText = true;
  String quote = '';
  int number = 0;
  AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
  //Let the user close the window
  void setShow() {
    setState(() {
      showText = false;
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(appLocale.quoteDismissedMessage),
        action: SnackBarAction(
          label: appLocale.quoteUndoAction,
          onPressed: () {
            if (!mounted) {
              return;
            }
            setState(() {
              showText = true;
            });
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    //decide which quote to show
    if (widget.quotes.isNotEmpty) {
      number = Random().nextInt(widget.quotes.length);
    }
  }

  @override
  void didUpdateWidget(InspirationalQuote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quotes.isEmpty) {
      number = 0;
      return;
    }
    if (oldWidget.quotes != widget.quotes || number >= widget.quotes.length) {
      number = Random().nextInt(widget.quotes.length);
    }
  }

  void _refreshQuote() {
    if (widget.quotes.isEmpty) {
      return;
    }
    setState(() {
      final prevNumber = number;
      number = Random().nextInt(widget.quotes.length);
      mixPanelService.trackEvent("Inspirational Quotes Refreshed", {
        "Old Quote": widget.quotes[prevNumber],
        "New Quote": widget.quotes[number],
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quotes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          appLocale.quotesUnavailableMessage,
          textAlign: TextAlign.start,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 12.sp,
            fontWeight: FontWeight.normal,
          ),
        ),
      );
    }
    return Visibility(
      visible: showText,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.primary,
        ),
        width: MediaQuery.of(context).size.width > 1000
            ? 800
            : MediaQuery.of(context).size.width,
        constraints: const BoxConstraints(minHeight: 120),
        child: Stack(
          children: [
            PositionedDirectional(
              top: 5,
              end: 5,
              // Tooltip owns the announced label; Semantics only adds the
              // `button` role so GestureDetector doesn't read as plain text.
              child: Semantics(
                button: true,
                child: GestureDetector(
                  onTap: setShow,
                  child: Tooltip(
                    message: appLocale.dismissQuoteTooltip,
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(4, 4, 0, 4),
                      child: Icon(Icons.close),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: min(35.sp, 40),
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    tooltip: appLocale.refreshQuoteTooltip,
                    //"refresh" button to change the quote
                    onPressed: _refreshQuote,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        0,
                        0,
                        30,
                        0,
                      ),
                      child: myAutoSizedText(
                        widget.quotes[number],
                        TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 24.sp,
                        ),
                        TextAlign.start,
                        24,
                        4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
