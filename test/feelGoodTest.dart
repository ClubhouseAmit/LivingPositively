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
      appBar: AppBar(title: const Text('Simplified FeelGood')),
      body: Column(
        children: [
          ElevatedButton(
            key: const Key('addImageButton'),
            onPressed: addMockImage,
            child: const Text('Add Image'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Image $index'),
                  trailing: IconButton(
                    key: Key('removeImage_$index'),
                    icon: const Icon(Icons.delete),
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
