import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Show a loading screen immediately so we know Flutter started
  runApp(const LoadingApp());

  try {
    // 2. Try to connect to Firebase with a 5-second limit
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));

    // 3. If connected, run the Map
    runApp(const MyApp());
    
  } catch (e) {
    // 4. If it hangs or crashes, force the Error Screen
    runApp(ErrorApp(message: "Startup Error: $e"));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resistance Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB71C1C)),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

// Temporary Loading Screen
class LoadingApp extends StatelessWidget {
  const LoadingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 20),
              Text("Connecting to Resistance...", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// Startup Error Screen
class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  const Text("CONNECTION FAILED", style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SelectableText(message, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}