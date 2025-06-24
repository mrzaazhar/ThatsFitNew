import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/health_connect_service.dart';

class StepCountPage extends StatefulWidget {
  @override
  _StepCountPageState createState() => _StepCountPageState();
}

class _StepCountPageState extends State<StepCountPage> {
  int _currentSteps = 0;
  int _weeklyTotal = 0;
  final int dailyGoal = 10000;
  final int weeklyGoal = 70000;
  DateTime? _lastResetDate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Health Connect integration
  final HealthConnectService _healthConnectService = HealthConnectService();
  bool _healthConnectAvailable = false;
  bool _healthConnectInitialized = false;
  String _healthConnectStatus = 'Not initialized';
  bool _isLoading = true;
  DateTime? _lastUpdated;

  // Stream subscription for Health Connect updates
  StreamSubscription<int>? _healthConnectSubscription;

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

  // Helper methods to calculate metrics from step count
  int _calculateCalories(int steps) {
    // Average person burns about 0.04 calories per step
    return (steps * 0.04).round();
  }

  double _calculateDistance(int steps) {
    // Average step length is about 0.762 meters (30 inches)
    return (steps * 0.762 / 1000); // Convert to kilometers
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  String _calculateTimeActive(int steps) {
    // Assuming average walking speed of 100 steps per minute
    final minutes = (steps / 100).round();
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

  String _formatLastUpdated(DateTime? lastUpdated) {
    if (lastUpdated == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== Initializing Step Count App ===');

      // Initialize Health Connect first
      await _initHealthConnect();

      // Then load initial data from Firestore (as fallback)
      await _checkAndResetDailySteps();
      await _loadInitialSteps();

      // Calculate weekly total from Health Connect if available
      if (_healthConnectAvailable) {
        print(
            'Health Connect available - loading weekly steps from Health Connect');
        await _loadWeeklyStepsFromHealthConnect();
      } else {
        print('Health Connect not available - using Firestore data only');
      }

      print('=== App initialization complete ===');
    } catch (e) {
      print('Error initializing app: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initHealthConnect() async {
    try {
      final initialized = await _healthConnectService.initialize();
      if (initialized) {
        final available = await _healthConnectService.isAvailable();
        setState(() {
          _healthConnectInitialized = true;
          _healthConnectAvailable = available;
          _healthConnectStatus = available ? 'Available' : 'Not available';
        });

        if (available) {
          // Start Health Connect monitoring automatically
          await _startHealthConnectMonitoring();
        }
      }
    } catch (e) {
      setState(() {
        _healthConnectStatus = 'Error: $e';
      });
    }
  }

  Future<void> _loadWeeklyStepsFromHealthConnect() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      final weeklySteps = await _healthConnectService.getStepCountForDateRange(
          startOfWeekDay, now);

      setState(() {
        _weeklyTotal = weeklySteps;
      });

      // Update Firestore with the weekly total
      await _updateStepCountInFirestore(_currentSteps, weeklySteps);
    } catch (e) {
      print('Error loading weekly steps from Health Connect: $e');
    }
  }

  Future<void> _startHealthConnectMonitoring() async {
    try {
      // First check if permissions are already granted
      final hasPermissions = await _healthConnectService.hasPermissions();
      if (hasPermissions) {
        print('Health Connect permissions already granted');
        setState(() {
          _healthConnectStatus = 'Permissions granted';
        });

        // Start monitoring
        await _healthConnectService.startStepCountMonitoring();

        // Get initial step count from Health Connect
        final steps = await _healthConnectService.getTodayStepCount();
        setState(() {
          _currentSteps = steps;
          _lastUpdated = DateTime.now();
        });

        // Update Firebase with the new step count
        await _updateStepCountInFirestore(steps, _weeklyTotal);

        // Listen to Health Connect updates
        _healthConnectSubscription =
            _healthConnectService.stepCountStream.listen((steps) {
          setState(() {
            _currentSteps = steps;
            _lastUpdated = DateTime.now();
          });
          // Update Firebase after UI is updated
          _updateStepCountInFirestore(steps, _weeklyTotal);
        });

        return;
      }

      // If permissions not granted, request them
      final permissionsGranted =
          await _healthConnectService.requestPermissions();
      if (permissionsGranted) {
        setState(() {
          _healthConnectStatus = 'Permissions granted';
        });

        // Start monitoring after permissions are granted
        await _healthConnectService.startStepCountMonitoring();

        // Get initial step count from Health Connect
        final steps = await _healthConnectService.getTodayStepCount();
        setState(() {
          _currentSteps = steps;
          _lastUpdated = DateTime.now();
        });

        // Update Firebase with the new step count
        await _updateStepCountInFirestore(steps, _weeklyTotal);

        // Listen to Health Connect updates
        _healthConnectSubscription =
            _healthConnectService.stepCountStream.listen((steps) {
          setState(() {
            _currentSteps = steps;
            _lastUpdated = DateTime.now();
          });
          // Update Firebase after UI is updated
          _updateStepCountInFirestore(steps, _weeklyTotal);
        });
      } else {
        setState(() {
          _healthConnectStatus = 'Permissions not granted';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Health Connect permissions not granted. Please:\n1. Open Health Connect app\n2. Go to Apps and devices\n3. Enable Steps for this app'),
            duration: Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Try Again',
              onPressed: () => _requestPermissions(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _healthConnectStatus = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting Health Connect: $e'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final permissionsGranted =
          await _healthConnectService.requestPermissions();
      if (permissionsGranted) {
        setState(() {
          _healthConnectStatus = 'Permissions granted';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Health Connect permissions granted!')),
        );
        // Start monitoring after permissions are granted
        await _startHealthConnectMonitoring();
      } else {
        setState(() {
          _healthConnectStatus = 'Permissions denied';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Health Connect permissions denied. Please grant permissions in Health Connect app.'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open Health Connect',
              onPressed: () {
                // This would ideally open Health Connect app
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Please manually open Health Connect app and grant permissions')),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _healthConnectStatus = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting permissions: $e')),
      );
    }
  }

  /// Debug method to help troubleshoot Health Connect issues
  Future<void> _debugHealthConnect() async {
    try {
      print('=== Health Connect Debug Info ===');

      final available = await _healthConnectService.isAvailable();
      print('Health Connect available: $available');

      final hasPerms = await _healthConnectService.hasPermissions();
      print('Has permissions: $hasPerms');

      if (hasPerms) {
        try {
          final steps = await _healthConnectService.getTodayStepCount();
          print('Today steps: $steps');
        } catch (e) {
          print('Error getting steps: $e');
        }
      }

      print('=== End Debug Info ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  Future<void> _refreshStepCount() async {
    if (_healthConnectAvailable) {
      try {
        setState(() {
          _isLoading = true;
        });

        print('=== Refreshing Step Count ===');
        print('Current steps before refresh: $_currentSteps');

        final steps = await _healthConnectService.getTodayStepCount();
        print('Steps from Health Connect: $steps');

        // Update UI immediately
        setState(() {
          _currentSteps = steps;
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });

        // Then update Firebase
        await _updateStepCountInFirestore(steps, _weeklyTotal);

        // Also refresh weekly total
        await _loadWeeklyStepsFromHealthConnect();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Step count refreshed!')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        print('Error refreshing step count: $e');

        String errorMessage = 'Error refreshing step count';

        // Check if it's a permission error
        if (e.toString().contains('READ_STEPS') ||
            e.toString().contains('not declared')) {
          errorMessage =
              'Health Connect permissions not granted. Please:\n1. Open Health Connect app\n2. Go to Apps and devices\n3. Enable Steps for this app';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Health Connect is not available on this device')),
      );
    }
  }

  Future<void> _checkAndResetDailySteps() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;

        // Handle different types for lastResetDate
        DateTime? lastResetDate;
        final lastResetData = data['lastResetDate'];
        if (lastResetData is Timestamp) {
          lastResetDate = lastResetData.toDate();
        } else if (lastResetData is String) {
          try {
            lastResetDate = DateTime.parse(lastResetData);
          } catch (e) {
            print('Error parsing lastResetDate string: $e');
            lastResetDate = null;
          }
        }

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

        // Handle different types for lastResetDate
        DateTime? lastResetDate;
        final lastResetData = data['lastResetDate'];
        if (lastResetData is Timestamp) {
          lastResetDate = lastResetData.toDate();
        } else if (lastResetData is String) {
          try {
            lastResetDate = DateTime.parse(lastResetData);
          } catch (e) {
            print('Error parsing lastResetDate string: $e');
            lastResetDate = null;
          }
        }

        setState(() {
          _currentSteps = data['dailySteps'] ?? 0;
          _weeklyTotal = data['weeklySteps'] ?? 0;
          _lastResetDate = lastResetDate;
        });
      }
    }
  }

  Future<void> _updateStepCountInFirestore(int steps, int weeklySteps) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'dailySteps': steps,
        'weeklySteps': weeklySteps,
        'lastUpdated': FieldValue.serverTimestamp(),
        'stepSource': 'health_connect',
      });
    }
  }

  @override
  void dispose() {
    _healthConnectSubscription?.cancel();
    _healthConnectService.dispose();
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
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6e9277),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading step data...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: user != null
                      ? _firestore.collection('users').doc(user.uid).snapshots()
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    int steps = _currentSteps;
                    int weeklyTotal = _weeklyTotal;

                    // Only update from Firestore if Health Connect is not available
                    if (!_healthConnectAvailable &&
                        snapshot.hasData &&
                        snapshot.data!.data() != null) {
                      steps = snapshot.data!.data()!['dailySteps'] ?? steps;
                      weeklyTotal =
                          snapshot.data!.data()!['weeklySteps'] ?? weeklyTotal;
                    }
                    // If Health Connect is available, only use Firestore for weekly total if not already loaded
                    else if (_healthConnectAvailable &&
                        snapshot.hasData &&
                        snapshot.data!.data() != null) {
                      // Only update weekly total from Firestore if we haven't loaded it from Health Connect yet
                      if (_weeklyTotal == 0) {
                        weeklyTotal = snapshot.data!.data()!['weeklySteps'] ??
                            weeklyTotal;
                      }
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
                                  Icons.bug_report_rounded,
                                  color: Colors.white,
                                  size: _isLandscape(context) ? 20 : 24,
                                ),
                                onPressed: _debugHealthConnect,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: _isLandscape(context) ? 20 : 24,
                                ),
                                onPressed: _refreshStepCount,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        // Health Connect Status and Permission Button
                                        if (!_healthConnectAvailable ||
                                            _healthConnectStatus
                                                .contains('Error') ||
                                            _healthConnectStatus
                                                .contains('not granted'))
                                          _buildHealthConnectStatusCard(
                                              context, cardPadding),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .padding
                                                  .bottom +
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
          // Data source indicator
          if (_healthConnectAvailable)
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF6e9277).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF6e9277).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    color: Color(0xFF6e9277),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Health Connect',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6e9277),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
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
                _calculateTimeActive(steps),
                context,
              ),
              _buildInfoBox(
                Icons.local_fire_department_outlined,
                'Calories',
                '${_calculateCalories(steps)}',
                context,
              ),
              _buildInfoBox(
                Icons.straighten_outlined,
                'Distance',
                _formatDistance(_calculateDistance(steps)),
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
          // Data source indicator for weekly
          if (_healthConnectAvailable)
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF6e9277).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF6e9277).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    color: Color(0xFF6e9277),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Health Connect',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6e9277),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
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

  Widget _buildHealthConnectStatusCard(
      BuildContext context, double cardPadding) {
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
                'Health Connect Status',
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
                  Icons.health_and_safety_outlined,
                  color: Color(0xFF6e9277),
                  size: _isLandscape(context) ? 20 : 24,
                ),
              ),
            ],
          ),
          SizedBox(height: _isLandscape(context) ? 16 : 24),
          Text(
            _healthConnectStatus,
            style: TextStyle(
              fontSize: _getFontSize(context, small: 14, medium: 15, large: 16),
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'Poppins',
            ),
          ),
          if (_healthConnectAvailable && _lastUpdated != null) ...[
            SizedBox(height: 8),
            Text(
              'Last updated: ${_formatLastUpdated(_lastUpdated)}',
              style: TextStyle(
                fontSize:
                    _getFontSize(context, small: 12, medium: 13, large: 14),
                color: Color(0xFF6e9277),
                fontFamily: 'Poppins',
              ),
            ),
          ],
          SizedBox(height: _isLandscape(context) ? 16 : 24),
          ElevatedButton(
            onPressed: _requestPermissions,
            child: Text(
              'Request Permissions',
              style: TextStyle(
                fontSize:
                    _getFontSize(context, small: 14, medium: 15, large: 16),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6e9277),
              padding: EdgeInsets.symmetric(
                horizontal: _isLandscape(context) ? 20 : 24,
                vertical: _isLandscape(context) ? 12 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
