import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';


class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _verifyEmailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _verifyPasswordController = TextEditingController();
  bool _isPasswordObscured = true;


  register(TextEditingController firstNameController, TextEditingController lastNameController,
      TextEditingController emailController, TextEditingController passwordController, BuildContext context) async {
    var response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"Fname": firstNameController.text, "Lname": lastNameController.text, "email": emailController.text, "password": passwordController.text})
    );

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
      );
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
        title: Text('Inscription'),
      ),
      body: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Prénom',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Nom',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _verifyEmailController,
              decoration: InputDecoration(
                labelText: 'Vérification Email',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _isPasswordObscured,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
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
            ),
            SizedBox(height: 20),
            TextField(
              controller: _verifyPasswordController,
              obscureText: _isPasswordObscured,
              decoration: InputDecoration(
                labelText: 'Vérification Mot de passe',
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
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 25),
            
            child : ElevatedButton(
              onPressed: () {
                if (!_emailRegExp.hasMatch(_emailController.text)) {
                  _showErrorDialog('Email invalide',
                      'Saisir un email valide.');
                  return;
                }

                if (_emailController.text != _verifyEmailController.text) {
                  _showErrorDialog('Les emails ne correspondent pas',
                      'L\'email est différent de la vérification.');
                  return;
                }

                if (!_firstNameController.text.isNotEmpty ||
                    !_lastNameController.text.isNotEmpty ||
                    _firstNameController.text[0].toUpperCase() !=
                        _firstNameController.text[0] ||
                    _lastNameController.text[0].toUpperCase() !=
                        _lastNameController.text[0]) {
                  _showErrorDialog(
                      'Nom invalide',
                      'Mettre une majuscule au début du prénom et du nom.');
                  return;
                }

                if (!_passwordController.text.contains(RegExp(r'[A-Z]')) ||
                    !_passwordController.text.contains(RegExp(r'[a-z]')) ||
                    !_passwordController.text.contains(RegExp(r'[0-9]')) ||
                    _passwordController.text.length < 8) {
                  _showErrorDialog(
                      'Mot de passe invalide',
                      'Le mot de passe doit contenir au moins 8 caractères, '
                          'dont une majuscule, une minuscule et un chiffre.');
                  return;
                }

                if (_passwordController.text !=
                    _verifyPasswordController.text) {
                  _showErrorDialog('Les mots de passe ne correspondent pas',
                      'Le mot de passe est différent de la vérification.');
                  return;
                }

                register(_firstNameController, _lastNameController, _emailController,
                    _passwordController, context);

              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
              ),
                child: Text(
                  'S\'inscrire',
                  style: TextStyle(
                    fontSize: 18, // Augmentez la taille de la police
                  ),
                ),
               ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
