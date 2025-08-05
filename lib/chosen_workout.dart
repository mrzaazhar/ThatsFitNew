import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'widgets/workout_video_player.dart';
import 'services/youtube_service.dart';
import 'services/workout_recording_service.dart';
import 'homepage.dart';

class ChosenWorkoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> chosenExercises;

  const ChosenWorkoutPage({Key? key, required this.chosenExercises})
      : super(key: key);

  @override
  _ChosenWorkoutPageState createState() => _ChosenWorkoutPageState();
}

class _ChosenWorkoutPageState extends State<ChosenWorkoutPage> {
  Set<int> _completedExercises = <int>{};
  bool _isWorkoutStarted = false;

  // Responsive helper methods

  double _getFontSize(BuildContext context,
      {required double small, required double medium, required double large}) {
    if (MediaQuery.of(context).size.width < 600) return small;
    if (MediaQuery.of(context).size.width < 900) return medium;
    return large;
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completedExercises.length;
    final totalCount = widget.chosenExercises.length;
    final progressPercentage =
        totalCount > 0 ? (completedCount / totalCount) : 0.0;

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
              // Header Section
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
                    Expanded(
                      child: Text(
                        'Your Chosen Workout',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    // Clear All Button
                    if (widget.chosenExercises.isNotEmpty)
                      TextButton(
                        onPressed: _showClearAllDialog,
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Progress Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Workout Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          '$completedCount/$totalCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6e9277),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progressPercentage,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF6e9277)),
                      minHeight: 8,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${(progressPercentage * 100).toInt()}% Complete',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: widget.chosenExercises.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Start Workout Button
                            if (!_isWorkoutStarted &&
                                completedCount < totalCount)
                              Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isWorkoutStarted = true;
                                    });
                                    _showWorkoutStartedDialog();
                                  },
                                  icon: Icon(Icons.play_arrow, size: 24),
                                  label: Text(
                                    'Start Workout Session',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF6e9277),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),

                            // Complete Workout Button (always visible once workout is started)
                            if (_isWorkoutStarted)
                              Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    // Show completion status when all exercises are done
                                    if (completedCount == totalCount)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 12),
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF6e9277)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Color(0xFF6e9277),
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.celebration,
                                              color: Color(0xFF6e9277),
                                              size: 24,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'All exercises completed! 🎉',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Main action button - ALWAYS visible when workout started
                                    ElevatedButton.icon(
                                      onPressed: _completeWorkoutAndGoHome,
                                      icon: Icon(
                                          completedCount == totalCount
                                              ? Icons.home
                                              : Icons.check_circle,
                                          size: 24),
                                      label: Text(
                                        completedCount == totalCount
                                            ? 'Finish & Go Home'
                                            : 'Complete Workout Session',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            completedCount == totalCount
                                                ? Color(0xFF6e9277)
                                                : Colors.green[600],
                                        foregroundColor: Colors.white,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: completedCount == totalCount
                                            ? 8
                                            : 4,
                                        shadowColor: completedCount ==
                                                totalCount
                                            ? Color(0xFF6e9277).withOpacity(0.5)
                                            : Colors.green.withOpacity(0.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Exercises List
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF6e9277)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.fitness_center,
                                          color: Color(0xFF6e9277),
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Your Exercises (${widget.chosenExercises.length})',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  ...widget.chosenExercises
                                      .asMap()
                                      .entries
                                      .map((entry) => _buildExerciseCard(
                                          entry.value, context, entry.key))
                                      .toList(),
                                ],
                              ),
                            ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.4),
            ),
            SizedBox(height: 16),
            Text(
              'No exercises chosen yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Go back and select exercises from the workout options',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
      Map<String, dynamic> exercise, BuildContext context, int exerciseIndex) {
    final exerciseName = exercise['name'] ?? 'Exercise';
    final isCompleted = _completedExercises.contains(exerciseIndex);
    final videoId = exercise['videoId'] ??
        exercise['details']?['videoId'] ??
        YouTubeService.getVideoId(exerciseName);

    return GestureDetector(
      onDoubleTap: () => _saveExerciseToFavorites(exercise),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isCompleted
              ? Color(0xFF6e9277).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isCompleted ? Color(0xFF6e9277) : Colors.white.withOpacity(0.1),
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exerciseName,
                      style: TextStyle(
                        fontSize: _getFontSize(context,
                            small: 16, medium: 18, large: 20),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  // Complete/Undo Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isCompleted) {
                          _completedExercises.remove(exerciseIndex);
                        } else {
                          _completedExercises.add(exerciseIndex);
                        }
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.2)
                            : Color(0xFF6e9277).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isCompleted ? Colors.green : Color(0xFF6e9277),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Video Thumbnail (if available)
              if (videoId != null && videoId != 'dQw4w9WgXcQ')
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: _buildVideoThumbnail(videoId, exerciseName, context),
                ),

              // Exercise Details
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
              if (exercise['workoutType'] != null) ...[
                SizedBox(height: 12),
                _buildExerciseDetail(
                  Icons.category,
                  'Workout Type',
                  exercise['workoutType'],
                  context,
                ),
              ],
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
        height: 140,
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
            size: 16,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
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

  // Function to save exercise to Firebase favorites (Instagram-like double-tap)
  Future<void> _saveExerciseToFavorites(Map<String, dynamic> exercise) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Please sign in to save exercises', Colors.red);
        return;
      }

      // Create a unique workout ID
      final workoutId = DateTime.now().millisecondsSinceEpoch.toString();

      // Prepare data to save
      final workoutData = {
        'exerciseName': exercise['name'] ?? 'Unknown Exercise',
        'setsAndReps': exercise['details']?['setsAndReps'] ?? 'N/A',
        'restPeriod': exercise['details']?['restPeriod'] ?? 'N/A',
        'formTips': exercise['details']?['formTips'] ?? 'N/A',
        'savedAt': FieldValue.serverTimestamp(),
        'workoutType': 'favorite_exercise',
        'source': 'chosen_workout',
        'videoId': exercise['videoId'],
      };

      // Save exercise to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(workoutId)
          .set(workoutData);

      // Show animated heart feedback (Instagram style)
      _showHeartAnimation();
      _showSnackBar('Exercise saved to favorites! 💪', Colors.green);

      // Add haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Error saving exercise: $e');
      _showSnackBar('Failed to save exercise. Please try again.', Colors.red);
    }
  }

  // Instagram-like heart animation
  void _showHeartAnimation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: 1.0 - value,
                child: Icon(
                  Icons.favorite,
                  size: 80,
                  color: Colors.red,
                ),
              ),
            );
          },
          onEnd: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
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

  Future<void> _showClearAllDialog() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenWidth * 0.9 : 400,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 24,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Section
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.red[400],
                        size: isSmallScreen ? 20 : 24,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Clear All Exercises',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: isSmallScreen ? 16 : 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),

                  // Content Section
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        'Are you sure you want to clear all chosen exercises? This action cannot be undone.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmallScreen ? 14 : 16,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Actions Section
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'Poppins',
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldClear == true) {
      await _clearAllExercises();
    }
  }

  Future<void> _clearAllExercises() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('chosen_workouts')
            .doc('current_selection')
            .delete();
      }
      Navigator.pop(context);
    } catch (e) {
      print('Error clearing exercises: $e');
    }
  }

  void _showWorkoutStartedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenWidth * 0.9 : 400,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 24,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Section
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_filled,
                        color: Color(0xFF6e9277),
                        size: isSmallScreen ? 20 : 24,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Workout Started!',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: isSmallScreen ? 16 : 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),

                  // Content Section
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        'Your workout session has begun! Mark exercises as completed when you finish them.\n\nTip: Double-tap any exercise to save it to your favorites!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmallScreen ? 14 : 16,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6e9277),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Got it!',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeWorkoutAndGoHome() async {
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenWidth * 0.9 : 400,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 24,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Section
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Complete Workout',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: isSmallScreen ? 16 : 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),

                  // Content Section
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        'Mark all remaining exercises as complete and finish your workout session? You\'ll be redirected to the home page.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmallScreen ? 14 : 16,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Actions Section
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'Poppins',
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldComplete == true) {
      await _completeAllExercises();
      // Navigate back to homepage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }

  Future<void> _completeAllExercises() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Please sign in to save workout', Colors.red);
        return;
      }

      // Mark all exercises as completed locally
      setState(() {
        for (int i = 0; i < widget.chosenExercises.length; i++) {
          _completedExercises.add(i);
        }
      });

      // Calculate workout duration (estimated 2-3 minutes per exercise)
      final estimatedDuration = (widget.chosenExercises.length * 2.5).round();

      // Use the existing service to save workout (includes weekly progress tracking)
      await WorkoutRecordingService.recordWorkout(
        workoutName: 'Custom Chosen Workout',
        exercises: widget.chosenExercises,
        duration: estimatedDuration,
        notes:
            'Completed via chosen workout page - All ${widget.chosenExercises.length} exercises completed',
      );

      // Clear the chosen workouts from Firebase after completion
      await _clearChosenWorkoutsFromFirebase();

      HapticFeedback.mediumImpact();
      print(
          '✅ Workout saved to workout_history: ${widget.chosenExercises.length} exercises completed');
    } catch (e) {
      print('❌ Error completing workout: $e');
      _showSnackBar('Failed to save workout. Please try again.', Colors.red);
    }
  }

  // Helper method to clear chosen workouts from Firebase after completion
  Future<void> _clearChosenWorkoutsFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('chosen_workouts')
            .doc('current_selection')
            .delete();
        print('✅ Cleared chosen workouts from Firebase');
      }
    } catch (e) {
      print('⚠️ Error clearing chosen workouts: $e');
      // Don't throw error as this is not critical
    }
  }
}
