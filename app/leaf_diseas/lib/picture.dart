import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'homepage.dart';
import 'diseases.dart';
import 'camera.dart';
import 'package:path_provider/path_provider.dart';

class PicturePage extends StatelessWidget {
  final String imagePath;

  PicturePage({required this.imagePath});

  Future<void> _saveImageToDevice(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(imagePath);
      final newImagePath = '${directory.path}/saved_image.jpg';
      await file.copy(newImagePath);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Image saved to device'),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      print('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save image'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;

    return Scaffold(
      appBar: AppBar(
        title: Text('Picture'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isWeb
                ? Image.network(imagePath)
                : Image.file(File(imagePath)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()), // Assuming Page1 is the name of your Page 1 class
                );
              },
              child: Text('Go to Page 1'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Page2()),
                );
              },
              child: Text('Go to Page 2'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraPage()),
                );
              },
              child: Text('Go to Camera'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveImageToDevice(context);
              },
              child: Text('Save Image to Device'),
            ),
          ],
        ),
      ),
    );
  }
}
