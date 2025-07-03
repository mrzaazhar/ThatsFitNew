import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WeeklyGoalsPage extends StatefulWidget {
  @override
  _WeeklyGoalsPageState createState() => _WeeklyGoalsPageState();
}

class _WeeklyGoalsPageState extends State<WeeklyGoalsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for goal inputs
  final TextEditingController _stepGoalController = TextEditingController();
  final TextEditingController _workoutGoalController = TextEditingController();

  // Selected body part for focus
  String _selectedBodyPart = 'Full Body';
  final List<String> _bodyParts = [
    'Full Body',
    'Chest',
    'Back',
    'Arms',
    'Legs',
    'Shoulders',
    'Core'
  ];

  // Goal tracking variables
  Map<String, dynamic> _currentGoals = {};
  Map<String, dynamic> _weeklyProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentGoals();
  }

  @override
  void dispose() {
    _stepGoalController.dispose();
    _workoutGoalController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentGoals() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      if (user != null) {
        // Get current week's goals
        final weekStart = _getWeekStart();
        final goalsDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('weekly_goals')
            .doc(weekStart)
            .get();

        if (goalsDoc.exists) {
          _currentGoals = goalsDoc.data()!;
          _stepGoalController.text =
              (_currentGoals['stepGoal'] ?? 0).toString();
          _workoutGoalController.text =
              (_currentGoals['workoutGoal'] ?? 0).toString();
          _selectedBodyPart = _currentGoals['focusBodyPart'] ?? 'Full Body';
        }

        // Load weekly progress
        await _loadWeeklyProgress();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading goals: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWeeklyProgress() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final weekStart = _getWeekStart();
        final weekEnd = _getWeekEnd();

        // Get completed workouts for the week
        final workoutsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workout_history')
            .where('completedAt', isGreaterThanOrEqualTo: weekStart)
            .where('completedAt', isLessThanOrEqualTo: weekEnd)
            .get();

        int completedWorkouts = workoutsSnapshot.docs.length;
        int totalSteps = 0;

        // Get step count for the week (from profile or activity tracking)
        final profileSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .limit(1)
            .get();

        if (profileSnapshot.docs.isNotEmpty) {
          final profileData = profileSnapshot.docs[0].data();
          totalSteps = profileData['weeklySteps'] ?? 0;
        }

        setState(() {
          _weeklyProgress = {
            'completedWorkouts': completedWorkouts,
            'totalSteps': totalSteps,
            'stepGoal': _currentGoals['stepGoal'] ?? 0,
            'workoutGoal': _currentGoals['workoutGoal'] ?? 0,
          };
        });
      }
    } catch (e) {
      print('Error loading progress: $e');
    }
  }

  String _getWeekStart() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
  }

  String _getWeekEnd() {
    final now = DateTime.now();
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    return '${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveGoals() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('Please sign in to save goals', Colors.red);
        return;
      }

      final stepGoal = int.tryParse(_stepGoalController.text) ?? 0;
      final workoutGoal = int.tryParse(_workoutGoalController.text) ?? 0;

      if (stepGoal <= 0 || workoutGoal <= 0) {
        _showSnackBar('Please enter valid goals', Colors.red);
        return;
      }

      final weekStart = _getWeekStart();
      final goalsData = {
        'stepGoal': stepGoal,
        'workoutGoal': workoutGoal,
        'focusBodyPart': _selectedBodyPart,
        'createdAt': FieldValue.serverTimestamp(),
        'weekStart': weekStart,
        'weekEnd': _getWeekEnd(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weekly_goals')
          .doc(weekStart)
          .set(goalsData);

      setState(() {
        _currentGoals = goalsData;
      });

      _showSnackBar('Weekly goals saved successfully! 🎯', Colors.green);
      await _loadWeeklyProgress();
    } catch (e) {
      print('Error saving goals: $e');
      _showSnackBar('Failed to save goals. Please try again.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf8f9fa),
      appBar: AppBar(
        title: Text(
          'Weekly Goals',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF6e9277),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6e9277)),
          ),
          SizedBox(height: 20),
          Text(
            'Loading your goals...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Overview Card
          _buildProgressOverviewCard(),
          SizedBox(height: 24),

          // Goal Setting Section
          _buildGoalSettingSection(),
          SizedBox(height: 24),

          // Body Part Focus Section
          _buildBodyPartFocusSection(),
          SizedBox(height: 24),

          // Save Button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildProgressOverviewCard() {
    final stepProgress = _weeklyProgress['stepGoal'] > 0
        ? (_weeklyProgress['totalSteps'] / _weeklyProgress['stepGoal'])
            .clamp(0.0, 1.0)
        : 0.0;
    final workoutProgress = _weeklyProgress['workoutGoal'] > 0
        ? (_weeklyProgress['completedWorkouts'] /
                _weeklyProgress['workoutGoal'])
            .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6e9277),
            Color(0xFF5a7a63),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week\'s Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 20),

          // Steps Progress
          _buildProgressItem(
            'Steps',
            _weeklyProgress['totalSteps'] ?? 0,
            _weeklyProgress['stepGoal'] ?? 0,
            stepProgress,
            Icons.directions_walk,
          ),
          SizedBox(height: 16),

          // Workouts Progress
          _buildProgressItem(
            'Workouts',
            _weeklyProgress['completedWorkouts'] ?? 0,
            _weeklyProgress['workoutGoal'] ?? 0,
            workoutProgress,
            Icons.fitness_center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
      String label, int current, int goal, double progress, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            Spacer(),
            Text(
              '$current / $goal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 8,
        ),
        SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}% Complete',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSettingSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Your Weekly Goals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 20),

          // Step Goal
          TextField(
            controller: _stepGoalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Weekly Step Goal',
              hintText: 'e.g., 50000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.directions_walk, color: Color(0xFF6e9277)),
            ),
          ),
          SizedBox(height: 16),

          // Workout Goal
          TextField(
            controller: _workoutGoalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Weekly Workout Goal',
              hintText: 'e.g., 4',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.fitness_center, color: Color(0xFF6e9277)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPartFocusSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Body Part',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedBodyPart,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.fitness_center, color: Color(0xFF6e9277)),
            ),
            items: _bodyParts.map((bodyPart) {
              return DropdownMenuItem(
                value: bodyPart,
                child: Text(bodyPart),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBodyPart = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveGoals,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF6e9277),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Save Weekly Goals',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
