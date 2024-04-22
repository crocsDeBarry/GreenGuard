import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'camera.dart'; // Import CameraPage
import 'homepage.dart'; // Import Page1
import 'historique.dart'; // Import HistoriquePage
import 'map.dart'; //Import MapPage

class Page2 extends StatefulWidget {
  @override
  _Page2State createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  int _selectedIndex = 1;
  List<dynamic> diseasesList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    print("Je rentre dans la page affichage des maladies");

    var headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    var response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/diseases'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      setState(() {
        diseasesList = json.decode(response.body)['data'];
      });
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 0) {
        // Navigate to HomePage if the "HomePage" item is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
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

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: Text('Maladies'),
    ),
    body: ListView.builder(
        itemCount: diseasesList.length,
        itemBuilder: (BuildContext context, int index) {
          // Vérifiez si c'est le premier élément de la liste ou si la section de maladie a changé
          if (index == 0 || diseasesList[index]['plant'] != diseasesList[index - 1]['plant']) {
            // Si c'est le cas, affichez un diviseur et le nom de la nouvelle section
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(), // Diviseur entre les sections de maladies
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Plante: ${diseasesList[index]['plant']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20, // Taille du titre
                      ),
                    ),
                  ),
                ),
                _buildDiseaseTile(diseasesList[index]), // Afficher la tuile de maladie pour cet élément
              ],
            );
          } else {
            // Sinon, affichez simplement la tuile de maladie pour cet élément
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(), // Diviseur entre les maladies
                _buildDiseaseTile(diseasesList[index]), // Afficher la tuile de maladie pour cet élément
              ],
            );
          }
        },
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

void _showFullImage(BuildContext context, String imageUrl) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FullImagePage(imageUrl: imageUrl),
    ),
  );
}

Widget _buildDiseaseTile(Map<String, dynamic> disease) {
  return Column(
    children: [
      ListTile(
        title: Center(
          child: Text(
            disease['name'],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            _showFullImage(context, 'http://10.0.2.2:5000/image/${disease['image']}');
          },
          child: Image.network(
            'http://10.0.2.2:5000/image/${disease['image']}',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              disease['description'],
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                _showTreatmentPopup(context, disease['cure']);
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Traitement',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          // Afficher des détails supplémentaires ou effectuer une action lorsque l'utilisateur appuie sur la maladie
        },
      ),
      Divider(),
    ],
  );
}


void _showTreatmentPopup(BuildContext context, String cure) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Traitement'),
        content: Text(cure), // Afficher le traitement dans le contenu de la boîte de dialogue
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le pop-up lorsque le bouton est cliqué
            },
            child: Text('Fermer'),
          ),
        ],
      );
    },
  );
}
}

class FullImagePage extends StatelessWidget {
  final String imageUrl;

  FullImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Image'),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain, // Ajuster l'image pour s'adapter à la taille de l'écran
        ),
      ),
    );
  }
}
