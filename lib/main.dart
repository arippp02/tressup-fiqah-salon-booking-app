import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'auth_gate.dart'; // ✅ Import AuthGate
import 'notification_service.dart';

void main() async {
  // --- CHECKPOINT 1 ---
  WidgetsFlutterBinding.ensureInitialized();
  print("✅ Step 1: Widgets Binding Initialized");

  // Load Environment Variables
  try {
    await dotenv.load(fileName: ".env");
    print("✅ Step 1.5: DotEnv Loaded");
  } catch (e) {
    print("⚠️ DotEnv Warning: $e");
  }

  // --- CHECKPOINT 2 ---
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Step 2: Firebase App Initialized");
  } catch (e) {
    print("❌ Step 2 FAILED: Firebase Init Error: $e");
  }

  // --- CHECKPOINT 3 ---
  try {
    await NotificationService.init();
    print("✅ Step 3: Notification Service Initialized");
  } catch (e) {
    print("❌ Step 3 FAILED: Notification Service Error: $e");
  }

  // --- CHECKPOINT 4 ---
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  print("✅ Step 4: Background Handler Set");

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const FiqahBeautyApp(),
    ),
  );
  print("✅ Step 5: App Running");
}

class FiqahBeautyApp extends StatelessWidget {
  const FiqahBeautyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Fiqah Beauty & Salon",

      // ✅ Theme Configuration
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF6D4C41), // figmaBrown1
        scaffoldBackgroundColor: const Color(0xFFFDF6F0), // figmaNudeBG
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D4C41),
          background: const Color(0xFFFDF6F0),
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,

      // ✅ CHANGE: Use AuthGate instead of LoginPage
      home: const AuthGate(),
    );
  }
}
