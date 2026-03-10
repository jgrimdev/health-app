import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // NOVÝ IMPORT
import 'firebase_options.dart';                    // NOVÝ IMPORT (tvůj vygenerovaný soubor)

import 'services/background_service.dart';
import 'screens/main_navigation.dart';

void main() async {
  // Zajištění, že se vše načte před startem
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 START FIREBASE MOTORU 🔥
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await inicializovatPozadi(); // Spustí náš senzor kroků
  runApp(const MujKrokomerApp()); // Spustí UI
}

class MujKrokomerApp extends StatelessWidget {
  const MujKrokomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biohack Krokoměr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.greenAccent, 
          brightness: Brightness.dark
        ),
      ),
      home: const HlavniNavigace(),
    );
  }
}