import 'package:flutter/material.dart';
import 'player.dart';

class WellnessTools extends StatefulWidget {
  final Function setBool;
  final bool isFullScreen;
  final Map<String, List<String>> videoData;
  const WellnessTools({
    super.key,
    required this.isFullScreen,
    required this.setBool,
    required this.videoData,
  });

  @override
  State<WellnessTools> createState() => _WellnessToolsState();
}

class _WellnessToolsState extends State<WellnessTools> {
  var isFullScreen = false;
  var selectedVideoId = 0;

  String getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }

  void setIsFullScreen(bool isFullScreen) {
    setState(() {
      this.isFullScreen = isFullScreen;
    });
    widget.setBool(isFullScreen);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Visibility(
              visible: !isFullScreen,
              child: Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'מצילון',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: Image.asset(
                        'assets/images/Logo.png',
                        width: MediaQuery.sizeOf(context).width * 0.4 > 1000
                            ? 500
                            : MediaQuery.sizeOf(context).width *
                                  0.2, // Adjust as needed
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: !isFullScreen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 10.0, 8, 10),
                child: Text(
                  widget.videoData['videoHeadline']![selectedVideoId],
                ),
              ),
            ),
            YoutubePlayerPage(
              controller: selectedVideoId,
              setBool: setIsFullScreen,
            ),
            SizedBox(height: 10),
            Visibility(
              visible: !isFullScreen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4.0, 4, 20),
                child: Text(
                  widget.videoData['videoDescription']![selectedVideoId],
                ),
              ),
            ),
            Visibility(
              visible: !isFullScreen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4.0, 4, 20),
                child: Text(':סרטונים נוספים'),
              ),
            ),
            Visibility(
              visible: true,
              child: Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    if (index == selectedVideoId) {
                      return Container();
                    }

                    return SizedBox(
                      key: Key("tap$index"),
                      width: 150,
                      height: 100,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedVideoId = index;
                          });
                        },
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.asset('assets/images/Logo.png'),
                        ),
                      ),
                    );
                  },
                  itemCount: widget.videoData['videoId']!.length,
                  separatorBuilder: (context, _) =>
                      const SizedBox(height: 10.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
