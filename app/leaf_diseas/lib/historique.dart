import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart'; // Import Page1
import 'diseases.dart'; // Import Page2
import 'camera.dart'; // Import CameraPage
import 'map.dart'; // Import MapPage
 
class HistoriquePage extends StatefulWidget {
  @override
  _HistoriquePageState createState() => _HistoriquePageState();
}
 
class _HistoriquePageState extends State<HistoriquePage> {
  List<dynamic> historique = [];
  int _selectedIndex = 3;
 
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (_selectedIndex == 1) {
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
      }
    });
  }
 
  @override
  void initState() {
    super.initState();
    fetchData();
  }
 
  Future<void> fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
 
    var headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
 
    var response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/historique'),
      headers: headers,
    );
 
    if (response.statusCode == 200) {
      setState(() {
        historique = json.decode(response.body)['message'];
        // Tri des éléments de l'historique du plus récent au plus ancien
        historique.sort((a, b) => b['date_scan'].compareTo(a['date_scan']));
      });
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Historique des scans'),
      ),
      body: historique.isEmpty
          ? Center(child: Text('Aucune donnée d\'historique'))
          : ListView.builder(
              itemCount: historique.length,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text('Diagnostic : ${historique[index]['name']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Utiliser DateFormat pour formater la date
                          Text('${(historique[index]['date_scan'])}'),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImage(
                                    imageUrl: 'http://10.0.2.2:5000/image/${historique[index]['image']}',
                                  ),
                                ),
                              );
                            },
                            child: Image.network(
                              'http://10.0.2.2:5000/image/${historique[index]['image']}',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (historique[index]['cure'] != null)
                            GestureDetector(
                              onTap: () {
                                _showTreatmentPopup(
                                    context, historique[index]['cure']);
                              },
                              child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
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
                    ),
                    Divider(), // Ajouter un Divider entre chaque ListTile
                  ],
                );
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
        selectedIconTheme: IconThemeData(color: Colors.black),
        unselectedIconTheme: IconThemeData(color: Colors.black.withOpacity(0.6)),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black.withOpacity(0.6),
      ),
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
 
class FullScreenImage extends StatelessWidget {
  final String imageUrl;
 
  const FullScreenImage({required this.imageUrl});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
 