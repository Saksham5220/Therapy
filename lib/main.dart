import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:therapy_ai/Pages/home.dart';
import 'package:therapy_ai/Launch Sign In/page1.dart';
import 'services/openai.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Clear any old OpenAI credentials
  await OpenAIStorage.clearCredentials();

  // Get OpenAI API credentials
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  final assistantId = dotenv.env['OPENAI_ASSISTANT_ID'];

  print('[Main] API Key from .env: ${apiKey?.substring(0, 20)}...');

  if (apiKey != null && apiKey.startsWith('sk-proj-') && apiKey.length > 50) {
    await OpenAIStorage.saveCredentials(
      apiKey: apiKey,
      assistantId: assistantId ?? '',
    );
    print('[Main] ✅ Credentials saved to SharedPreferences');
  } else {
    print('[Main] ❌ Invalid API key format');
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Therapy AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: StreamBuilder<User?>(
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
    );
  }
}
