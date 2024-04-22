import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:http_parser/http_parser.dart'; // Import MediaType
import 'user.dart'; // Import UserPage
import 'diseases.dart'; // Import Page2
import 'camera.dart'; // Import CameraPage
import 'historique.dart'; // Import HistoriquePage
import 'map.dart'; //Import
import 'package:intl/intl.dart';
 
class HomePage extends StatefulWidget {
  @override
  _Page1State createState() => _Page1State();
}
 
class LocationDataModel {
  final double latitude;
  final double longitude;
 
  LocationDataModel({required this.latitude, required this.longitude});
}
 
 
class _Page1State extends State<HomePage> {
  int _selectedIndex = 0;
  String? _selectedItem = 'Tomate'; // Par défaut, 'Tomate' est sélectionné
  File? _selectedImage;
 
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
 
  Future<LocationDataModel?> getCurrentLocation() async {
    Location location = Location();
 
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;
 
    // Vérifiez si le service de localisation est activé
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        // Si le service de localisation n'est pas activé, retournez null
        return null;
      }
    }
 
    // Vérifiez si l'autorisation de localisation a été accordée
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        // Si l'autorisation de localisation n'a pas été accordée, retournez null
        return null;
      }
    }
 
    // Obtenez la position actuelle
    _locationData = await location.getLocation();
    double latitude = _locationData.latitude!;
    double longitude = _locationData.longitude!;
 
    return LocationDataModel(latitude: latitude, longitude: longitude);
  }
 
 
 
Future<void> _sendImageToServer(String imagePath) async {
 
    // Afficher le popup de chargement
  showDialog(
    context: context,
    barrierDismissible: false, // Empêcher la fermeture du popup en cliquant à l'extérieur
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(), // Cercle de progression
            SizedBox(height: 20),
            Text("Analyse de la photo"), // Texte indiquant le chargement
          ],
        ),
      );
    },
  );
 
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
 
  if (token == null) {
    print("Token de session introuvable");
    Navigator.pop(context); // Fermer le popup de chargement
    return;
  }
 
  DateTime now = DateTime.now(); // Obtenez la date actuelle
  String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now); // Formattez la date selon votre besoin
 
  http.MultipartRequest request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:5000/api/scan'));
 
  // Ajouter le token de session à l'en-tête de la requête
  request.headers['Authorization'] = 'Bearer $token';
  request.fields['date'] = formattedDate;
 
  LocationDataModel? locationData = await getCurrentLocation();
  if (locationData != null) {
    double latitude = locationData.latitude;
    double longitude = locationData.longitude;
    print('Latitude: $latitude, Longitude: $longitude');
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
  } else {
    print('Impossible de récupérer la localisation');
  }
 
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
 
  // Fermer le popup de chargement une fois la réponse reçue
  Navigator.pop(context);
 
  Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HistoriquePage()),
        );
 
}
 
  @override
  void initState() {
    super.initState();
    // Appeler la fonction lors du chargement de la page
    fetchData();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Cette propriété empêche l'affichage de la flèche de retour
        title: Text('Green Guard'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserPage(
                  firstName: '',
                  lastName: '',
                  email: '',
                  password: '',
                )),
              );
            },
          ),
        ],
      ),
 
    body: Column(
      mainAxisAlignment: MainAxisAlignment.start, // Alignez les éléments en haut de la colonne
      children: [
        // Paragraphe d'explication de l'application
        Container(
          padding: EdgeInsets.only(top: 50, left: 20, right: 20),
          child: Text(
            "Choisissez le type de feuille, prenez une photo de votre plante et découvrez son état de santé !",
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 16),
          ),
        ),
        // Reste du contenu de la page
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Titre et choix entre tomate et pomme de terre
                Container(
                  padding: EdgeInsets.only(left: 15),
                  child: Text(
                    'Types de feuille disponibles :',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom:36),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Feuille de Tomate'),                        
                        value: 'Tomate',
                        groupValue: _selectedItem,
                        onChanged: (String? value) {
                          setState(() {
                            _selectedItem = value;
                          });
                        },
                      ),
                      /*RadioListTile<String>(
                        title: const Text('Feuille de Pomme de terre'),
                        value: 'Pomme de terre',
                        groupValue: _selectedItem,
                        onChanged: (String? value) {
                          setState(() {
                            _selectedItem = value;
                          });
                        },
                      ),*/
                    ],
                  ),
                ),
                // Boutons pour prendre une photo ou sélectionner dans la galerie
                Container(
                  padding: EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: _pickImageFromCamera,
                    child: Text('Prendre une Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom: 50),
                  child: TextButton(
                    onPressed: _pickImageFromGallery,
                    child: Text('Selectionner dans la Galerie'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
 
 
 
 
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Green Guard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Maladies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedIconTheme: IconThemeData(color: Colors.black), // Set icon color when selected
        unselectedIconTheme: IconThemeData(color: Colors.black.withOpacity(0.6)), // Set icon color when not selected
        selectedItemColor: Colors.black, // Set text color when selected
        unselectedItemColor: Colors.black.withOpacity(0.6), // Set text color when not selected
      ),
    );
  }
 
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 1) {
        // Navigate to Page2 if the "Page 2" item is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Page2()),
        );
      } else if (_selectedIndex == 2) {
        // Navigate to MapPage if the "Map" item is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapPage()),
        );
      } else if (_selectedIndex == 3) {
        // Navigate to HistoriquePage if the "Historique" item is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HistoriquePage()),
        );
      }
    });
  }
 
  void fetchData() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
 
    var headers = {
      'Content-Type': 'application/json',
      // Ajouter le token au header si disponible
      if (token != null) 'Authorization': 'Bearer $token',
    };
 
    var response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/homepage'),
      headers: headers
    );
 
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      print(responseData);
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }
}