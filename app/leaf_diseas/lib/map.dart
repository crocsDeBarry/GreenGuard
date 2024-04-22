import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'homepage.dart';
import 'diseases.dart';
import 'camera.dart';
import 'historique.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = Location();
  LatLng _centerPosition = LatLng(0.0, 0.0);
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  LatLng? _currentP;
  int _selectedIndex = 2;
  List<String> filterOptions = []; // List to store disease names
  Timer? _debounce;

  // Disease Name
  List<String> _names = [];
  List<String> _selectedFilters = [];
  Set<Marker> _markers = {}; // Set to store markers

  Future<void> getDiseaseNames() async {
    var response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/diseases_names'),
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      List<dynamic> names = responseData['disease_names']; // Assuming the response key is 'disease_names'
      setState(() {
        _names = List<String>.from(names);
      });
    } else {
      print('Failed to fetch disease names: ${response.statusCode}');
    }
  }

  bool? isChecked = false;

  void dispose() {
  // Cancel the timer when the widget is disposed
  _debounce?.cancel();
  super.dispose();
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
      } else if (_selectedIndex == 1) {
        // Navigate to MapPage if the "Map" item is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Page2()),
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
  void initState() {
    super.initState();
    getLocationUpdates();
    getDiseaseNames();
  }

  void _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(target: pos, zoom: 13);
    await controller.animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition));
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _centerPosition = position.target;
    });
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(seconds: 1), () {
    _applyFilters();
    });
  }
  

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    }

    if (!_serviceEnabled) {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
    }

    if (_permissionGranted != PermissionStatus.granted) {
      return;
    }

    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentP = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
      }
    });
  }

  void _showFilterOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Options',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.0),
                  // Generate checkboxes dynamically from _names list
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _names.length,
                    itemBuilder: (BuildContext context, int index) {
                      return CheckboxListTile(
                        title: Text(_names[index]),
                        value: _selectedFilters.contains(_names[index]),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null) {
                              if (value) {
                                _selectedFilters.add(_names[index]);
                              } else {
                                _selectedFilters.remove(_names[index]);
                              }
                            }
                          });
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: Text('Apply Filters'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },

  );
}

  Future<void> getCoordinatesInRadius(double latitude, double longitude, List<String> selectedDiseases) async {
    // Prepare the request body
    Map<String, dynamic> requestBody = {
      'latitude': latitude,
      'longitude': longitude,
      'disease_list': selectedDiseases,
    };

    var response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/get_locations'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      // Handle the response here
      var responseData = json.decode(response.body);
      List<dynamic> coordinates = responseData['coordinates'];
      

      Set<Marker> markers = {}; // Create a new set to hold markers
      
      // Loop through coordinates and create marker objects
      for (var coord in coordinates) {
        markers.add(
          Marker(
            markerId: MarkerId("Latitude: ${coord[0]}, Longitude: ${coord[1]}"),
            position: LatLng(coord[0], coord[1]),
            // You can customize the marker icon if needed
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            // Add other properties as needed
          ),
        );
      }

      setState(() {
        _markers = markers; // Update _markers to trigger a rebuild of the map widget
      });
    } else {
      print('Failed to get coordinates: ${response.statusCode}');
    }
  }


  void _applyFilters() {
    getCoordinatesInRadius(_centerPosition.latitude, _centerPosition.longitude, _selectedFilters);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            initialCameraPosition: _currentP != null
              ? CameraPosition(
                  target: _currentP!,
                  zoom: 13,
                )
              : CameraPosition(
                  target: LatLng(50.6295, 3.0619), 
                  zoom: 13, 
                ),
            markers: _markers,
            onCameraMove: _onCameraMove,

          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: IconButton(
              onPressed: _currentP == null ? null : () => _cameraToPosition(_currentP!),
              icon: Icon(Icons.my_location),
              tooltip: 'Go to My Location',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showFilterOptions(context);
        },
        tooltip: 'Filter',
        child: Icon(Icons.filter_list),
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
}
