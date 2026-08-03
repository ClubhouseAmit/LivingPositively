import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/thankYou.dart';

import 'package:mazilon/util/userInformation.dart';

import 'package:mazilon/util/theme/app_theme.dart';

import '../helpers/widget_test_scaffold.dart';

class _RebindingThankYouHost extends StatefulWidget {
  const _RebindingThankYouHost({super.key});

  @override
  State<_RebindingThankYouHost> createState() => _RebindingThankYouHostState();
}

class _RebindingThankYouHostState extends State<_RebindingThankYouHost> {
  final focusNode = FocusNode();
  int number = 1;
  int? removedIndex;

  void rebindAsSecondRow() {
    setState(() {
      number = 2;
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThankYou(
        key: const ValueKey('rebindable-thank-you-row'),
        text: 'Stable entry',
        number: number,
        edit: (String text, int index) {},
        remove: (int index) {
          removedIndex = index;
        },
        myFocusNode: focusNode,
        date: '',
        color: AppColors.primary,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices();
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
  });

  tearDown(resetTestServices);

  testWidgets('delete confirmation uses the row index from tap time', (
    tester,
  ) async {
    final hostKey = GlobalKey<_RebindingThankYouHostState>();

    await pumpWithProviders(
      tester,
      _RebindingThankYouHost(key: hostKey),
      userInformation: user,
      surfaceSize: const Size(1024, 800),
    );

    final deleteButton = find
        .ancestor(
          of: find.byIcon(Icons.delete),
          matching: find.byType(MaterialButton),
        )
        .first;
    await tester.tap(deleteButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    hostKey.currentState!.rebindAsSecondRow();
    await tester.pump();

    await tester.tap(find.text('Delete'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(hostKey.currentState!.removedIndex, 0);
  });
}
