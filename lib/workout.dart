import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'widgets/workout_video_player.dart';
import 'services/youtube_service.dart';

class WorkoutPage extends StatefulWidget {
  final Map<String, dynamic>? suggestedWorkout;

  const WorkoutPage({Key? key, this.suggestedWorkout}) : super(key: key);

  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedWorkoutIndex = 0;

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
    // Initialize tab controller based on workout options
    final workoutOptions = widget.suggestedWorkout?['workoutOptions'] ?? [];
    _tabController = TabController(
      length: workoutOptions.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Debug print to see what data we're receiving
    print('Suggested Workout Data: ${widget.suggestedWorkout}');

    if (widget.suggestedWorkout == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Workout Plan'),
          backgroundColor: Color(0xFF6e9277),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No workout data available',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // The workout data structure has changed to include workoutOptions
    final summary = widget.suggestedWorkout!['summary'] ??
        {
          'title': 'Custom Workout',
          'subtitle': 'Workout Plan',
          'intensity': 'Moderate',
          'stepCount': 'N/A',
          'restPeriods': 'N/A'
        };

    final workoutOptions = widget.suggestedWorkout!['workoutOptions'] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Your Workout Options',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF6e9277),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: workoutOptions.length > 1
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      _getFontSize(context, small: 14, medium: 16, large: 18),
                ),
                tabs: workoutOptions.map<Widget>((workout) {
                  return Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(workout['name'] ?? 'Workout'),
                        SizedBox(height: 4),
                        Text(
                          '${workout['exercises']?.length ?? 0} exercises',
                          style: TextStyle(
                            fontSize: _getFontSize(context,
                                small: 10, medium: 12, large: 14),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Compact Workout Summary Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(_getCardPadding(context)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6e9277),
                    Color(0xFF5a7a63),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:
                      Radius.circular(_isSmallScreen(context) ? 20 : 30),
                  bottomRight:
                      Radius.circular(_isSmallScreen(context) ? 20 : 30),
                ),
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
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary['title'] ?? 'Workout Options',
                              style: TextStyle(
                                fontSize: _getFontSize(context,
                                    small: 20, medium: 24, large: 28),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              summary['subtitle'] ?? 'Choose Your Workout',
                              style: TextStyle(
                                fontSize: _getFontSize(context,
                                    small: 14, medium: 16, large: 18),
                                color: Colors.white.withOpacity(0.9),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.swipe_up,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Compact summary items in a single row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCompactSummaryItem(
                        Icons.fitness_center,
                        'Intensity',
                        summary['intensity'] ?? 'N/A',
                        context,
                      ),
                      _buildCompactSummaryItem(
                        Icons.directions_walk,
                        'Steps',
                        (summary['stepCount'] ?? 'N/A').toString(),
                        context,
                      ),
                      _buildCompactSummaryItem(
                        Icons.timer,
                        'Rest',
                        summary['restPeriods'] ?? 'N/A',
                        context,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Workout Options Content
            workoutOptions.length > 1
                ? Container(
                    height: MediaQuery.of(context).size.height *
                        0.7, // Limit height for TabBarView
                    child: TabBarView(
                      controller: _tabController,
                      children: workoutOptions.map<Widget>((workout) {
                        return _buildWorkoutContent(workout, context);
                      }).toList(),
                    ),
                  )
                : workoutOptions.isNotEmpty
                    ? _buildWorkoutContent(workoutOptions[0], context)
                    : _buildEmptyState(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutContent(
      Map<String, dynamic> workout, BuildContext context) {
    final exercises = workout['exercises'] ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(_getCardPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF6e9277).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Color(0xFF6e9277),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout['name'] ?? 'Workout',
                        style: TextStyle(
                          fontSize: _getFontSize(context,
                              small: 20, medium: 24, large: 28),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${exercises.length} exercises • Tap to start',
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF6e9277),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'START',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: _getFontSize(context,
                          small: 12, medium: 14, large: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Exercises List
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF6e9277).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.list_alt,
                  color: Color(0xFF6e9277),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Exercises',
                style: TextStyle(
                  fontSize:
                      _getFontSize(context, small: 20, medium: 24, large: 28),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          if (exercises.isEmpty)
            _buildEmptyState(context)
          else
            _buildExercisesList(exercises, context),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      IconData icon, String label, String value, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon,
              color: Colors.white, size: _isSmallScreen(context) ? 24 : 28),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: _getFontSize(context, small: 12, medium: 14, large: 16),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: _getFontSize(context, small: 14, medium: 16, large: 18),
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSummaryItem(
      IconData icon, String label, String value, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: Colors.white, size: _isSmallScreen(context) ? 20 : 24),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: _getFontSize(context, small: 10, medium: 12, large: 14),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: _getFontSize(context, small: 12, medium: 14, large: 16),
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No exercises available',
              style: TextStyle(
                fontSize:
                    _getFontSize(context, small: 16, medium: 18, large: 20),
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList(List exercises, BuildContext context) {
    if (_isLargeScreen(context)) {
      // Grid layout for large screens
      return GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          if (exercises[index] is Map<String, dynamic>) {
            return _buildExerciseCard(exercises[index], context);
          }
          return SizedBox.shrink();
        },
      );
    } else {
      // List layout for small and medium screens
      return Column(
        children: exercises.map((exercise) {
          if (exercise is Map<String, dynamic>) {
            return _buildExerciseCard(exercise, context);
          }
          return SizedBox.shrink();
        }).toList(),
      );
    }
  }

  Widget _buildExerciseCard(
      Map<String, dynamic> exercise, BuildContext context) {
    // Get video ID from exercise data or fallback to YouTube service
    final videoId = exercise['videoId'] ??
        exercise['details']?['videoId'] ??
        YouTubeService.getVideoId(exercise['name'] ?? 'Exercise');

    return GestureDetector(
      onPanEnd: (details) {
        // Check if the swipe was significant enough (right to left)
        if (details.velocity.pixelsPerSecond.dx < -500) {
          // Show confirmation dialog
          _showSaveConfirmationDialog(exercise, context);
        }
      },
      child: Container(
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
        child: Padding(
          padding: EdgeInsets.all(_isSmallScreen(context) ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exercise['name'] ?? 'Exercise',
                      style: TextStyle(
                        fontSize: _getFontSize(context,
                            small: 16, medium: 18, large: 20),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  // Add a hint icon
                  Icon(
                    Icons.swipe_left,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Video Thumbnail Section (if video ID is available)
              if (videoId != null &&
                  videoId != 'dQw4w9WgXcQ') // Don't show for default video
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: _buildVideoThumbnail(
                      videoId, exercise['name'] ?? 'Exercise', context),
                ),

              _buildExerciseDetail(
                Icons.repeat,
                'Sets & Reps',
                exercise['details']?['setsAndReps'] ?? 'N/A',
                context,
              ),
              SizedBox(height: 12),
              _buildExerciseDetail(
                Icons.timer,
                'Rest Period',
                exercise['details']?['restPeriod'] ?? 'N/A',
                context,
              ),
              SizedBox(height: 12),
              _buildExerciseDetail(
                Icons.info_outline,
                'Form Tips',
                exercise['details']?['formTips'] ?? 'N/A',
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(
      String videoId, String exerciseName, BuildContext context) {
    return GestureDetector(
      onTap: () => _openVideoPlayer(exerciseName, videoId: videoId),
      child: Container(
        height: _isSmallScreen(context) ? 120 : 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Video thumbnail
              Image.network(
                'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.video_library,
                          size: 48,
                          color: Colors.grey[500],
                        ),
                      );
                    },
                  );
                },
              ),
              // Play button overlay
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF6e9277).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseDetail(
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

  // Function to show save confirmation dialog
  Future<void> _showSaveConfirmationDialog(
      Map<String, dynamic> exercise, BuildContext context) async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.favorite, color: Color(0xFF6e9277)),
              SizedBox(width: 8),
              Text(
                'Save Exercise',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Save "${exercise['name'] ?? 'Exercise'}" to your favorites?',
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
                backgroundColor: Color(0xFF6e9277),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save',
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

    if (shouldSave == true) {
      // Save the exercise
      _saveExerciseToFavorites(exercise);
    }
  }

  // Function to save exercise to Firebase
  Future<void> _saveExerciseToFavorites(Map<String, dynamic> exercise) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Please sign in to save exercises', Colors.red);
        return;
      }

      print('=== Saving Exercise to Favorites ===');
      print('User ID: ${user.uid}');
      print('Exercise data: $exercise');

      // Create a unique workout ID
      final workoutId = DateTime.now().millisecondsSinceEpoch.toString();
      print('Generated workout ID: $workoutId');

      // Prepare data to save
      final workoutData = {
        'exerciseName': exercise['name'] ?? 'Unknown Exercise',
        'setsAndReps': exercise['details']?['setsAndReps'] ?? 'N/A',
        'restPeriod': exercise['details']?['restPeriod'] ?? 'N/A',
        'formTips': exercise['details']?['formTips'] ?? 'N/A',
        'savedAt': FieldValue.serverTimestamp(),
        'workoutType': 'favorite_exercise',
        'source': 'workout_plan'
      };

      print('Data to save: $workoutData');
      print('Collection path: users/${user.uid}/workouts/$workoutId');

      // Save exercise to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(workoutId)
          .set(workoutData);

      print('Exercise saved successfully to Firebase!');

      _showSnackBar('Exercise saved to favorites! 💪', Colors.green);

      // Add haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Error saving exercise: $e');
      print('Error details: ${e.toString()}');
      _showSnackBar('Failed to save exercise. Please try again.', Colors.red);
    }
  }

  // Helper function to show snackbar
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

  void _openVideoPlayer(String exerciseName, {String? videoId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutVideoPlayer(
          exerciseName: exerciseName,
          videoId: videoId,
        ),
      ),
    );
  }

  // Helper method to demonstrate how to structure exercise data with video IDs
  Map<String, dynamic> _createExerciseWithVideo({
    required String name,
    required String setsAndReps,
    required String restPeriod,
    required String formTips,
    String? videoId,
  }) {
    return {
      'name': name,
      'details': {
        'setsAndReps': setsAndReps,
        'restPeriod': restPeriod,
        'formTips': formTips,
        'videoId': videoId, // Optional: specific video ID for this exercise
      },
      'videoId': videoId, // Alternative: video ID at root level
    };
  }

  // Example of how to use the video system
  List<Map<String, dynamic>> _getExampleExercises() {
    return [
      _createExerciseWithVideo(
        name: 'Barbell Squats',
        setsAndReps: '3 sets x 8-12 reps',
        restPeriod: '2-3 minutes',
        formTips:
            'Keep chest up, knees in line with toes, go parallel or below',
        videoId: 'aclHkVaku9U', // Specific video ID for Barbell Squats
      ),
      _createExerciseWithVideo(
        name: 'Push-ups',
        setsAndReps: '3 sets x 10-15 reps',
        restPeriod: '1-2 minutes',
        formTips: 'Maintain straight body line, lower chest to ground',
        // Will use default video ID from YouTubeService
      ),
      _createExerciseWithVideo(
        name: 'Deadlift',
        setsAndReps: '3 sets x 5-8 reps',
        restPeriod: '3-4 minutes',
        formTips:
            'Keep bar close to body, hinge at hips, maintain neutral spine',
        videoId: '1XEDaV7ZZqs', // Specific video ID for Deadlift
      ),
    ];
  }
}
