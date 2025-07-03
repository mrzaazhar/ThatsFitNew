import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'profile_page.dart';
import 'main.dart';
import 'step_count.dart';
import 'workout.dart';
import 'saved_workout.dart';
import 'widgets/create_workout_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'services/health_connect_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Track the selected index
  int _current = 0; // Track current carousel page
  final int dailyGoal = 10000;
  late HealthConnectService _healthConnectService;
  DateTime? _lastResetDate;
  int _currentSteps = 0; // Add this to track current steps
  bool _isLoadingSteps = true; // Add loading state

  // List of widgets for each tab
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _healthConnectService = HealthConnectService();
    _checkAndResetDailySteps().then((_) {
      _loadInitialSteps(); // Load initial steps from Firebase
      _initHealthConnect();
    });
    _widgetOptions = <Widget>[
      Text('Home Screen'), // Replace with your Home widget
      Text('Search Screen'), // Replace with your Search widget
      Text('Back Screen'), // Replace with your Back widget
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Are you sure you want to logout?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'DM Sans',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to login page and clear navigation stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'DM Sans',
                  fontSize: 20,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6e9277),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    ];
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
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    final screenWidth = MediaQuery.of(context).size.width;

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
                      // Step Count Card
                      Card(
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
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
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
                                                backgroundColor:
                                                    Colors.grey[800],
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Color(0xFF6e9277),
                                                ),
                                                strokeWidth: 8,
                                              ),
                                            );
                                          },
                                        ),
                                  SizedBox(width: 18),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      side:
                                          BorderSide(color: Color(0xFF6e9277)),
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
                      // Create Workout Card
                      Card(
                        color: Colors.white,
                        elevation: 7,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            maxWidth: 500,
                            minHeight: 180,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            image: DecorationImage(
                              image: AssetImage('assets/JPG/Gym.jpg'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.18),
                                BlendMode.darken,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(24),
                            alignment: Alignment.bottomCenter,
                            child: CreateWorkoutButton(
                              userId: userId ?? '',
                              onWorkoutCreated: (result) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WorkoutPage(
                                      suggestedWorkout: result['workoutPlan'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      // Set Weekly Goals Card
                      Card(
                        color: Colors.white,
                        elevation: 7,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            maxWidth: 500,
                            minHeight: 180,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            image: DecorationImage(
                              image: AssetImage('assets/JPG/workout_image.jpg'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.18),
                                BlendMode.darken,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(24),
                            alignment: Alignment.bottomCenter,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Navigate to weekly goals page
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => WeeklyGoalsPage(),
                                //   ),
                                // );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 124, 49, 164),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.flag,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Set Your Weekly Goals',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      // Saved Workouts Card
                      Card(
                        color: Color.fromARGB(133, 165, 72, 198),
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
              GButton(icon: Icons.search, text: 'Search'),
              GButton(icon: Icons.arrow_back, text: 'Back'),
              GButton(icon: Icons.logout, text: 'Logout'),
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

          setState(() {
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
}
