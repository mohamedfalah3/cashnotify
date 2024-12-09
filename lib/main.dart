import 'package:cashnotify/sidebar_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyDO8ceWLzbsPvY0x312P3gHN737MDJtI2c",
        authDomain: "cashnotification-8ff9d.firebaseapp.com",
        projectId: "cashnotification-8ff9d",
        storageBucket: "cashnotification-8ff9d.firebasestorage.app",
        messagingSenderId: "522042836464",
        appId: "1:522042836464:web:3259e1f99657925f100935",
        measurementId: "G-T0ZQPYPK79"),
  );

  runApp(
    MaterialApp(
      home: SidebarXExampleApp(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
