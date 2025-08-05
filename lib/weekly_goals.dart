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

  // Weekly schedule data
  Map<String, Map<String, dynamic>> _weeklySchedule = {};
  DateTime _weekStart = DateTime.now();
  DateTime _weekEnd = DateTime.now().add(Duration(days: 6));

  // Available body parts
  List<String> _availableBodyParts = [
    'Chest',
    'Back',
    'Bicep',
    'Tricep',
    'Shoulder',
    'Legs',
  ];

  // Goal tracking variables
  Map<String, dynamic> _currentGoals = {};
  Map<String, dynamic> _weeklyProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWeekSchedule();
    _loadCurrentGoals();
  }

  @override
  void dispose() {
    _stepGoalController.dispose();
    super.dispose();
  }

  void _initializeWeekSchedule() {
    _weekStart = DateTime.now();
    _weekEnd = _weekStart.add(Duration(days: 6));

    // Initialize schedule for each day of the week
    for (int i = 0; i < 7; i++) {
      DateTime day = _weekStart.add(Duration(days: i));
      String dayKey = _formatDate(day);
      String dayName = _getDayName(day.weekday);

      _weeklySchedule[dayKey] = {
        'dayName': dayName,
        'date': dayKey,
        'isWorkoutDay': false,
        'bodyParts': [],
        'workoutTime': '09:00',
        'isCompleted': false,
      };
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  Future<void> _loadCurrentGoals() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      if (user != null) {
        // Get current week's goals
        final goalsDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('Weekly_Goals')
            .doc('current_week')
            .get();

        if (goalsDoc.exists) {
          _currentGoals = goalsDoc.data()!;
          _stepGoalController.text =
              (_currentGoals['stepGoal'] ?? 0).toString();

          // Load weekly schedule if it exists
          if (_currentGoals['weeklySchedule'] != null) {
            Map<String, dynamic> savedSchedule =
                _currentGoals['weeklySchedule'];
            for (String dayKey in savedSchedule.keys) {
              if (_weeklySchedule.containsKey(dayKey)) {
                _weeklySchedule[dayKey] =
                    Map<String, dynamic>.from(savedSchedule[dayKey]);
              }
            }
          }
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
        final weekStart = _formatDate(_weekStart);
        final weekEnd = _formatDate(_weekEnd);

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

        // Get step count for the week
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
          };
        });
      }
    } catch (e) {
      print('Error loading progress: $e');
    }
  }

  Future<void> _saveGoals() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('Please sign in to save goals', Colors.red);
        return;
      }

      final stepGoal = int.tryParse(_stepGoalController.text) ?? 0;

      if (stepGoal <= 0) {
        _showSnackBar('Please enter valid goals', Colors.red);
        return;
      }

      // Check if at least one workout day is scheduled
      int scheduledWorkouts = _weeklySchedule.values
          .where((day) => day['isWorkoutDay'] == true)
          .length;

      if (scheduledWorkouts == 0) {
        _showSnackBar('Please schedule at least one workout day', Colors.red);
        return;
      }

      final goalsData = {
        'stepGoal': stepGoal,
        'weeklySchedule': _weeklySchedule,
        'weekStart': _formatDate(_weekStart),
        'weekEnd': _formatDate(_weekEnd),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save goals to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('Weekly_Goals')
          .doc('current_week')
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
      backgroundColor: Color(0xFF1a1a1a),
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
          child: _isLoading ? _buildLoadingState() : _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF33443c)),
          ),
          SizedBox(height: 20),
          Text(
            'Loading your goals...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Custom App Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: 10),
              Text(
                'Weekly Goals',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              Spacer(),
            ],
          ),
        ),

        // Main Content
        Expanded(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Week Overview Card
                  _buildWeekOverviewCard(),
                  SizedBox(height: 24),

                  // Progress Overview Card
                  _buildProgressOverviewCard(),
                  SizedBox(height: 24),

                  // Goal Setting Section
                  _buildGoalSettingSection(),
                  SizedBox(height: 24),

                  // Weekly Schedule Section
                  _buildWeeklyScheduleSection(),
                  SizedBox(height: 24),

                  // Save Button
                  _buildSaveButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekOverviewCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF33443c),
            Color(0xFF2a3630),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week\'s Schedule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 12),
          Text(
            '${_formatDate(_weekStart)} - ${_formatDate(_weekEnd)}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                '${_weeklySchedule.values.where((day) => day['isWorkoutDay'] == true).length} workout days scheduled',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverviewCard() {
    final stepProgress = _weeklyProgress['stepGoal'] > 0
        ? (_weeklyProgress['totalSteps'] / _weeklyProgress['stepGoal'])
            .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Overview',
            style: TextStyle(
              fontSize: 18,
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
          backgroundColor: Colors.grey[700],
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF33443c)),
          minHeight: 8,
        ),
        SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}% Complete',
          style: TextStyle(
            color: Colors.white,
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
        color: Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 20),

          // Step Goal
          TextField(
            controller: _stepGoalController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Weekly Step Goal',
              labelStyle: TextStyle(color: Colors.white),
              hintText: 'e.g., 50000',
              hintStyle: TextStyle(color: Colors.grey[300]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF33443c)),
              ),
              filled: true,
              fillColor: Color(0xFF1a1a1a),
              prefixIcon: Icon(Icons.directions_walk, color: Color(0xFF33443c)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyScheduleSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Workout Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Schedule your workouts for the week:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 16),

          // Weekly schedule cards
          ...(_weeklySchedule.entries
              .map((entry) => _buildDayScheduleCard(entry.key, entry.value))),
        ],
      ),
    );
  }

  Widget _buildDayScheduleCard(String dayKey, Map<String, dynamic> dayData) {
    bool isWorkoutDay = dayData['isWorkoutDay'] ?? false;
    String dayName = dayData['dayName'] ?? '';
    String date = dayData['date'] ?? '';
    List<String> bodyParts = List<String>.from(dayData['bodyParts'] ?? []);
    String workoutTime = dayData['workoutTime'] ?? '09:00';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Color(0xFF1a1a1a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isWorkoutDay ? Color(0xFF33443c) : Colors.grey[700]!,
          width: isWorkoutDay ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Checkbox(
              value: isWorkoutDay,
              onChanged: (bool? value) {
                setState(() {
                  _weeklySchedule[dayKey]!['isWorkoutDay'] = value ?? false;
                  if (!(value ?? false)) {
                    _weeklySchedule[dayKey]!['bodyParts'] = [];
                  }
                });
              },
              activeColor: Color(0xFF33443c),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: isWorkoutDay ? Color(0xFF33443c) : Colors.white,
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (isWorkoutDay)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF33443c),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${bodyParts.length} parts',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        children: isWorkoutDay
            ? [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Workout Time
                      Text(
                        'Workout Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, dayKey),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFF1a1a1a),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                workoutTime,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Body Parts Selection
                      Text(
                        'Focus Body Parts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableBodyParts.map((bodyPart) {
                          bool isSelected = bodyParts.contains(bodyPart);
                          return FilterChip(
                            label: Text(
                              bodyPart,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[300],
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  bodyParts.add(bodyPart);
                                } else {
                                  bodyParts.remove(bodyPart);
                                }
                                _weeklySchedule[dayKey]!['bodyParts'] =
                                    bodyParts;
                              });
                            },
                            backgroundColor: Color(0xFF3d3d3d),
                            selectedColor: Color(0xFF33443c),
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, String dayKey) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.parse(
            '2024-01-01 ${_weeklySchedule[dayKey]!['workoutTime']}:00'),
      ),
    );

    if (picked != null) {
      setState(() {
        _weeklySchedule[dayKey]!['workoutTime'] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveGoals,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF33443c),
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
