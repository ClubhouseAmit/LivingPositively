import 'package:flutter/material.dart';

class StepsWidget extends StatefulWidget {
  const StepsWidget({super.key});

  @override
  _StepsWidgetState createState() => _StepsWidgetState();
}

class _StepsWidgetState extends State<StepsWidget> {
  int currentStep = 0;
  final List<Step> steps = [
    Step(title: Text('Step 0'), content: Text('This is the first step.')),
    Step(title: Text('Step 1'), content: Text('This is the second step.')),
    Step(title: Text('Step 2'), content: Text('This is the third step.')),
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
        appBar: AppBar(title: Text('Your Widget')),
        body: Column(
          children: [
            Text('Step $currentStep'),
            ElevatedButton(
              key: Key('Next'),
              onPressed: next,
              child: Text('Next'),
            ),
            ElevatedButton(
              key: Key('Prev'),
              onPressed: prev,
              child: Text('Prev'),
            ),
            ElevatedButton(
              key: Key('Skip'),
              onPressed: skip,
              child: Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}
