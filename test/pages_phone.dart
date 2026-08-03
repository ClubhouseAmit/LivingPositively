import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';

import 'EmergencyPhonesTest.dart'; // Adjust the import path as necessary

class MockUrlLauncher extends Mock {
  Future<bool> canLaunchUrl(Uri url) => super.noSuchMethod(
    Invocation.method(#canLaunchUrl, [url]),
    returnValue: Future.value(true),
    returnValueForMissingStub: Future.value(false),
  );

  Future<void> launchUrl(Uri url) => super.noSuchMethod(
    Invocation.method(#launchUrl, [url]),
    returnValue: Future.value(),
    returnValueForMissingStub: Future.value(),
  );
}

class SimplifiedPhonePage extends StatelessWidget {

  const SimplifiedPhonePage({
    required this.phoneNumbers, required this.canLaunchUrl, required this.launchUrl, super.key,
  });
  final List<String> phoneNumbers;
  final Future<bool> Function(Uri url) canLaunchUrl;
  final Future<void> Function(Uri url) launchUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            ...phoneNumbers.map(
              (number) => InkWell(
                onTap: () async {
                  final url = Uri.parse('tel:$number');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    debugPrint('Could not launch $url');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Call $number',
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const EmergencyPhonesRow(), // Assuming this is a widget that displays emergency phone numbers
          ],
        ),
      ),
    );
  }
}
