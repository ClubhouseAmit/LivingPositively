import 'package:flutter/material.dart';

class SimplifiedFeelGood extends StatefulWidget {
  const SimplifiedFeelGood({super.key});

  @override
  _SimplifiedFeelGoodState createState() => _SimplifiedFeelGoodState();
}

class _SimplifiedFeelGoodState extends State<SimplifiedFeelGood> {
  List<String> imagePaths = [];

  void addMockImage() {
    setState(() {
      imagePaths.add('mock_image_path');
    });
  }

  void removeImage(int index) {
    setState(() {
      imagePaths.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simplified FeelGood')),
      body: Column(
        children: [
          ElevatedButton(
            key: Key('addImageButton'),
            onPressed: addMockImage,
            child: Text('Add Image'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Image $index'),
                  trailing: IconButton(
                    key: Key('removeImage_$index'),
                    icon: Icon(Icons.delete),
                    onPressed: () => removeImage(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
