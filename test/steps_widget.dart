import 'package:flutter/material.dart';

class StepsWidget extends StatefulWidget {
  const StepsWidget({super.key});

  @override
  _StepsWidgetState createState() => _StepsWidgetState();
}

class _StepsWidgetState extends State<StepsWidget> {
  int currentStep = 0;
  final List<Step> steps = [
    const Step(title: Text('Step 0'), content: Text('This is the first step.')),
    const Step(title: Text('Step 1'), content: Text('This is the second step.')),
    const Step(title: Text('Step 2'), content: Text('This is the third step.')),
  ];

  void next() {
    setState(() {
      if (currentStep < steps.length - 1) currentStep++;
    });
  }

  void skip() {
    setState(() {
      currentStep = steps.length - 1;
      //if (currentStep < steps.length - 1) currentStep++;
      //## this is the part that skips the initial form.##//
    });
  }

  void prev() {
    setState(() {
      if (currentStep > 0) currentStep--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Your Widget')),
        body: Column(
          children: [
            Text('Step $currentStep'),
            ElevatedButton(
              key: const Key('Next'),
              onPressed: next,
              child: const Text('Next'),
            ),
            ElevatedButton(
              key: const Key('Prev'),
              onPressed: prev,
              child: const Text('Prev'),
            ),
            ElevatedButton(
              key: const Key('Skip'),
              onPressed: skip,
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}
