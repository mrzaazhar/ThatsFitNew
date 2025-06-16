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

  // Add responsive helper methods
  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;
  bool _isMediumScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= 360 &&
      MediaQuery.of(context).size.width < 600;
  bool _isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;
  bool _isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  double _getProgressSize(BuildContext context) {
    if (_isLandscape(context)) {
      return _isSmallScreen(context) ? 120 : 150;
    }
    return _isSmallScreen(context)
        ? 160
        : (_isMediumScreen(context) ? 200 : 240);
  }

  double _getCardPadding(BuildContext context) {
    if (_isLandscape(context)) {
      return _isSmallScreen(context) ? 16 : 20;
    }
    return _isSmallScreen(context) ? 20 : (_isMediumScreen(context) ? 24 : 28);
  }

  double _getFontSize(BuildContext context,
      {required double small, required double medium, required double large}) {
    if (_isLandscape(context)) {
      return _isSmallScreen(context) ? small * 0.8 : small;
    }
    return _isSmallScreen(context)
        ? small
        : (_isMediumScreen(context) ? medium : large);
  }

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
    final progressSize = _getProgressSize(context);
    final cardPadding = _getCardPadding(context);

    return Scaffold(
      backgroundColor: Colors.black,
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
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: user != null
                ? _firestore.collection('users').doc(user.uid).snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              int steps = _currentSteps;
              int weeklyTotal = _weeklyTotal;
              if (snapshot.hasData && snapshot.data!.data() != null) {
                steps = snapshot.data!.data()!['dailySteps'] ?? steps;
                weeklyTotal =
                    snapshot.data!.data()!['weeklySteps'] ?? weeklyTotal;
              }

              return Column(
                children: [
                  // Custom App Bar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isLandscape(context) ? 16 : 20,
                      vertical: _isLandscape(context) ? 10 : 15,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: _isLandscape(context) ? 20 : 22,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        SizedBox(width: _isLandscape(context) ? 8 : 10),
                        Text(
                          'Step Count',
                          style: TextStyle(
                            fontSize: _getFontSize(context,
                                small: 22, medium: 24, large: 28),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: _isLandscape(context) ? 20 : 24,
                          ),
                          onPressed: _loadInitialSteps,
                        ),
                      ],
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _isLandscape(context) ? 16 : 20,
                        ),
                        child: _isLandscape(context)
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildDailyProgressCard(
                                      context,
                                      steps,
                                      progressSize,
                                      cardPadding,
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: _buildWeeklyProgressCard(
                                      context,
                                      weeklyTotal,
                                      cardPadding,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDailyProgressCard(
                                    context,
                                    steps,
                                    progressSize,
                                    cardPadding,
                                  ),
                                  SizedBox(height: 20),
                                  _buildWeeklyProgressCard(
                                    context,
                                    weeklyTotal,
                                    cardPadding,
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).padding.bottom +
                                            20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDailyProgressCard(
    BuildContext context,
    int steps,
    double progressSize,
    double cardPadding,
  ) {
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Progress',
                style: TextStyle(
                  fontSize:
                      _getFontSize(context, small: 18, medium: 20, large: 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              Container(
                padding: EdgeInsets.all(_isLandscape(context) ? 6 : 8),
                decoration: BoxDecoration(
                  color: Color(0xFF6e9277).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_walk_rounded,
                  color: Color(0xFF6e9277),
                  size: _isLandscape(context) ? 20 : 24,
                ),
              ),
            ],
          ),
          SizedBox(height: _isLandscape(context) ? 16 : 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: progressSize,
                width: progressSize,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: steps / dailyGoal,
                  ),
                  duration: Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6e9277),
                      ),
                      strokeWidth: _isLandscape(context) ? 8 : 12,
                    );
                  },
                ),
              ),
              Column(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: _isLandscape(context) ? 32 : 40,
                    color: steps >= dailyGoal
                        ? Colors.amber
                        : Colors.white.withOpacity(0.3),
                  ),
                  SizedBox(height: _isLandscape(context) ? 8 : 12),
                  Text(
                    '$steps',
                    style: TextStyle(
                      fontSize: _getFontSize(context,
                          small: 32, medium: 36, large: 42),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'of $dailyGoal steps',
                    style: TextStyle(
                      fontSize: _getFontSize(context,
                          small: 14, medium: 15, large: 16),
                      color: Colors.white.withOpacity(0.7),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: _isLandscape(context) ? 16 : 24),
          Wrap(
            spacing: _isLandscape(context) ? 8 : 12,
            runSpacing: _isLandscape(context) ? 8 : 12,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _buildInfoBox(
                Icons.timer_outlined,
                'Time Active',
                '2h 30m',
                context,
              ),
              _buildInfoBox(
                Icons.local_fire_department_outlined,
                'Calories',
                '350',
                context,
              ),
              _buildInfoBox(
                Icons.straighten_outlined,
                'Distance',
                '5.2 km',
                context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard(
    BuildContext context,
    int weeklyTotal,
    double cardPadding,
  ) {
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                  fontSize:
                      _getFontSize(context, small: 18, medium: 20, large: 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              Container(
                padding: EdgeInsets.all(_isLandscape(context) ? 6 : 8),
                decoration: BoxDecoration(
                  color: Color(0xFF6e9277).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF6e9277),
                  size: _isLandscape(context) ? 20 : 24,
                ),
              ),
            ],
          ),
          SizedBox(height: _isLandscape(context) ? 16 : 24),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: weeklyTotal / weeklyGoal,
            ),
            duration: Duration(milliseconds: 800),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF6e9277),
                ),
                minHeight: _isLandscape(context) ? 8 : 10,
                borderRadius: BorderRadius.circular(5),
              );
            },
          ),
          SizedBox(height: _isLandscape(context) ? 12 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$weeklyTotal steps',
                style: TextStyle(
                  fontSize:
                      _getFontSize(context, small: 14, medium: 15, large: 16),
                  color: Colors.white.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '$weeklyGoal steps',
                style: TextStyle(
                  fontSize:
                      _getFontSize(context, small: 14, medium: 15, large: 16),
                  color: Colors.white.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isLandscape(context) ? 12 : 16,
        vertical: _isLandscape(context) ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: _isLandscape(context) ? 20 : 24,
            color: Color(0xFF6e9277),
          ),
          SizedBox(height: _isLandscape(context) ? 6 : 8),
          Text(
            label,
            style: TextStyle(
              fontSize: _getFontSize(context, small: 11, medium: 12, large: 14),
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: _getFontSize(context, small: 13, medium: 14, large: 16),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
