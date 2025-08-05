import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'profile_page.dart';
import 'step_count.dart';
import 'workout.dart';
import 'saved_workout.dart';
import 'weekly_goals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'services/health_connect_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/workout_service.dart';
import 'setup_profile.dart';
import 'workout_statistics.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Track the selected index
  final int dailyGoal = 10000;
  late HealthConnectService _healthConnectService;
  int _currentSteps = 0; // Add this to track current steps
  bool _isLoadingSteps = true; // Add loading state

  // Page controller for sliding cards
  PageController _cardPageController = PageController();
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _healthConnectService = HealthConnectService();
    _checkAndResetDailySteps().then((_) {
      _loadInitialSteps(); // Load initial steps from Firebase
      _initHealthConnect();
    });

    // Check profile completion on app start
    _checkProfileCompletion();
  }

  // Add method to load initial steps from Firebase
  Future<void> _loadInitialSteps() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the profile document from the profile subcollection
        final profileSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .limit(1)
            .get();

        if (profileSnapshot.docs.isNotEmpty) {
          final profileDoc = profileSnapshot.docs[0];
          final data = profileDoc.data();

          setState(() {
            _currentSteps = data['dailySteps'] ?? 0;
            _isLoadingSteps = false;
          });
        } else {
          setState(() {
            _isLoadingSteps = false;
          });
        }
      } else {
        setState(() {
          _isLoadingSteps = false;
        });
      }
    } catch (e) {
      print('Error loading initial steps: $e');
      setState(() {
        _isLoadingSteps = false;
      });
    }
  }

  Future<void> _initHealthConnect() async {
    try {
      final initialized = await _healthConnectService.initialize();
      if (initialized) {
        final available = await _healthConnectService.isAvailable();
        if (available) {
          await _healthConnectService.startStepCountMonitoring();
        }
      }
    } catch (e) {
      print('Error initializing Health Connect: $e');
    }
  }

  @override
  void dispose() {
    _healthConnectService.dispose();
    _cardPageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });

    // Navigate to different pages based on index
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WeeklyGoalsPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SavedWorkoutPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            // Logo
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  'assets/PNG/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'ThatsFit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: user != null
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('profile')
                    .limit(1)
                    .snapshots()
                : const Stream.empty(),
            builder: (context, firebaseSnapshot) {
              return StreamBuilder<int>(
                stream: _healthConnectService.stepCountStream,
                builder: (context, healthSnapshot) {
                  int steps = _currentSteps; // Start with Firebase data

                  // Update with Firebase data if available
                  if (firebaseSnapshot.hasData &&
                      firebaseSnapshot.data!.docs.isNotEmpty) {
                    final profileData = firebaseSnapshot.data!.docs[0].data();
                    steps = profileData['dailySteps'] ?? steps;
                    _currentSteps = steps;
                  }

                  // Update with Health Connect data if available (takes precedence)
                  if (healthSnapshot.hasData) {
                    steps = healthSnapshot.data!;
                    _currentSteps = steps;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Greeting
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 18),
                        child: Text(
                          'Welcome back!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Sliding Cards (Step Count & Statistics)
                      Container(
                        height: 200,
                        child: Column(
                          children: [
                            // Page Indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  height: 8,
                                  width: _currentCardIndex == 0 ? 24 : 8,
                                  decoration: BoxDecoration(
                                    color: _currentCardIndex == 0
                                        ? Color(0xFF6e9277)
                                        : Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  height: 8,
                                  width: _currentCardIndex == 1 ? 24 : 8,
                                  decoration: BoxDecoration(
                                    color: _currentCardIndex == 1
                                        ? Color(0xFF6e9277)
                                        : Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Sliding Cards
                            Expanded(
                              child: PageView(
                                controller: _cardPageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentCardIndex = index;
                                  });
                                },
                                children: [
                                  // Step Count Card
                                  _buildStepCountCard(steps),
                                  // Statistics Card
                                  _buildStatisticsCard(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18),
                      // Daily Goal & Weekly Progress Cards
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Color(0xFF33443c),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 18, horizontal: 10),
                                child: Column(
                                  children: [
                                    Text(
                                      'Daily Goal',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '${steps.clamp(0, dailyGoal)} / $dailyGoal',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              color: Color(0xFF33443c),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 18, horizontal: 10),
                                child: Column(
                                  children: [
                                    Text(
                                      'Weekly Progress',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    StreamBuilder<
                                        QuerySnapshot<Map<String, dynamic>>>(
                                      stream: user != null
                                          ? FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(user.uid)
                                              .collection('profile')
                                              .limit(1)
                                              .snapshots()
                                          : const Stream.empty(),
                                      builder: (context, snapshot) {
                                        int weeklySteps = 0;

                                        if (snapshot.hasData &&
                                            snapshot.data!.docs.isNotEmpty) {
                                          final profileData =
                                              snapshot.data!.docs[0].data();
                                          weeklySteps =
                                              profileData['weeklySteps'] ?? 0;
                                        }

                                        return Text(
                                          '${weeklySteps.toString()} steps',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'Inter',
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 22),
                      // Generate Workout Card
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: 500,
                          minHeight: 160,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Background Image
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage('assets/JPG/Gym.jpg'),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.3),
                                        BlendMode.darken,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  // Left side - Text content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Generate',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          'Workout',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'AI-powered plans',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Right side - Modern Button
                                  Container(
                                    width: 120,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        // Show a modern loading dialog
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            return Dialog(
                                              backgroundColor:
                                                  Colors.transparent,
                                              child: Container(
                                                padding: EdgeInsets.all(24),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF1a1a1a),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Color(0xFF6e9277),
                                                      ),
                                                    ),
                                                    SizedBox(height: 16),
                                                    Text(
                                                      'Generating your workout...',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );

                                        try {
                                          // Get current user
                                          final user =
                                              FirebaseAuth.instance.currentUser;
                                          if (user == null) {
                                            Navigator.pop(
                                                context); // Close loading dialog
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Please log in to generate workouts'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          // Create workout service instance
                                          final workoutService =
                                              WorkoutService();

                                          // Call backend to generate workout
                                          final workoutData =
                                              await workoutService
                                                  .createWorkout(
                                            userId: user.uid,
                                          );

                                          // Close loading dialog
                                          Navigator.pop(context);

                                          // Extract the workoutPlan from the response
                                          final workoutPlan =
                                              workoutData['workoutPlan'];

                                          // Navigate to workout page with generated data
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => WorkoutPage(
                                                suggestedWorkout: workoutPlan,
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          // Close loading dialog
                                          Navigator.pop(context);

                                          // Show error message
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Failed to generate workout: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Start',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18),
                      // Set Weekly Goals Card
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: 500,
                          minHeight: 160,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Background Image
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                          'assets/JPG/workout_image.jpg'),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.3),
                                        BlendMode.darken,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  // Left side - Text content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Set Your',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          'Weekly Goals',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Plan your workout schedule',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Right side - Modern Button
                                  Container(
                                    width: 120,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                WeeklyGoalsPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Plan',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18),
                      // Saved Workouts Card
                      Card(
                        color: Color(0xFF33443c),
                        elevation: 7,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SavedWorkoutPage(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              maxWidth: 500,
                              minHeight: 120,
                            ),
                            padding: EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Saved Workouts',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'View your favorite exercises',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.9),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: GNav(
            gap: 8,
            color: Colors.white,
            activeColor: Colors.white,
            iconSize: 24,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            duration: Duration(milliseconds: 400),
            tabBackgroundColor: Color(0xFF6e9277),
            tabs: [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.calendar_today, text: 'Goals'),
              GButton(icon: Icons.favorite, text: 'Saved'),
              GButton(icon: Icons.person, text: 'Profile'),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              _onItemTapped(index);
            },
          ),
        ),
      ),
    );
  }

  // Build Step Count Card
  Widget _buildStepCountCard(int steps) {
    return Card(
      color: Color(0xFF232323),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Text(
              'Step Count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoadingSteps
                    ? SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6e9277),
                          ),
                          strokeWidth: 8,
                        ),
                      )
                    : TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: steps / dailyGoal,
                        ),
                        duration: Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return SizedBox(
                            width: 70,
                            height: 70,
                            child: CircularProgressIndicator(
                              value: value,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF6e9277),
                              ),
                              strokeWidth: 8,
                            ),
                          );
                        },
                      ),
                SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoadingSteps ? '...' : '$steps',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'steps',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 18),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF6e9277)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StepCountPage(),
                      ),
                    );
                    // Refresh steps when returning from step count page
                    _loadInitialSteps();
                  },
                  child: Text(
                    'View More',
                    style: TextStyle(
                      color: Color(0xFF6e9277),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build Statistics Card
  Widget _buildStatisticsCard() {
    return Card(
      color: Color(0xFF232323),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutHistoryPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              Text(
                'Workout Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF6e9277).withOpacity(0.2),
                      border: Border.all(
                        color: Color(0xFF6e9277),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: Color(0xFF6e9277),
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Body Parts',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          'tracked',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.6),
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkAndResetDailySteps() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get the profile document from the profile subcollection
      final profileSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .limit(1)
          .get();

      if (profileSnapshot.docs.isNotEmpty) {
        final profileDoc = profileSnapshot.docs[0];
        final data = profileDoc.data();
        final lastResetDate = (data['lastResetDate'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        if (lastResetDate == null ||
            lastResetDate.year != now.year ||
            lastResetDate.month != now.month ||
            lastResetDate.day != now.day) {
          final currentWeeklyTotal = data['weeklySteps'] ?? 0;

          await profileDoc.reference.update({
            'dailySteps': 0,
            'lastResetDate': FieldValue.serverTimestamp(),
            'weeklySteps': currentWeeklyTotal,
          });
        }
      }
    }
  }

  // Check if user has completed profile setup
  Future<void> _checkProfileCompletion() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() ?? {};
          final profileCompleted = userData['profileCompleted'] ?? false;

          if (!profileCompleted && mounted) {
            // Show dialog to complete profile setup
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Complete Your Profile'),
                  content: Text(
                      'Please complete your profile setup to use all features of the app.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SetupProfilePage()),
                        );
                      },
                      child: Text('Complete Profile'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Later'),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    } catch (e) {
      print('Error checking profile completion: $e');
    }
  }
}
