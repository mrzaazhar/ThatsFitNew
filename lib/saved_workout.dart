import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/workout_video_player.dart';

class SavedWorkoutPage extends StatefulWidget {
  @override
  _SavedWorkoutPageState createState() => _SavedWorkoutPageState();
}

class _SavedWorkoutPageState extends State<SavedWorkoutPage>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedWorkouts = [];

  // Controllers for custom routine creation
  final TextEditingController _routineNameController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _restTimeController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Theme colors
  static const Color primaryGreen = Color(0xFF00FF88);
  static const Color darkGreen = Color(0xFF00CC6A);
  static const Color backgroundColor = Color(0xFF0A0A0A);
  static const Color surfaceColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedWorkouts();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _routineNameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restTimeController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedWorkouts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      print('=== Loading Saved Workouts ===');
      print('Current user: ${user?.uid}');

      if (user != null) {
        print('Querying Firebase for saved workouts...');

        // First, let's check if any workouts exist at all
        final allWorkoutsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .get();

        print(
            'Total workouts in collection: ${allWorkoutsSnapshot.docs.length}');
        if (allWorkoutsSnapshot.docs.isNotEmpty) {
          print('All workouts data:');
          for (var doc in allWorkoutsSnapshot.docs) {
            print('  Document ${doc.id}: ${doc.data()}');
          }
        }

        // Now try to get favorite exercises
        QuerySnapshot snapshot;
        try {
          snapshot = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('workouts')
              .where('workoutType', isEqualTo: 'favorite_exercise')
              .get();
        } catch (e) {
          print('Filtered query failed, getting all workouts: $e');
          // If the filtered query fails, get all workouts and filter manually
          snapshot = allWorkoutsSnapshot;
        }

        print('Firebase query completed');
        print('Number of documents found: ${snapshot.docs.length}');

        List<Map<String, dynamic>> workouts = [];

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('Processing document ${doc.id}: $data');

          // If we got all workouts, filter for favorite_exercise manually
          if (snapshot == allWorkoutsSnapshot) {
            if (data['workoutType'] == 'favorite_exercise') {
              workouts.add({
                'id': doc.id,
                ...data,
              });
            }
          } else {
            workouts.add({
              'id': doc.id,
              ...data,
            });
          }
        }

        setState(() {
          _savedWorkouts = workouts;
          _isLoading = false;
        });

        print('Final saved workouts list length: ${_savedWorkouts.length}');
      } else {
        print('No user logged in');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading saved workouts: $e');
      print('Error details: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteWorkout(String workoutId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .doc(workoutId)
            .delete();

        setState(() {
          _savedWorkouts.removeWhere((workout) => workout['id'] == workoutId);
        });

        _showSnackBar('Exercise removed from favorites', Colors.green);
      }
    } catch (e) {
      print('Error deleting workout: $e');
      _showSnackBar('Failed to remove exercise', Colors.red);
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

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      body: Column(
        children: [
          // Custom App Bar
          Container(
            padding: EdgeInsets.only(top: 24),
            child: Container(
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
                    'My Favorite Exercises',
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
          ),
          // Main Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _savedWorkouts.isEmpty
                    ? _buildEmptyState()
                    : _buildWorkoutsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
          ),
          SizedBox(height: 20),
          Text(
            'Loading your favorite exercises...',
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Color(0xFF00FF88).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 80,
                color: Color(0xFF00FF88),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'No Favorite Exercises Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Swipe left on exercises in your workout plans to save them here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: Colors.black),
              label: Text('Go Back to Workouts',
                  style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00FF88),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutsList() {
    return RefreshIndicator(
      onRefresh: _loadSavedWorkouts,
      color: Color(0xFF00FF88),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _savedWorkouts.length,
        itemBuilder: (context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildExerciseCard(_savedWorkouts[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> workout) {
    return Container(
      margin: EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF2d2d2d),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (workout['exerciseName'] ?? 'Unknown Exercise')
                            .replaceAll('*', '')
                            .trim(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Saved on ${_formatDate(workout['savedAt'])}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(workout['id']),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  tooltip: 'Remove from favorites',
                ),
                IconButton(
                  onPressed: () =>
                      _openVideoPlayer(workout['exerciseName'] ?? 'Exercise'),
                  icon: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Watch Video',
                ),
              ],
            ),
          ),

          // Exercise details
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.repeat,
                  'Sets & Reps',
                  workout['setsAndReps'] ?? 'N/A',
                ),
                SizedBox(height: 16),
                _buildDetailRow(
                  Icons.timer,
                  'Rest Period',
                  workout['restPeriod'] ?? 'N/A',
                ),
                SizedBox(height: 16),
                _buildDetailRow(
                  Icons.info_outline,
                  'Form Tips',
                  workout['formTips'] ?? 'N/A',
                ),
                SizedBox(height: 20),
                // Create Custom Routine Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final setsAndReps = workout['setsAndReps'] ?? '';
                      final restPeriod = workout['restPeriod'] ?? '';
                      final setsController = TextEditingController(text: setsAndReps.split('x').first.trim());
                      final repsController = TextEditingController(text: setsAndReps.contains('x') ? setsAndReps.split('x').last.trim() : '');
                      final restController = TextEditingController(text: restPeriod.toString());

                      final result = await showDialog<Map<String, String>>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: Color(0xFF232323),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(
                              'Edit Routine',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: setsController,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Sets',
                                          labelStyle: TextStyle(color: Colors.white70),
                                          filled: true,
                                          fillColor: Color(0xFF1a1a1a),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.white24),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: repsController,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Reps',
                                          labelStyle: TextStyle(color: Colors.white70),
                                          filled: true,
                                          fillColor: Color(0xFF1a1a1a),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.white24),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                TextField(
                                  controller: restController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Rest Period (seconds)',
                                    labelStyle: TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Color(0xFF1a1a1a),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white24),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Cancel', style: TextStyle(color: Colors.white70, fontFamily: 'Poppins')),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop({
                                    'sets': setsController.text,
                                    'reps': repsController.text,
                                    'rest': restController.text,
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF234932),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text('Save', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                              ),
                            ],
                          );
                        },
                      );

                      if (result != null && result['sets'] != null && result['reps'] != null && result['rest'] != null) {
                        final newSetsAndReps = '${result['sets']}x${result['reps']}';
                        final newRest = result['rest'];
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('workouts')
                              .doc(workout['id'])
                              .update({
                            'setsAndReps': newSetsAndReps,
                            'restPeriod': newRest,
                          });
                          setState(() {
                            workout['setsAndReps'] = newSetsAndReps;
                            workout['restPeriod'] = newRest;
                          });
                        }
                      }
                    },
                    child: Text(
                      'Edit Routine',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF234932),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF00FF88).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Color(0xFF00FF88),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(String workoutId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red[400]),
              SizedBox(width: 8),
              Text(
                'Remove Exercise',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove this exercise from your favorites?',
            style: TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Remove',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      _deleteWorkout(workoutId);
    }
  }

  Future<void> _openVideoPlayer(String exerciseName) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutVideoPlayer(
          exerciseName: exerciseName,
        ),
      ),
    );
  }

  Future<void> _showCreateRoutineDialog(Map<String, dynamic> workout) async {
    // Pre-fill controllers with current workout data
    _routineNameController.text = '${workout['exerciseName']} Custom Routine';
    _setsController.text = '3'; // Default values
    _repsController.text = '12';
    _restTimeController.text = '60';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.fitness_center, color: Color(0xFF6e9277)),
                  SizedBox(width: 8),
                  Text(
                    'Create Custom Routine',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercise: ${workout['exerciseName']}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF6e9277),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _routineNameController,
                      decoration: InputDecoration(
                        labelText: 'Routine Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.edit, color: Color(0xFF6e9277)),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _setsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Sets',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon:
                                  Icon(Icons.repeat, color: Color(0xFF6e9277)),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _repsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Reps',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.fitness_center,
                                  color: Color(0xFF6e9277)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _restTimeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Rest Time (seconds)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.timer, color: Color(0xFF6e9277)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_routineNameController.text.trim().isNotEmpty &&
                        _setsController.text.trim().isNotEmpty &&
                        _repsController.text.trim().isNotEmpty &&
                        _restTimeController.text.trim().isNotEmpty) {
                      Navigator.of(context).pop({
                        'routineName': _routineNameController.text.trim(),
                        'sets': int.tryParse(_setsController.text) ?? 3,
                        'reps': int.tryParse(_repsController.text) ?? 12,
                        'restTime':
                            int.tryParse(_restTimeController.text) ?? 60,
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill in all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6e9277),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Create Routine',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _saveCustomRoutine(workout, result);
    }
  }

  Future<void> _saveCustomRoutine(
      Map<String, dynamic> workout, Map<String, dynamic> customData) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Create the custom routine data
        final routineData = {
          'routineName': customData['routineName'],
          'exerciseName': workout['exerciseName'],
          'originalExerciseId': workout['id'],
          'sets': customData['sets'],
          'reps': customData['reps'],
          'restTime': customData['restTime'],
          'formTips': workout['formTips'] ?? '',
          'workoutType': 'custom_routine',
          'createdAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
        };

        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('custom_routines')
            .add(routineData);

        _showSnackBar('Custom routine created successfully!', Colors.green);

        // Clear the controllers
        _routineNameController.clear();
        _setsController.clear();
        _repsController.clear();
        _restTimeController.clear();
      }
    } catch (e) {
      print('Error saving custom routine: $e');
      _showSnackBar('Failed to create custom routine', Colors.red);
    }
  }

  Future<void> _showCustomRoutines() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('Please log in to view custom routines', Colors.red);
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6e9277)),
          ),
        ),
      );

      // Fetch custom routines from Firestore
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('custom_routines')
          .orderBy('createdAt', descending: true)
          .get();

      // Close loading dialog
      Navigator.of(context).pop();

      final routines = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      if (routines.isEmpty) {
        _showSnackBar('No custom routines found', Colors.orange);
        return;
      }

      // Show custom routines dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.fitness_center, color: Color(0xFF6e9277)),
              SizedBox(width: 8),
              Text(
                'My Custom Routines',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF6e9277).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: Color(0xFF6e9277),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      routine['routineName'] ?? 'Unnamed Routine',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exercise: ${routine['exerciseName']}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${routine['sets']} sets × ${routine['reps']} reps • ${routine['restTime']}s rest',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                      onPressed: () =>
                          _deleteCustomRoutine(routine['id'], context),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error loading custom routines: $e');
      _showSnackBar('Failed to load custom routines', Colors.red);
    }
  }

  Future<void> _deleteCustomRoutine(
      String routineId, BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('custom_routines')
            .doc(routineId)
            .delete();

        _showSnackBar('Custom routine deleted successfully!', Colors.green);
        Navigator.of(context).pop(); // Close the dialog
        _showCustomRoutines(); // Refresh the list
      }
    } catch (e) {
      print('Error deleting custom routine: $e');
      _showSnackBar('Failed to delete custom routine', Colors.red);
    }
  }
}
