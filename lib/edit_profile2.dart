import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homepage.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _ageController.text = doc.data()?['age']?.toString() ?? '';
            _weightController.text = doc.data()?['weight']?.toString() ?? '';
            _selectedGender = doc.data()?['gender'] ?? 'Male';
            _selectedExperience = doc.data()?['experience'] ?? 'Beginner';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile(BuildContext context) async {
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
          SnackBar(
              content: Text('Please enter valid numbers for age and weight')),
        );
        return;
      }

      if (age < 13 || age > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please enter a valid age between 13 and 100')),
        );
        return;
      }

      if (weight < 30 || weight > 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Please enter a valid weight between 30 and 300 kg')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'age': age,
          'weight': weight,
          'gender': _selectedGender,
          'experience': _selectedExperience,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Additional Info',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Form Section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form Fields
                      _buildTextField(
                        controller: _ageController,
                        label: 'Age',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      _buildDropdown(
                        value: _selectedGender,
                        label: 'Gender',
                        icon: Icons.people_outline,
                        items: _genders,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() => _selectedGender = value);
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      _buildDropdown(
                        value: _selectedExperience,
                        label: 'Experience Level',
                        icon: Icons.fitness_center_outlined,
                        items: _experienceLevels,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() => _selectedExperience = value);
                          }
                        },
                      ),
                      SizedBox(height: 30),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _updateProfile(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6e9277),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(icon, color: Color(0xFF6e9277)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: Color(0xFF1A1A1A),
          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF6e9277)),
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(icon, color: Color(0xFF6e9277), size: 20),
                    SizedBox(width: 12),
                    Text(item),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
