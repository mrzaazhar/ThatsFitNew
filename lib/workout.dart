import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'widgets/workout_video_player.dart';
import 'services/youtube_service.dart';
import 'services/workout_recording_service.dart';

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
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            'Workout Plan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No workout data available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
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
          child: Column(
            children: [
              // Custom App Bar
              Container(
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
                      'Your Workout Options',
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
              // Tab Bar
              if (workoutOptions.length > 1)
                Container(
                  color: Colors.black,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Color(0xFF6e9277),
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.7),
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: _getFontSize(context,
                          small: 14, medium: 16, large: 18),
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
                  ),
                ),
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Compact Workout Summary Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(_getCardPadding(context)),
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        summary['subtitle'] ??
                                            'Choose Your Workout',
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
                                    color: Color(0xFF6e9277).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.swipe_up,
                                    color: Color(0xFF6e9277),
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
              ),
            ],
          ),
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
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF6e9277).withOpacity(0.2),
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
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${exercises.length} exercises • Tap to start',
                        style: TextStyle(
                          fontSize: _getFontSize(context,
                              small: 14, medium: 16, large: 18),
                          color: Colors.white.withOpacity(0.7),
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
                  child: GestureDetector(
                    onTap: () => _showWorkoutCompletionDialog(workout),
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
                  color: Color(0xFF6e9277).withOpacity(0.2),
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
                  color: Colors.white,
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
              color: Colors.white.withOpacity(0.4),
            ),
            SizedBox(height: 16),
            Text(
              'No exercises available',
              style: TextStyle(
                fontSize:
                    _getFontSize(context, small: 16, medium: 18, large: 20),
                color: Colors.white.withOpacity(0.7),
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

    return Container(
      margin: EdgeInsets.only(bottom: _isSmallScreen(context) ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                      color: Colors.white,
                    ),
                  ),
                ),
                // Hold to save button
                _buildHoldToSaveButton(exercise, context),
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
    );
  }

  Widget _buildHoldToSaveButton(
      Map<String, dynamic> exercise, BuildContext context) {
    return HoldToSaveButton(
      exercise: exercise,
      onSave: () => _saveExerciseToFavorites(exercise),
      onShowConfirmation: () => _showSaveConfirmationDialog(exercise, context),
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
            color: Color(0xFF6e9277).withOpacity(0.2),
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
                  color: Colors.white.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize:
                      _getFontSize(context, small: 14, medium: 15, large: 16),
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

  // Function to show save confirmation dialog
  Future<void> _showSaveConfirmationDialog(
      Map<String, dynamic> exercise, BuildContext context) async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1a1a1a),
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
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Text(
            'Save "${exercise['name'] ?? 'Exercise'}" to your favorites?',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
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

  /// Show workout completion dialog
  Future<void> _showWorkoutCompletionDialog(
      Map<String, dynamic> workout) async {
    final exercises = workout['exercises'] ?? [];

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF6e9277)),
            SizedBox(width: 8),
            Text(
              'Complete Workout',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Did you complete "${workout['name'] ?? 'this workout'}"?',
              style: TextStyle(
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${exercises.length} exercises • ~${(exercises.length * 2.5).round()} minutes',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 12),
            // Add weekly progress preview
            FutureBuilder<Map<String, dynamic>>(
              future: _getWeeklyProgress(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final progress = snapshot.data!;
                  final currentWorkouts = progress['completedWorkouts'] ?? 0;
                  final workoutGoal = progress['workoutGoal'] ?? 0;
                  final progressPercentage = workoutGoal > 0
                      ? ((currentWorkouts + 1) / workoutGoal * 100)
                          .clamp(0.0, 100.0)
                      : 0.0;

                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF6e9277).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Progress',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: progressPercentage / 100,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6e9277)),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '${currentWorkouts + 1}/$workoutGoal',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${progressPercentage.toInt()}% of weekly goal',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Not Yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _recordCompletedWorkout(workout);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6e9277),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Complete',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Record completed workout for weekly goals tracking
  Future<void> _recordCompletedWorkout(Map<String, dynamic> workout) async {
    try {
      final exercises = workout['exercises'] ?? [];
      final workoutName = workout['name'] ?? 'Unknown Workout';

      // Calculate estimated duration (2-3 minutes per exercise)
      final estimatedDuration = exercises.length * 2.5;

      // Record the workout
      await WorkoutRecordingService.recordWorkout(
        workoutName: workoutName,
        exercises: exercises,
        duration: estimatedDuration.round(),
        notes: 'Completed via workout plan',
      );

      // Update weekly progress and show celebration
      await _updateWeeklyProgress(workoutName, exercises.length);

      // Show completion celebration
      _showCompletionCelebration(workoutName, exercises.length);
    } catch (e) {
      print('Error recording workout: $e');
      _showSnackBar(
          'Workout completed but failed to record progress.', Colors.orange);
    }
  }

  /// Update weekly progress and check goal completion
  Future<void> _updateWeeklyProgress(
      String workoutName, int exerciseCount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get current weekly progress
      final progress = await _getWeeklyProgress();
      final currentWorkouts = progress['completedWorkouts'] ?? 0;
      final workoutGoal = progress['workoutGoal'] ?? 0;
      final newTotal = currentWorkouts + 1;

      // Check if this completes the weekly goal
      bool goalCompleted = workoutGoal > 0 && newTotal >= workoutGoal;
      bool goalExceeded = workoutGoal > 0 && newTotal > workoutGoal;

      // Show appropriate message
      if (goalCompleted && !goalExceeded) {
        _showGoalCompletionCelebration(workoutGoal);
      } else if (goalExceeded) {
        _showSnackBar(
            'Amazing! You exceeded your weekly goal! 🎉', Colors.green);
      } else {
        _showSnackBar('Workout completed! Great job! 💪', Colors.green);
      }

      // Add haptic feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Error updating weekly progress: $e');
    }
  }

  /// Get current weekly progress for display
  Future<Map<String, dynamic>> _getWeeklyProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = now.add(Duration(days: 7 - now.weekday));

      // Get completed workouts for the week
      final workoutsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workout_history')
          .where('completedAt', isGreaterThanOrEqualTo: weekStart)
          .where('completedAt', isLessThanOrEqualTo: weekEnd)
          .get();

      int completedWorkouts = workoutsSnapshot.docs.length;

      // Get weekly goals
      final goalsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Weekly_Goals')
          .doc('current_week')
          .get();

      int workoutGoal = 0;
      if (goalsDoc.exists) {
        final goalsData = goalsDoc.data()!;
        workoutGoal = goalsData['workoutGoal'] ?? 0;
      }

      return {
        'completedWorkouts': completedWorkouts,
        'workoutGoal': workoutGoal,
      };
    } catch (e) {
      print('Error getting weekly progress: $e');
      return {};
    }
  }

  /// Show completion celebration
  void _showCompletionCelebration(String workoutName, int exerciseCount) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF6e9277).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Color(0xFF6e9277),
                  size: 48,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Workout Complete!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '$workoutName',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                '$exerciseCount exercises completed',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6e9277),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show goal completion celebration
  void _showGoalCompletionCelebration(int goal) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.amber[700],
                  size: 48,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Weekly Goal Achieved! 🎉',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You completed $goal workouts this week!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Awesome!',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom widget for hold-to-save functionality
class HoldToSaveButton extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onSave;
  final VoidCallback onShowConfirmation;

  const HoldToSaveButton({
    Key? key,
    required this.exercise,
    required this.onSave,
    required this.onShowConfirmation,
  }) : super(key: key);

  @override
  _HoldToSaveButtonState createState() => _HoldToSaveButtonState();
}

class _HoldToSaveButtonState extends State<HoldToSaveButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  bool _isHolding = false;
  Timer? _holdTimer;
  static const int _holdDuration = 3000; // 3 seconds

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: _holdDuration),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    if (_isHolding) return;

    setState(() {
      _isHolding = true;
    });

    _animationController.forward();

    _holdTimer = Timer(Duration(milliseconds: _holdDuration), () {
      if (_isHolding) {
        widget.onShowConfirmation();
        _resetHold();
      }
    });
  }

  void _resetHold() {
    setState(() {
      _isHolding = false;
    });

    _animationController.reset();
    _holdTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _resetHold(),
      onTapCancel: _resetHold,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isHolding
              ? Color(0xFF6e9277).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                _isHolding ? Color(0xFF6e9277) : Colors.white.withOpacity(0.3),
            width: _isHolding ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Progress indicator
            if (_isHolding)
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _progressAnimation.value,
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF6e9277)),
                    backgroundColor: Colors.white.withOpacity(0.2),
                  );
                },
              ),
            // Icon
            Center(
              child: Icon(
                _isHolding ? Icons.favorite : Icons.favorite_border,
                color: _isHolding
                    ? Color(0xFF6e9277)
                    : Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
