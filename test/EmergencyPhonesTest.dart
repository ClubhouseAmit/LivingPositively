import 'package:flutter/material.dart';

// Mock data for testing
Map<String, List<String>> mockPhonePageTitles = {
  'emergencyPhones': ['123', '456', '789'],
  'phoneName': ['Police', 'Fire Station', 'Hospital'],
  'phoneDescription': [
    'Call for law enforcement',
    'Call in case of fire',
    'Call for medical emergencies'
  ]
};

// Simplified EmergencyDialogBox for testing
class EmergencyDialogBox extends StatelessWidget {
  const EmergencyDialogBox({required this.number, super.key});
  final String number;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Emergency Number'),
      content: Text('Call $number'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Simplified EmergencyPhonesRow for testing
class EmergencyPhonesRow extends StatelessWidget {
  const EmergencyPhonesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < mockPhonePageTitles['emergencyPhones']!.length; i++)
          Flexible(
            child: InkWell(
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (context) {
                    return EmergencyDialogBox(
                        number: mockPhonePageTitles['emergencyPhones']![i]);
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purple),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mockPhonePageTitles['phoneName']![i],
                              style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                            Text(
                              mockPhonePageTitles['phoneDescription']![i],
                              style:
                                  const TextStyle(color: Colors.purple, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-30, -10),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.purple),
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
