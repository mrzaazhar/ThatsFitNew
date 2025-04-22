import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile2.dart';

class EditProfile1 extends StatefulWidget {
  @override
  _EditProfile1State createState() => _EditProfile1State();
}

class _EditProfile1State extends State<EditProfile1> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists) {
          setState(() {
            _nameController.text = doc.data()?['name'] ?? '';
            _usernameController.text = doc.data()?['username'] ?? '';
            _emailController.text = user.email ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(BuildContext context) async {
    // Input validation
    if (_nameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    // Validate password if provided
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 6 characters long')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6e9277)),
          ),
        );
      },
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        bool needsReauth = false;

        // Check if email is being changed
        if (_emailController.text.trim() != user.email) {
          needsReauth = true;
        }

        // Check if password is being changed
        if (_passwordController.text.isNotEmpty) {
          needsReauth = true;
        }

        // Reauthenticate if needed
        if (needsReauth) {
          try {
            await _reauthenticateUser(context, user);
          } catch (e) {
            // Close loading dialog
            Navigator.of(context).pop();

            if (e is FirebaseAuthException) {
              if (e.code == 'operation-cancelled') {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Operation cancelled')));
              } else if (e.code == 'wrong-password') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Incorrect password. Please try again.'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Authentication error: ${e.message}')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Authentication error: ${e.toString()}'),
                ),
              );
            }
            return;
          }
        }

        // Update email if changed
        if (_emailController.text.trim() != user.email) {
          await user.updateEmail(_emailController.text.trim());
        }

        // Update password if provided
        if (_passwordController.text.isNotEmpty) {
          await user.updatePassword(_passwordController.text.trim());
        }

        // Update Firestore document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'name': _nameController.text.trim(),
              'username': _usernameController.text.trim(),
              'email': _emailController.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );

        // Navigate to edit_profile2
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EditProfilePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      String message = 'Error updating profile';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'The email is already in use';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please log in again to update your profile';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    }
  }

  // Helper method to reauthenticate user
  Future<void> _reauthenticateUser(BuildContext context, User user) async {
    // Show dialog to get current password
    final TextEditingController passwordController = TextEditingController();
    bool dialogConfirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reauthentication Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter your current password to update your email or password.',
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  dialogConfirmed = true;
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter your current password'),
                    ),
                  );
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (!dialogConfirmed || passwordController.text.isEmpty) {
      throw FirebaseAuthException(
        code: 'operation-cancelled',
        message: 'Reauthentication cancelled',
      );
    }

    try {
      // Create credential with email and password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text,
      );

      // Reauthenticate user
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'Incorrect password',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage('assets/PNG/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context); // Go back to the previous page
                  },
                ),
              ),
            ),
            Expanded(flex: 1, child: Container()),
            Expanded(
              flex: 0,
              child: Container(
                margin: EdgeInsets.zero,
                height: 550,
                width: 500,
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.all(30),
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'aileron',
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Email Field
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(fontFamily: 'DM Sans'),
                            filled: true,
                            fillColor: Color(0xFFE0E0E0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(fontFamily: 'DM Sans'),
                            filled: true,
                            fillColor: Color(0xFFE0E0E0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Name Field
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            labelStyle: TextStyle(fontFamily: 'DM Sans'),
                            filled: true,
                            fillColor: Color(0xFFE0E0E0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Username Field
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: TextStyle(fontFamily: 'DM Sans'),
                            filled: true,
                            fillColor: Color(0xFFE0E0E0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        // Save Button
                        Container(
                          margin: EdgeInsets.all(20),
                          child: ElevatedButton(
                            onPressed: () {
                              _saveProfile(context);
                            },
                            child: Text(
                              'Save Profile',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'DM Sans',
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6e9277),
                              padding: EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 10,
                              ),
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
