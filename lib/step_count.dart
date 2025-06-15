import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepCountPage extends StatefulWidget {
  @override
  _StepCountPageState createState() => _StepCountPageState();
}

class _StepCountPageState extends State<StepCountPage> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  int _currentSteps = 0;
  int _weeklyTotal = 0;
  final int dailyGoal = 10000;
  final int weeklyGoal = 70000;
  double _lastMagnitude = 0;
  double _threshold = 12.0;
  DateTime? _lastStepTime;
  DateTime? _lastResetDate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkAndResetDailySteps().then((_) => _loadInitialSteps());
    _initAccelerometer();
  }

  Future<void> _checkAndResetDailySteps() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final lastResetDate = (data['lastResetDate'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        if (lastResetDate == null ||
            lastResetDate.year != now.year ||
            lastResetDate.month != now.month ||
            lastResetDate.day != now.day) {
          final currentWeeklyTotal = data['weeklySteps'] ?? 0;

          await _firestore.collection('users').doc(user.uid).update({
            'dailySteps': 0,
            'lastResetDate': FieldValue.serverTimestamp(),
            'weeklySteps': currentWeeklyTotal,
          });

          setState(() {
            _currentSteps = 0;
            _weeklyTotal = currentWeeklyTotal;
            _lastResetDate = now;
          });
        } else {
          setState(() {
            _lastResetDate = lastResetDate;
          });
        }
      }
    }
  }

  Future<void> _loadInitialSteps() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _currentSteps = data['dailySteps'] ?? 0;
          _weeklyTotal = data['weeklySteps'] ?? 0;
          _lastResetDate = (data['lastResetDate'] as Timestamp?)?.toDate();
        });
      }
    }
  }

  void _initAccelerometer() {
    _accelerometerSubscription = accelerometerEvents.listen((event) async {
      double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > _threshold && _lastMagnitude <= _threshold) {
        if (_lastStepTime == null ||
            DateTime.now().difference(_lastStepTime!).inMilliseconds > 300) {
          setState(() {
            _currentSteps++;
            _weeklyTotal++;
            _lastStepTime = DateTime.now();
          });
          await _updateStepCountInFirestore(_currentSteps, _weeklyTotal);
        }
      }
      _lastMagnitude = magnitude;
    });
  }

  Future<void> _updateStepCountInFirestore(int steps, int weeklySteps) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'dailySteps': steps,
        'weeklySteps': weeklySteps,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
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
            onPressed: _loadInitialSteps,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: user != null
            ? _firestore.collection('users').doc(user.uid).snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          int steps = _currentSteps;
          int weeklyTotal = _weeklyTotal;
          if (snapshot.hasData && snapshot.data!.data() != null) {
            steps = snapshot.data!.data()!['dailySteps'] ?? steps;
            weeklyTotal = snapshot.data!.data()!['weeklySteps'] ?? weeklyTotal;
          }
          return SingleChildScrollView(
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
                              value: steps / dailyGoal,
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
                                color: steps >= dailyGoal
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                '$steps',
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
                        value: weeklyTotal / weeklyGoal,
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
                            '$weeklyTotal steps',
                            style:
                                TextStyle(fontSize: 18, fontFamily: 'DM Sans'),
                          ),
                          Text(
                            '$weeklyGoal steps',
                            style:
                                TextStyle(fontSize: 18, fontFamily: 'DM Sans'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
