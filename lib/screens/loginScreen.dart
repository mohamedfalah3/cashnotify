import 'package:firebase_auth/firebase_auth.dart'; // Add Firebase Auth for login
import 'package:flutter/material.dart';

class ResponsiveLoginScreen extends StatefulWidget {
  const ResponsiveLoginScreen({Key? key}) : super(key: key);

  @override
  _ResponsiveLoginScreenState createState() => _ResponsiveLoginScreenState();
}

class _ResponsiveLoginScreenState extends State<ResponsiveLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String errorMessage = '';

  // Dummy Firebase Authentication logic
  Future<void> _login() async {
    try {
      print(_emailController.text + '@gmail.com');
      print(_passwordController.text);

      // Firebase login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text + '@gmail.com',
        password: _passwordController.text,
      );

      // If successful, navigate to another screen or show a success message
      // Example: Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        errorMessage = 'Invalid email or password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine if the screen is wide enough for a desktop layout
            bool isWide = constraints.maxWidth > 800;

            return SingleChildScrollView(
              child: Container(
                width: isWide ? 600 : constraints.maxWidth * 0.9,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo or Header
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: isWide ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email TextField
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon:
                            const Icon(Icons.email, color: Colors.deepPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password TextField
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon:
                            const Icon(Icons.lock, color: Colors.deepPurple),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error Message Display
                    if (errorMessage.isNotEmpty)
                      Text(
                        errorMessage,
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 10),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _login,
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
