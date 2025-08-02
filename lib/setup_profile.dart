import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'services/workout_service.dart';

class SetupProfilePage extends StatefulWidget {
  @override
  _SetupProfilePageState createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _selectedGender = 'Male';
  String _selectedExperience = 'Beginner';

  final List<String> _genders = ['Male', 'Female'];
  final List<String> _experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced'
  ];

  String _getCurrentDay() {
    return WorkoutService.getCurrentDay();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(BuildContext context) async {
    // Input validation
    if (_ageController.text.isEmpty || _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red[800],
        ),
      );
      return;
    }

    try {
      final age = int.tryParse(_ageController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());

      if (age == null || weight == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter valid numbers for age and weight'),
            backgroundColor: Colors.red[800],
          ),
        );
        return;
      }

      if (age < 13 || age > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid age between 13 and 100'),
            backgroundColor: Colors.red[800],
          ),
        );
        return;
      }

      if (weight < 30 || weight > 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid weight between 30 and 300 kg'),
            backgroundColor: Colors.red[800],
          ),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get current user data from the main user document
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data() ?? {};

        // Create a profile document in the profile subcollection
        final profileRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .add({
          'age': age,
          'weight': weight,
          'gender': _selectedGender,
          'experience': _selectedExperience,
          'name': userData['name'] ?? '',
          'username': userData['username'] ?? '',
          'email': user.email,
          'profileCompleted': true,
          'dailySteps': 0,
          'weeklySteps': 0,
          'currentDay': _getCurrentDay(),
          'lastResetDate': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'lastWorkoutDay': FieldValue.serverTimestamp(),
          'stepSource': 'health_connect',
          'profileImageUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update the main user document to mark profile as completed
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'profileCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green[700],
          ),
        );

        // Navigate to loginpage after successful profile setup
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: ${e.toString()}'),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isMediumScreen = screenSize.width >= 400 && screenSize.width < 600;
    return Scaffold(
      backgroundColor: Color(0xFF121212), // Dark background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A), // Dark gradient start
              Color(0xFF0D0D0D), // Dark gradient end
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back Button
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: Colors.white, size: isSmallScreen ? 20 : 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Flexible content area
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 20.0,
                    vertical: isSmallScreen ? 10.0 : 20.0,
                  ),
                  child: Column(
                    children: [
                      // Title
                      Container(
                        margin: EdgeInsets.only(
                          top: isSmallScreen ? 20.0 : 30.0,
                          bottom: isSmallScreen ? 30.0 : 40.0,
                        ),
                        child: Text(
                          'Setup Profile',
                          style: TextStyle(
                            fontSize:
                                isSmallScreen ? 24 : (isMediumScreen ? 28 : 30),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'aileron',
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Profile Form Card
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: 500,
                          minHeight: screenSize.height * 0.6,
                        ),
                        child: Card(
                          color: Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(isSmallScreen ? 20 : 30),
                          ),
                          elevation: 10,
                          shadowColor: Colors.black54,
                          child: Padding(
                            padding:
                                EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: isSmallScreen ? 10 : 20),

                                // Age Field
                                TextField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Age',
                                    labelStyle: TextStyle(
                                      fontFamily: 'DM Sans',
                                      color: Colors.grey[400],
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFF2A2A2A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 15 : 20),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 15 : 20),
                                      borderSide: BorderSide(
                                          color: Color(0xFF6e9277), width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 15 : 20),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16 : 20,
                                      vertical: isSmallScreen ? 12 : 16,
                                    ),
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 15 : 20),

                                // Weight Field
                                TextField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Weight (kg)',
                                    labelStyle: TextStyle(
                                      fontFamily: 'DM Sans',
                                      color: Colors.grey[400],
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFF2A2A2A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 15 : 20),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 15 : 20),
                                      borderSide: BorderSide(
                                          color: Color(0xFF6e9277), width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 15 : 20),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16 : 20,
                                      vertical: isSmallScreen ? 12 : 16,
                                    ),
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 15 : 20),

                                // Gender Dropdown
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16 : 20,
                                    vertical: isSmallScreen ? 4 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 15 : 20),
                                    border:
                                        Border.all(color: Colors.transparent),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedGender,
                                      isExpanded: true,
                                      dropdownColor: Color(0xFF2A2A2A),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'DM Sans',
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                      items: _genders.map((String gender) {
                                        return DropdownMenuItem<String>(
                                          value: gender,
                                          child: Text(
                                            gender,
                                            style: TextStyle(
                                              fontFamily: 'DM Sans',
                                              color: Colors.white,
                                              fontSize: isSmallScreen ? 14 : 16,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedGender = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 15 : 20),

                                // Experience Level Dropdown
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16 : 20,
                                    vertical: isSmallScreen ? 4 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 15 : 20),
                                    border:
                                        Border.all(color: Colors.transparent),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedExperience,
                                      isExpanded: true,
                                      dropdownColor: Color(0xFF2A2A2A),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'DM Sans',
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                      items:
                                          _experienceLevels.map((String level) {
                                        return DropdownMenuItem<String>(
                                          value: level,
                                          child: Text(
                                            level,
                                            style: TextStyle(
                                              fontFamily: 'DM Sans',
                                              color: Colors.white,
                                              fontSize: isSmallScreen ? 14 : 16,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedExperience = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 25 : 30),

                                // Save Button
                                Container(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _saveProfile(context),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 12 : 15,
                                      ),
                                      child: Text(
                                        'Save Profile',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontFamily: 'DM Sans',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF6e9277),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 30 : 40,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            isSmallScreen ? 15 : 20),
                                      ),
                                      elevation: 5,
                                      shadowColor:
                                          Color(0xFF6e9277).withOpacity(0.3),
                                    ),
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 20 : 30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
