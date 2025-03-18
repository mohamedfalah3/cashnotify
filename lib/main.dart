import 'package:cashnotify/helper/dateTimeProvider.dart';
import 'package:cashnotify/helper/helper_class.dart';
import 'package:cashnotify/screens/loginScreen.dart';
import 'package:cashnotify/screens/sidebar_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'helper/placeDetailsHelper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyDO8ceWLzbsPvY0x312P3gHN737MDJtI2c",
        authDomain: "cashnotification-8ff9d.firebaseapp.com",
        projectId: "cashnotification-8ff9d",
        storageBucket: "cashnotification-8ff9d.firebasestorage.app",
        messagingSenderId: "522042836464",
        appId: "1:522042836464:web:3259e1f99657925f100935",
        measurementId: "G-T0ZQPYPK79"),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => DateTimeProvider()),
        ChangeNotifierProvider(create: (_) => PlaceDetailsHelper()),
      ],
      child: const MaterialApp(
        home: MyApp(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      home: const WowScreen(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.grey[200],
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          contentTextStyle: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class WowScreen extends StatelessWidget {
  const WowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens for auth state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          // If user is logged in, navigate to SidebarXExampleApp
          return SidebarXExampleApp();
        } else {
          // If user is not logged in, show login screen
          return const ResponsiveLoginScreen();
        }
      },
    );
  }
}
