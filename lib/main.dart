// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';

// import 'services/firebase_service.dart';
// import 'services/auth_service.dart';
// import 'screens/splash_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/home_screen.dart';
// import 'utils/theme.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: _initializeApp(),
//       builder: (context, snapshot) {
//         // Show error screen if initialization failed
//         if (snapshot.hasError) {
//           return MaterialApp(
//             home: Scaffold(
//               body: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.error, size: 64, color: Colors.red),
//                     const SizedBox(height: 16),
//                     const Text('Initialization Error',
//                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 8),
//                     Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Text(snapshot.error.toString(),
//                           textAlign: TextAlign.center),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }

//         // Show loading while initializing
//         if (snapshot.connectionState != ConnectionState.done) {
//           return MaterialApp(
//             home: Scaffold(
//               body: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const CircularProgressIndicator(),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Initializing...',
//                       style: GoogleFonts.poppins(fontSize: 16),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }

//         // App is ready - show full app with providers
//         return MultiProvider(
//           providers: [
//             ChangeNotifierProvider(create: (_) => AuthService()),
//             ChangeNotifierProvider(create: (_) => FirebaseService()),
//           ],
//           child: MaterialApp(
//             title: 'Gas Detector',
//             debugShowCheckedModeBanner: false,
//             theme: AppTheme.lightTheme,
//             darkTheme: AppTheme.darkTheme,
//             themeMode: ThemeMode.system,
//             home: const SplashScreen(),
//             routes: {
//               '/login': (context) => const LoginScreen(),
//               '/home': (context) => const HomeScreen(),
//             },
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _initializeApp() async {
//     // Initialize Firebase
//     await Firebase.initializeApp(
//       options: const FirebaseOptions(
//         // apiKey: 'YOUR_API_KEY',
//         // appId: 'YOUR_APP_ID',
//         // messagingSenderId: 'YOUR_SENDER_ID',
//         // projectId: 'gas-detection-system-30cc0',
//         // authDomain: 'gas-detection-system-30cc0.firebaseapp.com',
//         // databaseURL: 'https://gas-detection-system-30cc0-default-rtdb.firebaseio.com',
//         // storageBucket: 'gas-detection-system-30cc0.appspot.com',
//         apiKey: "AIzaSyBtgTQXfpFFU75d7sKxA80G4fp8zUa6bP0",
//         authDomain: "gas-detection-system-30cc0.firebaseapp.com",
//         databaseURL: "https://gas-detection-system-30cc0-default-rtdb.firebaseio.com",
//         projectId: "gas-detection-system-30cc0",
//         storageBucket: "gas-detection-system-30cc0.firebasestorage.app",
//         messagingSenderId: "27532992082",
//         appId: "1:27532992082:web:956f0bdc056e842d6e098b",
//         measurementId: "G-B9SPVKFS57"
//       ),
//     );

//     // Give it a moment to settle
//     await Future.delayed(const Duration(milliseconds: 500));
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
// Kept as you had it
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ ADDED THIS

import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

Future<void> main() async {
  // 1. Initialize Bindings (Required for async code)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load Environment Variables with Error Handling
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ Warning: .env file not found or empty. Using defaults.");
  }

  // 3. Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("❌ Firebase Initialization Error: $e");
  }

  // 4. ✅ ANDROID 14 FIX: Request Permissions on Start
  // This prevents the "App has a bug" crash when services start early
  await requestAndroid14Permissions();

  runApp(const MyApp());
}

/// Helper function to handle Android 13/14 runtime permissions
Future<void> requestAndroid14Permissions() async {
  // We request Notification (for alerts) and Camera (for QR Scanner)
  // The 'await' ensures we don't start the UI until we at least try to ask.
  Map<Permission, PermissionStatus> statuses = await [
    Permission.notification,
    Permission.camera,
    // Note: 'location' might be needed if you use WiFi scanning for ESP32
  ].request();

  if (statuses[Permission.notification]!.isDenied) {
    debugPrint("⚠️ User denied notifications. Gas alerts may not work!");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirebaseService()),
        // ✅ ADD THIS LINE:
        ChangeNotifierProvider(
            create: (_) => NotificationService()..initialize()),
      ],
      child: MaterialApp(
        title: 'Gas Detector',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        // The Splash Screen will handle the transition to Login/Home
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
