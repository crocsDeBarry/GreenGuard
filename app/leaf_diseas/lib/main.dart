import 'package:flutter/material.dart';
import 'Login.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon Application Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Afficher l'écran de chargement au démarrage de l'application
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true; // Définir l'état du chargement

  @override
  void initState() {
    super.initState();
    // Simuler un chargement en utilisant un Future.delayed
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _isLoading = false; // Mettre à jour l'état du chargement une fois terminé
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Afficher le logo de chargement ou l'écran de connexion selon l'état du chargement
    return _isLoading ? LoadingScreen() : LoginPage();
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Afficher le logo pendant le chargement
            Image.asset('assets/logo.png'),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
