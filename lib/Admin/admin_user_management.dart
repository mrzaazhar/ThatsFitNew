import 'package:flutter/material.dart';
import 'admin_service.dart';

class AdminUserManagement extends StatefulWidget {
  @override
  _AdminUserManagementState createState() => _AdminUserManagementState();
}

class _AdminUserManagementState extends State<AdminUserManagement> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await AdminService.getAllUsersFromBackend();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading users', Colors.red);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    return _users.where((user) {
      final name = user['name']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final username = user['username']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          username.contains(query);
    }).toList();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Color(0xFF33443c),
        title: Text(
          'User Management',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF33443c)),
                ),
                filled: true,
                fillColor: Color(0xFF2d2d2d),
              ),
            ),
          ),

          // User Count
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Users (${_filteredUsers.length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddUserDialog(),
                  icon: Icon(Icons.add),
                  label: Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF33443c),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Users List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF33443c)),
                    ),
                  )
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Color(0xFF2d2d2d),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF33443c),
          child: Text(
            (user['displayName'] ?? user['name'] ?? 'U')
                .substring(0, 1)
                .toUpperCase(),
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user['displayName'] ?? user['name'] ?? 'Unknown',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          user['email'] ?? 'No email',
          style: TextStyle(color: Colors.grey[400]),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfoRow('Username', user['username'] ?? 'Unknown'),
                _buildUserInfoRow('Age', '${user['age'] ?? 0} years'),
                _buildUserInfoRow('Weight', '${user['weight'] ?? 0} kg'),
                _buildUserInfoRow('Gender', user['gender'] ?? 'Unknown'),
                _buildUserInfoRow(
                    'Experience', user['experience'] ?? 'Unknown'),
                _buildUserInfoRow(
                    'Workouts', '${user['workoutCount'] ?? 0} completed'),
                _buildUserInfoRow(
                    'Weekly Steps', '${user['weeklySteps'] ?? 0} steps'),
                _buildUserInfoRow('Profile Completed',
                    user['profileCompleted'] ?? false ? 'Yes' : 'No'),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showEditUserDialog(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Edit'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showDeleteUserDialog(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _usernameController = TextEditingController();
    final _passwordController = TextEditingController();
    final _ageController = TextEditingController();
    final _weightController = TextEditingController();
    String _selectedGender = 'Male';
    String _selectedExperience = 'Beginner';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New User'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Name is required';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Email is required';
                      if (!value!.contains('@'))
                        return 'Valid email is required';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: 'Username'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Username is required';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Password is required';
                      if (value!.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(labelText: 'Gender'),
                    items: ['Male', 'Female'].map((gender) {
                      return DropdownMenuItem(
                          value: gender, child: Text(gender));
                    }).toList(),
                    onChanged: (value) {
                      _selectedGender = value!;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedExperience,
                    decoration: InputDecoration(labelText: 'Experience'),
                    items: ['Beginner', 'Intermediate', 'Advanced'].map((exp) {
                      return DropdownMenuItem(value: exp, child: Text(exp));
                    }).toList(),
                    onChanged: (value) {
                      _selectedExperience = value!;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final result = await AdminService.createUserViaBackend(
                      email: _emailController.text.trim(),
                      password: _passwordController.text,
                      name: _nameController.text.trim(),
                      username: _usernameController.text.trim(),
                      age: int.tryParse(_ageController.text),
                      weight: double.tryParse(_weightController.text),
                      gender: _selectedGender,
                      experience: _selectedExperience,
                    );

                    Navigator.of(context).pop();
                    _showSnackBar('User created successfully', Colors.green);
                    _loadUsers();
                  } catch (e) {
                    Navigator.of(context).pop();
                    _showSnackBar(
                        'Failed to create user: ${e.toString()}', Colors.red);
                  }
                }
              },
              child: Text('Add User'),
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final _formKey = GlobalKey<FormState>();
    final _nameController =
        TextEditingController(text: user['displayName'] ?? user['name']);
    final _usernameController = TextEditingController(text: user['username']);
    final _ageController = TextEditingController(text: user['age']?.toString());
    final _weightController =
        TextEditingController(text: user['weight']?.toString());
    String _selectedGender = user['gender'] ?? 'Male';
    String _selectedExperience = user['experience'] ?? 'Beginner';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit User'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Name is required';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: 'Username'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Username is required';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(labelText: 'Gender'),
                    items: ['Male', 'Female'].map((gender) {
                      return DropdownMenuItem(
                          value: gender, child: Text(gender));
                    }).toList(),
                    onChanged: (value) {
                      _selectedGender = value!;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedExperience,
                    decoration: InputDecoration(labelText: 'Experience'),
                    items: ['Beginner', 'Intermediate', 'Advanced'].map((exp) {
                      return DropdownMenuItem(value: exp, child: Text(exp));
                    }).toList(),
                    onChanged: (value) {
                      _selectedExperience = value!;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final success = await AdminService.updateUserViaBackend(
                      uid: user['uid'],
                      name: _nameController.text.trim(),
                      username: _usernameController.text.trim(),
                      age: int.tryParse(_ageController.text),
                      weight: double.tryParse(_weightController.text),
                      gender: _selectedGender,
                      experience: _selectedExperience,
                    );

                    Navigator.of(context).pop();

                    if (success) {
                      _showSnackBar('User updated successfully', Colors.green);
                      _loadUsers();
                    } else {
                      _showSnackBar('Failed to update user', Colors.red);
                    }
                  } catch (e) {
                    Navigator.of(context).pop();
                    _showSnackBar(
                        'Failed to update user: ${e.toString()}', Colors.red);
                  }
                }
              },
              child: Text('Update User'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete User'),
          content: Text(
              'Are you sure you want to delete ${user['displayName'] ?? user['name']}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final success =
                      await AdminService.deleteUserViaBackend(user['uid']);

                  Navigator.of(context).pop();

                  if (success) {
                    _showSnackBar('User deleted successfully', Colors.green);
                    _loadUsers();
                  } else {
                    _showSnackBar('Failed to delete user', Colors.red);
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  _showSnackBar(
                      'Failed to delete user: ${e.toString()}', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
