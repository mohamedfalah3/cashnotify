import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with username and password
  Future<User?> signIn(String username, String password) async {
    try {
      // Check if the username exists in Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (snapshot.docs.isEmpty) {
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'User not found');
      }

      // Sign in with email (using username as email)
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: '$username@gmail.com',
        password: password,
      );

      return userCredential.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
