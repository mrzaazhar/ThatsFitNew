import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/homepage.dart';
import 'firebase_options.dart';
import 'signup_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set Firebase locale to fix the warning
  FirebaseAuth.instance.setLanguageCode('en');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Check if user exists in Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      if (!userDoc.exists) {
        // If user doesn't exist in Firestore, show message and redirect to signup
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account not found. Please sign up first.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignUpPage()),
        );
      } else {
        // Navigate to home page after successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
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
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred during login')));
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
