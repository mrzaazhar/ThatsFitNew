import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/workout_service.dart';
import 'workout.dart';

class StepCountPage extends StatefulWidget {
  @override
  _StepCountPageState createState() => _StepCountPageState();
}

class _StepCountPageState extends State<StepCountPage> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  int _currentSteps = 0;
  final int dailyGoal = 10000;
  int _weeklyTotal = 0;
  final int weeklyGoal = 70000;
  double _lastMagnitude = 0;
  double _threshold = 13.0;
  bool _isStep = false;
  DateTime? _lastStepTime;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentDate;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now().toIso8601String().split('T')[0];
    _loadStepCount();
    _initAccelerometer();
    _setupMidnightReset();
  }

  void _setupMidnightReset() {
    // Calculate time until next midnight
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    // Set up timer for midnight reset
    _midnightTimer = Timer(timeUntilMidnight, () {
      _resetStepCount();
      // Set up next midnight timer
      _setupMidnightReset();
    });
  }

  Future<void> _resetStepCount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Reset step count in users collection
        await _firestore.collection('users').doc(user.uid).update({
          'dailySteps': 0,
          'lastResetDate': DateTime.now().toIso8601String().split('T')[0],
        });

        setState(() {
          _currentSteps = 0;
        });
      }
    } catch (e) {
      print('Error resetting step count: $e');
    }
  }

  Future<void> _loadStepCount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final lastResetDate = userData['lastResetDate'] as String?;
          final currentDate = DateTime.now().toIso8601String().split('T')[0];

          // Check if we need to reset (new day)
          if (lastResetDate != currentDate) {
            await _resetStepCount();
          } else {
            setState(() {
              _currentSteps = userData['dailySteps'] ?? 0;
              _weeklyTotal = userData['weeklySteps'] ?? 0;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading step count: $e');
    }
  }

  Future<void> _updateStepCount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update step count in users collection
        await _firestore.collection('users').doc(user.uid).update({
          'dailySteps': _currentSteps,
          'weeklySteps': _weeklyTotal,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating step count: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating step count: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initAccelerometer() {
    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      // Calculate the magnitude of acceleration
      double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Simple step detection algorithm
      if (!_isStep && magnitude > _threshold && _lastMagnitude <= _threshold) {
        // Check if enough time has passed since the last step (debouncing)
        if (_lastStepTime == null ||
            DateTime.now().difference(_lastStepTime!).inMilliseconds > 300) {
          setState(() {
            _currentSteps++;
            _weeklyTotal = _currentSteps * 5; // For demo purposes
            _lastStepTime = DateTime.now();
          });
          _updateStepCount(); // Update Firebase after each step
        }
      }

      _lastMagnitude = magnitude;
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> _showManualStepInputDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Step Count'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter your step count',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (controller.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a step count')),
                  );
                  return;
                }

                final steps = int.parse(controller.text);
                if (steps < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Step count cannot be negative')),
                  );
                  return;
                }

                setState(() {
                  _currentSteps = steps;
                  _weeklyTotal = steps * 5; // For demo purposes
                });

                // Update Firebase
                final user = _auth.currentUser;
                if (user != null) {
                  await _firestore.collection('users').doc(user.uid).update({
                    'dailySteps': steps,
                    'weeklySteps': _weeklyTotal,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(context); // Close the dialog
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating step count: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF008000),
      appBar: AppBar(
        title: Text(
          'Step Count',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFamily: 'DM Sans',
          ),
        ),
        backgroundColor: Color(0xFF008000),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _initAccelerometer,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Progress Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFbfbfbf),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Progress',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      Icon(
                        Icons.directions_walk,
                        size: 30,
                        color: Color(0xFF33443c),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: CircularProgressIndicator(
                          value: _currentSteps / dailyGoal,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF33443c),
                          ),
                          strokeWidth: 15,
                        ),
                      ),
                      Column(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 40,
                            color: _currentSteps >= dailyGoal
                                ? Colors.amber
                                : Colors.grey,
                          ),
                          SizedBox(height: 10),
                          Text(
                            '$_currentSteps',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                          Text(
                            'of $dailyGoal steps',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoBox(Icons.timer, 'Time Active', '2h 30m'),
                      _buildInfoBox(
                        Icons.local_fire_department,
                        'Calories',
                        '350',
                      ),
                      _buildInfoBox(Icons.straighten, 'Distance', '5.2 km'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Weekly Progress Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFbfbfbf),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly Progress',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 30,
                        color: Color(0xFF33443c),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: _weeklyTotal / weeklyGoal,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF33443c),
                    ),
                    minHeight: 10,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_weeklyTotal steps',
                        style: TextStyle(fontSize: 18, fontFamily: 'DM Sans'),
                      ),
                      Text(
                        '$weeklyGoal steps',
                        style: TextStyle(fontSize: 18, fontFamily: 'DM Sans'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showManualStepInputDialog,
        backgroundColor: Color(0xFF33443c),
        child: Icon(Icons.edit, color: Colors.white),
        tooltip: 'Enter Step Count Manually',
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Color(0xFF33443c)),
          SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 14, fontFamily: 'DM Sans')),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }
}
