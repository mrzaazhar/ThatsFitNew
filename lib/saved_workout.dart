import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedWorkoutPage extends StatefulWidget {
  @override
  _SavedWorkoutPageState createState() => _SavedWorkoutPageState();
}

class _SavedWorkoutPageState extends State<SavedWorkoutPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedWorkouts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedWorkouts();
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
      backgroundColor: Color(0xFFf8f9fa),
      appBar: AppBar(
        title: Text(
          'My Favorite Exercises',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color(0xFF6e9277),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSavedWorkouts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _savedWorkouts.isEmpty
              ? _buildEmptyState()
              : _buildWorkoutsList(),
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
            'Loading your favorite exercises...',
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
                color: Color(0xFF6e9277).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 80,
                color: Color(0xFF6e9277),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'No Favorite Exercises Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Swipe left on exercises in your workout plans to save them here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back),
              label: Text('Go Back to Workouts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6e9277),
                foregroundColor: Colors.white,
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
      color: Color(0xFF6e9277),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _savedWorkouts.length,
        itemBuilder: (context, index) {
          return _buildExerciseCard(_savedWorkouts[index]);
        },
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> workout) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6e9277).withOpacity(0.1),
                  Color(0xFF6e9277).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF6e9277),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout['exerciseName'] ?? 'Unknown Exercise',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Saved on ${_formatDate(workout['savedAt'])}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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
                    color: Colors.red[400],
                    size: 24,
                  ),
                  tooltip: 'Remove from favorites',
                ),
                IconButton(
                  onPressed: () =>
                      _openVideoPlayer(workout['exerciseName'] ?? 'Exercise'),
                  icon: Icon(
                    Icons.play_circle_outline,
                    color: Color(0xFF6e9277),
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
            color: Color(0xFF6e9277).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Color(0xFF6e9277),
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
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
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
    // Implementation of _openVideoPlayer method
  }
}
