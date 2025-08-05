import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'widgets/workout_video_player.dart';
import 'services/youtube_service.dart';
import 'chosen_workout.dart';

class WorkoutPage extends StatefulWidget {
  final Map<String, dynamic>? suggestedWorkout;

  const WorkoutPage({Key? key, this.suggestedWorkout}) : super(key: key);

  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Set<String> _selectedExercises = <String>{}; // Track selected exercises

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
                    Expanded(
                      child: Text(
                        'Your Workout Options',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    // View Chosen Workouts Button
                    if (_selectedExercises.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: _saveChosenWorkouts,
                          icon: Icon(Icons.playlist_add_check, size: 18),
                          label: Text(
                            'View Chosen (${_selectedExercises.length})',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6e9277),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
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
                // Checkbox to select exercise
                _buildExerciseCheckbox(exercise, context),
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

  Widget _buildExerciseCheckbox(
      Map<String, dynamic> exercise, BuildContext context) {
    final exerciseName = exercise['name'] ?? 'Exercise';
    final isSelected = _selectedExercises.contains(exerciseName);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected
            ? Color(0xFF6e9277).withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Color(0xFF6e9277) : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Checkbox(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _selectedExercises.add(exerciseName);
            } else {
              _selectedExercises.remove(exerciseName);
            }
          });
        },
        activeColor: Color(0xFF6e9277),
        checkColor: Colors.white,
        side: BorderSide.none,
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

  // Function to save chosen workouts and navigate to chosen workout page
  Future<void> _saveChosenWorkouts() async {
    if (_selectedExercises.isEmpty) {
      _showSnackBar('No exercises selected', Colors.orange);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Please sign in to save chosen workouts', Colors.red);
        return;
      }

      // Get all workout options to find selected exercises
      final workoutOptions = widget.suggestedWorkout!['workoutOptions'] ?? [];
      List<Map<String, dynamic>> chosenExercises = [];

      // Find all selected exercises from all workout options
      for (var workout in workoutOptions) {
        final exercises = workout['exercises'] ?? [];
        for (var exercise in exercises) {
          if (_selectedExercises.contains(exercise['name'])) {
            chosenExercises.add({
              'name': exercise['name'],
              'details': exercise['details'],
              'videoId': exercise['videoId'],
              'workoutType': workout['name'],
            });
          }
        }
      }

      // Save chosen workouts to Firebase
      final chosenWorkoutData = {
        'exercises': chosenExercises,
        'createdAt': FieldValue.serverTimestamp(),
        'totalExercises': chosenExercises.length,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chosen_workouts')
          .doc('current_selection')
          .set(chosenWorkoutData);

      _showSnackBar('Chosen workouts saved! 💪', Colors.green);

      // Navigate to chosen workout page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChosenWorkoutPage(
            chosenExercises: chosenExercises,
          ),
        ),
      );
    } catch (e) {
      print('Error saving chosen workouts: $e');
      _showSnackBar(
          'Failed to save chosen workouts. Please try again.', Colors.red);
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
}
