import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
import 'diseases.dart';
import 'camera.dart';
import 'historique.dart';
import 'login.dart';
import 'map.dart';

class UserPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  UserPage({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _password = '';
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    var headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    var response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/showProfile'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      setState(() {
        _firstName = responseData['data']['Fname'];
        _lastName = responseData['data']['Lname'];
        _email = responseData['data']['email'];
        _password = responseData['data']['password'];
      });
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  void loggout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void navigateToModifyPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ModifyPage(        
        firstName: _firstName,
        lastName: _lastName,
        email: _email,
        password: _password,)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Page utilisateur'),
        ),
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
              title: Text('Nom'),
              subtitle: Text(_firstName),
            ),
            ListTile(
              title: Text('Prénom'),
              subtitle: Text(_lastName),
            ),
            ListTile(
              title: Text('Email'),
              subtitle: Text(_email),
            ),
            ListTile(
                title: Text('Mot de passe'),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isPasswordVisible ? _password : '*' * _password.length,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ],
                ),
            ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: navigateToModifyPage,
                child: Text('Modifier les informations'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HistoriquePage()),
                  );
                },
                child: Text('Historique'),
              ),
              ElevatedButton(
                onPressed: loggout,
                child: Text('Déconnexion'),
              ),
            ],
          ),
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
            onTap: (index) => _onItemTapped(context, index),
            selectedIconTheme: IconThemeData(color: Colors.black),
            unselectedIconTheme: IconThemeData(color: Colors.black.withOpacity(0.6)),
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black.withOpacity(0.6)),
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
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
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HistoriquePage()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MapPage()),
      );
    }
  }
}

class UserInfoField extends StatelessWidget {
  final String label;
  final String value;

  UserInfoField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }
}

class ModifyPage extends StatefulWidget {

  final String firstName;
  final String lastName;
  final String email;
  final String password;

  ModifyPage({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  @override
  _ModifyPageState createState() => _ModifyPageState();
}

class _ModifyPageState extends State<ModifyPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController(text: widget.password);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void modifyProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    var headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    var data = {
      'Fname': _firstNameController.text,
      'Lname': _lastNameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    var response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/modifyProfile'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      // Peut-être que vous souhaitez effectuer une action après la modification réussie.
      print(responseData);
      Navigator.pop(context);
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

    RegExp _emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    caseSensitive: false,
    multiLine: false,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier le profil'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (!_firstNameController.text.isNotEmpty ||
                    _firstNameController.text[0].toUpperCase() !=
                        _firstNameController.text[0]) {
                    return 'Please make sure first name start with a capital letter.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Prénom'),
                validator: (value) {
                  if (!_lastNameController.text.isNotEmpty ||
                    _lastNameController.text[0].toUpperCase() !=
                        _lastNameController.text[0]) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (!_emailRegExp.hasMatch(_emailController.text)) {
                    return 'Please enter a correct email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: _isPasswordObscured,
                decoration: InputDecoration(labelText: 'Mot de passe', 
                suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordObscured = !_isPasswordObscured;
                      });
                    },
                    icon: Icon(
                      _isPasswordObscured ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),),
                validator: (value) {
                  if (!_passwordController.text.contains(RegExp(r'[A-Z]')) ||
                    !_passwordController.text.contains(RegExp(r'[a-z]')) ||
                    !_passwordController.text.contains(RegExp(r'[0-9]')) ||
                    _passwordController.text.length < 8) {
                    return 'Password should have at least 1 uppercase letter, 1 lowercase letter, 1 number, and minimum length of 8 characters.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    modifyProfile();
                    Navigator.pop(context);
                  }
                },
                child: Text('Sauvegarder les modifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

