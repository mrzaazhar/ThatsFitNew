import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

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
  final List<String> _experienceLevels = ['Beginner', 'Intermediate', 'Advanced'];

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
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final age = int.tryParse(_ageController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());

      if (age == null || weight == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter valid numbers for age and weight')),
        );
        return;
      }

      if (age < 13 || age > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid age between 13 and 100')),
        );
        return;
      }

      if (weight < 30 || weight > 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid weight between 30 and 300 kg')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create a new document in the 'users' collection with the user's UID
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'age': age,
          'weight': weight,
          'gender': _selectedGender,
          'experience': _selectedExperience,
          'profileCompleted': true,
          'createdAt': FieldValue.serverTimestamp(),
          'email': user.email,
        }, SetOptions(merge: true));

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile saved successfully!')),
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
        SnackBar(content: Text('Error saving profile: ${e.toString()}')),
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
                  onPressed: () => Navigator.pop(context),
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
                            'Setup Profile',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'aileron',
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Age Field
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Age',
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
                        // Weight Field
                        TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
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
                        // Gender Dropdown
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGender,
                              isExpanded: true,
                              items: _genders.map((String gender) {
                                return DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(
                                    gender,
                                    style: TextStyle(fontFamily: 'DM Sans'),
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
                        SizedBox(height: 20),
                        // Experience Level Dropdown
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedExperience,
                              isExpanded: true,
                              items: _experienceLevels.map((String level) {
                                return DropdownMenuItem<String>(
                                  value: level,
                                  child: Text(
                                    level,
                                    style: TextStyle(fontFamily: 'DM Sans'),
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
                        SizedBox(height: 30),
                        // Save Button
                        ElevatedButton(
                          onPressed: () => _saveProfile(context),
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
                              vertical: 15,
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
