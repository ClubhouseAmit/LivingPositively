import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Update with the correct path
import 'package:mockito/mockito.dart';

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

class SimpleEmergencyDialogBox extends StatelessWidget {
  final String number;
  final Future<bool> Function(Uri url) canLaunchUrl;
  final Future<void> Function(Uri url) launchUrl;

  const SimpleEmergencyDialogBox({
    super.key,
    required this.number,
    required this.canLaunchUrl,
    required this.launchUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Emergency Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Call $number'),
            ),
            onTap: () async {
              final Uri url = Uri.parse('tel:$number');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                debugPrint('Could not launch $url');
              }
            },
          ),
          SizedBox(height: 10),
          GestureDetector(
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('WhatsApp $number'),
            ),
            onTap: () async {
              final Uri url = Uri.parse('https://wa.me/$number');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                debugPrint('Could not launch $url');
              }
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class EmergencyDialogBoxNoWhatsapp extends StatelessWidget {
  final String number;
  final Future<bool> Function(Uri url) canLaunchUrl;
  final Future<void> Function(Uri url) launchUrl;

  const EmergencyDialogBoxNoWhatsapp({
    super.key,
    required this.number,
    required this.canLaunchUrl,
    required this.launchUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Directionality(
        textDirection: TextDirection.rtl,
        child: Text('בחר/י:'),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text('חיוג'),
                GestureDetector(
                  child: CircleAvatar(
                    radius: 20, // adjust as needed
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.phone, size: 20), // adjust as needed
                  ),
                  onTap: () async {
                    final Uri url = Uri.parse('tel:$number');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      debugPrint('Could not launch $url');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('חזרה'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class EmergencyDialogBoxWithLink extends StatelessWidget {
  final String number;
  final Future<bool> Function(Uri url) canLaunchUrl;
  final Future<void> Function(Uri url) launchUrl;

  const EmergencyDialogBoxWithLink({
    super.key,
    required this.number,
    required this.canLaunchUrl,
    required this.launchUrl,
  });

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'בחר/י:',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => _launchURL('tel:$number'),
                  child: CircleAvatar(
                    radius: 20,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.phone, size: 20),
                  ),
                ),
                Text(
                  'חיוג',
                  style: TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
                ),
              ],
            ),
            SizedBox(height: 10), // Add some spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => _launchURL(
                    'https://govforms.gov.il/mw/forms/moked105@police.gov.il',
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.search, size: 20),
                  ),
                ),
                Text(
                  'קישור לאתר',
                  style: TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'חזרה',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
