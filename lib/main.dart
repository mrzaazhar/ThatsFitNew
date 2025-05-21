import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/homepage.dart';
import 'firebase_options.dart';
import 'signup_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login Page',
      theme: ThemeData(primarySwatch: Colors.green),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  // Define the controllers here
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    // Input validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    print('Attempting login with email: ${_emailController.text.trim()}');

    try {
      print('Calling Firebase Auth...');
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('Firebase Auth successful, user ID: ${userCredential.user?.uid}');

      // Check if user exists in Firestore
      print('Checking Firestore for user document...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        print('User document not found in Firestore');
        // If user doesn't exist in Firestore, show message and redirect to signup
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text('Account not found. Please sign up first.')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignUpPage()),
        );
      } else {
        print('User document found, navigating to home page');
        // Navigate to home page after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email. Please sign up first.';
        // Redirect to signup page if user doesn't exist
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignUpPage()),
        );
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your internet connection.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      print('General Exception during login: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text('An error occurred during login: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage(
              'assets/PNG/background.png',
            ), // Add your background image here
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Upper half for background image
            Expanded(
              flex: 1, // This takes half of the screen
              child: Container(),
            ),
            // Lower half for the card
            Expanded(
              flex: 0, // This takes the other half of the screen
              child: Container(
                margin: EdgeInsets.zero, // Remove any margin
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ), // Rounded top corners
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'aileron',
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(fontFamily: 'DM Sans'),
                            filled: true, // Enable fill color
                            fillColor: Color(0xFFE0E0E0), // Set fill color
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                20,
                              ), // Circular border
                              borderSide: BorderSide.none, // Remove border line
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(fontFamily: 'DM Sans'),
                            filled: true, // Enable fill color
                            fillColor: Color(0xFFE0E0E0), // Set fill color
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                20,
                              ), // Circular border
                              borderSide: BorderSide.none, // Remove border line
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _login(context),
                          child: Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'DM Sans',
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6e9277), // Button color
                            padding: EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignUpPage(),
                              ), // Navigate to SignUpPage
                            );
                          },
                          child: Text(
                            'SIGN UP HERE!',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'DM Sans',
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            // Handle forgot password action
                          },
                          child: Text(
                            'FORGOT PASSWORD?',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'DM Sans',
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
