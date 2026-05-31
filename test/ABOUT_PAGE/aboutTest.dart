import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    // final appInfoProvider = Provider.of<AppInformation>(context, listen: true);
    return MaterialApp(
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(200.0),
          child: Container(
            color: Colors.white,
            height: 200.0,
            child: Image.asset(
              key: Key('MatzilonLogo'),
              'assets/images/Logo.jpeg',
              width: MediaQuery.of(context).size.width * 0.8 > 1000
                  ? 500
                  : MediaQuery.of(context).size.width * 0.8, // Adjust as needed
              height:
                  MediaQuery.of(context).size.height * 0.4, // Adjust as needed
            ),
          ),
        ),
        body: Scrollbar(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('title1'),
                  SizedBox(height: 5),
                  Text('text1'),
                  Text('title2'),
                  SizedBox(height: 5),
                  Text('text2'),
                  SizedBox(
                    height: 20,
                  ), // Adds space between the text and the image
                  Image.asset(
                    key: Key('aboutPageSocialHubLogo'),
                    'assets/images/SocialHub-Logo.png',
                    width:
                        MediaQuery.of(context).size.width *
                        0.8, // Adjust as needed
                    // Optional: if you want to specify the height
                    // height: MediaQuery.of(context).size.height * 0.2, // Adjust as needed
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
