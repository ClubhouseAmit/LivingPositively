import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//the page before the personal plan questionnaire that allows the user to fill the questionnaire or skip it.
class ToFormPage extends StatefulWidget {
  const ToFormPage({
    required this.phonePageData,
    required this.changeLocale,
    super.key,
  });
  final PhonePageData phonePageData;
  final Function changeLocale;

  @override
  State<ToFormPage> createState() => _ToFormPageState();
}

class _ToFormPageState extends LPExtendedState<ToFormPage> {
  bool hasFilled = false;
  bool _whyPrepareExpanded = false;

  Future<void> getHasFilled() async {
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    final hasFilledValue =
        await service.getItem(
              'hasFilled',
              PersistentMemoryType.Bool,
            )
            as bool?;

    setState(() {
      hasFilled = hasFilledValue ?? false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getHasFilled();
  }

  Widget _buildAccordionCard({
    required BuildContext context,
    required String title,
    required String content,
    required bool isExpanded,
    required VoidCallback onTap,
    Widget? child,
  }) {
    const cardBgColor = Color(0xFFFDFBF7);
    const darkSlateColor = Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: darkSlateColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: darkSlateColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: darkSlateColor.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                    ),
                    if (child != null) ...[
                      const SizedBox(height: 16),
                      child,
                    ],
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);
    final gender = userInfoProvider.gender;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Semantics(
            header: true,
            child: AutoSizeText(
              appLocale.introductionFormLastPageMainTitle(gender),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocale.introductionFormLastPageSubTitle1Line1(gender),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appLocale.introductionFormLastPageSubTitle1Line2(gender),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 220,
                    maxHeight: 220,
                  ),
                  child: Image.asset('assets/images/initialFormPage3.png'),
                ),
              ),
            ],
          ),
          _buildAccordionCard(
            context: context,
            title: appLocale.introductionFormLastPageAccordion2Header(gender),
            content: appLocale.introductionFormLastPageSubTitle2(gender),
            isExpanded: _whyPrepareExpanded,
            onTap: () {
              setState(() {
                _whyPrepareExpanded = !_whyPrepareExpanded;
              });
            },
          ),
          const SizedBox(height: Spacing.xl),
          //navigate to personal plan form button:
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder<void>(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      FormProgressIndicator(
                        phonePageData: widget.phonePageData,
                        changeLocale: widget.changeLocale,
                      ), //place collections here
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(-1, 0);
                        const end = Offset.zero;
                        final tween = Tween(begin: begin, end: end);
                        final offsetAnimation = animation.drive(tween);

                        final fadeTween = Tween<double>(begin: 0, end: 1);
                        final fadeAnimation = animation.drive(fadeTween);

                        return SlideTransition(
                          position: offsetAnimation,
                          child: FadeTransition(
                            opacity: fadeAnimation,
                            child: child,
                          ),
                        );
                      },
                ),
              );
            },
            child: Text(appLocale.introductionFormLastPageNext(gender)),
          ),
          const SizedBox(height: Spacing.lg),
          OutlinedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => Menu(
                    phonePageData: widget.phonePageData,
                    hasFilled: hasFilled,
                    changeLocale: widget.changeLocale,
                  ),
                ),
                (route) => false,
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl,
                vertical: Spacing.md,
              ),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: Text(appLocale.skipButton(gender)),
          ),
        ],
      ),
    );
  }
}
