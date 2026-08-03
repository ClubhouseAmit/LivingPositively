import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    // final appInfoProvider = Provider.of<AppInformation>(context, listen: true);
    return MaterialApp(
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: Container(
            color: Colors.white,
            height: 200,
            child: Image.asset(
              key: const Key('MatzilonLogo'),
              'assets/images/Logo.jpeg',
              width: 500, // Adjust as needed
              height: 600 * 0.4, // Adjust as needed
            ),
          ),
        ),
        body: Scrollbar(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
       const            Text(itle1'),
                  SizedBox(height: 5),
                  Text('text1'),
                  Text('title2'),
                  SizedBox(height: 5),
                  Text('text2'),
                  SizedBox(
   height: 20,
          ), // Adds space between const the text and the image
                  Image.asset(
                    key: Key('aboutPageSocialHubLogo'),
                    'assets/images/SocialHub-Logo.png',
                    width: 800 * 0.8, // Adjust as needed
                    // Optional: if you want to specify the height
                    // height: 600 * 0.2, // Adjust as needed
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
