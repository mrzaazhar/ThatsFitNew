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

  // Responsive helper methods
  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  bool _isMediumScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;
  bool _isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  double _getCardPadding(BuildContext context) {
    if (_isSmallScreen(context)) return 16.0;
    if (_isMediumScreen(context)) return 24.0;
    return 32.0;
  }

  double _getFontSize(BuildContext context,
      {required double small, required double medium, required double large}) {
    if (_isSmallScreen(context)) return small;
    if (_isMediumScreen(context)) return medium;
    return large;
  }

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
      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .where('workoutType', isEqualTo: 'favorite_exercise')
            .orderBy('savedAt', descending: true)
            .get();

        setState(() {
          _savedWorkouts = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading saved workouts: $e');
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

        // Remove from local list
        setState(() {
          _savedWorkouts.removeWhere((workout) => workout['id'] == workoutId);
        });

        _showSnackBar('Workout removed from favorites', Colors.green);
      }
    } catch (e) {
      print('Error deleting workout: $e');
      _showSnackBar('Failed to remove workout', Colors.red);
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Saved Workouts',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF6e9277),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSavedWorkouts,
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
          SizedBox(height: 16),
          Text(
            'Loading your saved workouts...',
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
        padding: EdgeInsets.all(_getCardPadding(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
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
            SizedBox(height: 24),
            Text(
              'No Saved Workouts Yet',
              style: TextStyle(
                fontSize:
                    _getFontSize(context, small: 24, medium: 28, large: 32),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Swipe right on exercises in your workout plans to save them here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize:
                    _getFontSize(context, small: 16, medium: 18, large: 20),
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
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(_getCardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF6e9277).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.favorite,
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
                        'Your Favorite Exercises',
                        style: TextStyle(
                          fontSize: _getFontSize(context,
                              small: 20, medium: 24, large: 28),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        '${_savedWorkouts.length} saved exercises',
                        style: TextStyle(
                          fontSize: _getFontSize(context,
                              small: 14, medium: 16, large: 18),
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Workouts grid/list
            _isLargeScreen(context)
                ? _buildWorkoutsGrid()
                : _buildWorkoutsColumn(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _savedWorkouts.length,
      itemBuilder: (context, index) {
        return _buildWorkoutCard(_savedWorkouts[index], context);
      },
    );
  }

  Widget _buildWorkoutsColumn() {
    return Column(
      children: _savedWorkouts.map((workout) {
        return _buildWorkoutCard(workout, context);
      }).toList(),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: _isSmallScreen(context) ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with delete button
          Container(
            padding: EdgeInsets.all(_isSmallScreen(context) ? 16 : 20),
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
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF6e9277),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout['exerciseName'] ?? 'Unknown Exercise',
                        style: TextStyle(
                          fontSize: _getFontSize(context,
                              small: 16, medium: 18, large: 20),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Saved on ${_formatDate(workout['savedAt'])}',
                        style: TextStyle(
                          fontSize: _getFontSize(context,
                              small: 12, medium: 13, large: 14),
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
                ),
              ],
            ),
          ),

          // Exercise details
          Padding(
            padding: EdgeInsets.all(_isSmallScreen(context) ? 16 : 20),
            child: Column(
              children: [
                _buildWorkoutDetail(
                  Icons.repeat,
                  'Sets & Reps',
                  workout['setsAndReps'] ?? 'N/A',
                  context,
                ),
                SizedBox(height: 12),
                _buildWorkoutDetail(
                  Icons.timer,
                  'Rest Period',
                  workout['restPeriod'] ?? 'N/A',
                  context,
                ),
                SizedBox(height: 12),
                _buildWorkoutDetail(
                  Icons.info_outline,
                  'Form Tips',
                  workout['formTips'] ?? 'N/A',
                  context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutDetail(
      IconData icon, String label, String value, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFF6e9277).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: _isSmallScreen(context) ? 16 : 18,
            color: Color(0xFF6e9277),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize:
                      _getFontSize(context, small: 12, medium: 13, large: 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize:
                      _getFontSize(context, small: 14, medium: 15, large: 16),
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
}
