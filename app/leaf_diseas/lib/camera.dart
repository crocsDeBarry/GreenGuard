import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Import MediaType
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'homepage.dart';
import 'diseases.dart';
import 'map.dart';
import 'historique.dart';
import 'package:intl/intl.dart';


class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _selectedImage;
  int _selectedIndex = 2;

  Future<void> _pickImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    // Send the image to the server
    _sendImageToServer(pickedFile.path);
  }

Future<void> _pickImageFromCamera() async {
  final pickedFile = await ImagePicker().pickImage(
    source: ImageSource.camera,
    imageQuality: 80, // Définissez la qualité de l'image entre 0 et 100
    maxWidth: 800, // Définissez la largeur maximale de l'image
    maxHeight: 600, // Définissez la hauteur maximale de l'image
  );

  if (pickedFile == null) return;

  setState(() {
    _selectedImage = File(pickedFile.path);
  });

  // Envoyer l'image au serveur
  _sendImageToServer(pickedFile.path);
}

    Future<Position?> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return position;
    } catch (e) {
      print(e);
      return null;
    }
  }

Future<void> _sendImageToServer(String imagePath) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  if (token == null) {
    print("Token de session introuvable");
    return;
  }

  /*// Obtenir la géolocalisation actuelle
  Position? position = await _getCurrentLocation();
  if (position == null) {
    print("Impossible de récupérer la position");
    return;
  }*/

  DateTime now = DateTime.now(); // Obtenez la date actuelle
  String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now); // Formattez la date selon votre besoin
  
  http.MultipartRequest request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:5000/api/scan'));

  // Ajouter le token de session à l'en-tête de la requête
  request.headers['Authorization'] = 'Bearer $token';
  request.fields['date'] = formattedDate;
  
  /*// Ajouter la position en tant que paramètre dans le corps de la requête
  request.fields['latitude'] = position.latitude.toString();
  request.fields['longitude'] = position.longitude.toString();

  print(position.latitude.toString());*/
  
  request.files.add(
    await http.MultipartFile.fromPath(
      'images',
      File(imagePath).path,
      contentType: MediaType('application', 'jpeg'),
    ),
  );

  // Envoyer la requête
  http.StreamedResponse r = await request.send();
  print(r.statusCode);
  print(await r.stream.transform(utf8.decoder).join());
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.photo),
            onPressed: _pickImageFromGallery,
          ),
          _selectedImage != null ? Image.file(_selectedImage!) : Text("Select Image"),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickImageFromCamera,
              child: Text('Take a Photo'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: _pickImageFromGallery,
              child: Text('Select from Gallery'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'HomePage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Diseases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedIconTheme: IconThemeData(color: Colors.black),
        unselectedIconTheme: IconThemeData(color: Colors.black.withOpacity(0.6)),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black.withOpacity(0.6),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Page2()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CameraPage()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HistoriquePage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MapPage()),
      );
    }
  }
}