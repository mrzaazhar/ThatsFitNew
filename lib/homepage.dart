import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'dart:async';
import 'profile_page.dart';
import 'main.dart';
import 'step_count.dart';
import 'workout.dart';
import 'widgets/create_workout_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Track the selected index
  int _current = 0; // Track current carousel page
  int _currentSteps = 0;
  final int dailyGoal = 10000;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _lastMagnitude = 0;
  double _threshold = 12.0; // Adjust this threshold based on testing
  bool _isStep = false;
  DateTime? _lastStepTime;

  // List of widgets for each tab
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _initAccelerometer();
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
            _lastStepTime = DateTime.now();
          });
        }
      }

      _lastMagnitude = magnitude;
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
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
    return Scaffold(
      backgroundColor: Color(0xFF008000), // Background color
      appBar: AppBar(
        title: Text(
          'ThatsFit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFamily: 'DM Sans',
          ),
        ),
        backgroundColor: Color(0xFF008000),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _initAccelerometer,
          ),
          IconButton(
            icon: Icon(Icons.person, size: 40),
            onPressed: () {
              // Handle user profile action
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Step Count Section
            Column(
              children: [
                SizedBox(height: 10),
                CarouselSlider.builder(
                  itemCount: 3,
                  options: CarouselOptions(
                    height: 160,
                    viewportFraction: 1.0,
                    enlargeCenterPage: false,
                    scrollDirection: Axis.horizontal,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _current = index;
                      });
                    },
                  ),
                  itemBuilder: (context, index, realIndex) {
                    if (index == 0) {
                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFbfbfbf),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Step Count',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                            SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: _currentSteps / dailyGoal,
                                    backgroundColor: Colors.grey,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF33443c),
                                    ),
                                    strokeWidth: 10,
                                  ),
                                ),
                                SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_currentSteps',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                    Text(
                                      'steps',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 20),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StepCountPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'View More',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF6e9277),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    } else if (index == 1) {
                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFbfbfbf),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Daily Goal',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              '7000 / 10000',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                            Text(
                              'steps',
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFbfbfbf),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Weekly Progress',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              '35,000 steps',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                            Text(
                              'Great progress!',
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 10), // Space between carousel and dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [0, 1, 2].map((index) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _current == index
                            ? Color(0xFF33443c) // Active dot color
                            : Colors.white.withOpacity(
                                0.4,
                              ), // Inactive dot color
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: 20),
            // New Container for Create Workout Button
            Container(
              padding: EdgeInsets.all(20),
              height: 400,
              width: 500,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/JPG/workout_image.jpg'),
                  fit: BoxFit.cover,
                ),
                color: Color(0xFFbfbfbf),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Center(
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
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Color(0xFF008000), // Background color of the navigation bar
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: GNav(
            gap: 8,
            color: Colors.white, // Color for unselected items
            activeColor: Colors.white, // Color for selected item
            iconSize: 24,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            duration: Duration(milliseconds: 400),
            tabBackgroundColor:
                Colors.green, // Background color for selected tab
            tabs: [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.search, text: 'Search'),
              GButton(icon: Icons.arrow_back, text: 'Back'),
              GButton(icon: Icons.logout, text: 'Logout'),
            ],
            selectedIndex: _selectedIndex, // Set the current index
            onTabChange: (index) {
              _onItemTapped(index); // Handle tab change
            },
          ),
        ),
      ),
    );
  }
}
