import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:brain_therapy/Pages/home.dart';
import 'package:brain_therapy/Launch Sign In/page1.dart';
import 'services/ai_services.dart'; // Changed from openai.dart to ai_services.dart
import 'utils/splash_screen.dart';
import 'services/api_keys.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print debug info for API configuration
  ApiKeys.printDebugInfo();

  // Initialize AI Service directly
  AIService.initialize();

  if (ApiKeys.isValidApiKey() && ApiKeys.isValidAssistantId()) {
    print('[Main] ✅ Valid API credentials');
  } else {
    print('[Main] ❌ Invalid API credentials');
    if (!ApiKeys.isValidApiKey()) {
      print('[Main] ❌ Invalid API key format');
    }
    if (!ApiKeys.isValidAssistantId()) {
      print('[Main] ❌ Invalid Assistant ID format');
    }
  }

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Therapy AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: SplashScreen(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasData) {
              // ✅ User is authenticated
              return const HomePage();
            }

            // 🚪 User not authenticated
            return const Page1();
          },
        ),
      ),
    );
  }
}
