import 'package:flutter/material.dart';
import 'view/home.dart'; // 📁 Import de la page Home
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uabhqvoajtkwpkahepyf.supabase.co', // URL Supabase
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVhYmhxdm9hanRrd3BrYWhlcHlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0NjA1NTcsImV4cCI6MjA2MDAzNjU1N30.x6c2GR1QSHCbm25M1tofOCikkjguhAhBnjB8aZumgXg', // clé API
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie App', // 🎬 Titre de l'application
      debugShowCheckedModeBanner: false, // ❌ Supprime le bandeau "DEBUG"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), // 🎨 Thème global
        useMaterial3: true,
      ),
      home: const HomePage(), // 🏠 Page d'accueil directe
    );
  }
}
