import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({Key? key}) : super(key: key);

  @override
  _WorkoutHistoryPageState createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  List<Map<String, dynamic>> _weeklyBodyPartStats = [];
  List<Map<String, dynamic>> _workoutHistory = [];
  bool _isLoading = true;

  // 3D rotation angles
  double _rotationX = 0.0;
  double _rotationY = 0.0;

  // Body part exercise mapping
  static const Map<String, List<String>> _bodyPartExercises = {
    'Chest': [
      'smith machine bench press',
      'bench press',
      'dumbell bench press',
      'dumbbell bench press',
      'seated bench press',
      'incline bench press',
      'incline dumbell press',
      'incline dumbbell press',
      'incline smith machine bench press',
      'pec fly',
      'dumbell fly',
      'dumbbell fly',
      'cable fly',
      'chest press',
      'push up',
      'pushup',
      'chest fly',
      'decline bench press'
    ],
    'Back': [
      'wide grip lat pull downs',
      'lat pull down',
      'lat pulldown',
      'v-bar pull downs',
      'v-bar pulldown',
      'wide grip cable rows',
      'cable row',
      'v-bar cable rows',
      'lying rows',
      'barbell rows',
      'dumbell rows',
      'dumbbell rows',
      'rope pull downs',
      'pull ups',
      'pullup',
      'deadlifts',
      'deadlift',
      'seated row',
      'bent over row',
      't-bar row'
    ],
    'Biceps': [
      'barbell curls',
      'barbell curl',
      'ez bar curls',
      'ez bar curl',
      'dumbell curls',
      'dumbbell curls',
      'cable bar curls',
      'seated wide grip curls',
      'hammer curls',
      'hammer curl',
      'preacher curls',
      'preacher curl',
      'preacher dumbell curls',
      'concentration curls',
      'rope hammer curls',
      'bicep curl',
      'cable curl'
    ],
    'Triceps': [
      'tricep push downs',
      'tricep pushdown',
      'tricep v-bar push downs',
      'tricep rope push downs',
      'tricep overhead extension',
      'tricep overhead rope extension',
      'dumbell tricep extensions',
      'dumbbell tricep extensions',
      'dumbell tricep single hand extensions',
      'barbell skull crushers',
      'skull crusher',
      'incline skull crushers',
      'tricep dips',
      'tricep dip',
      'close grip bench press',
      'overhead press'
    ],
    'Shoulders': [
      'barbell shoulder press',
      'shoulder press',
      'dumbell shoulder press',
      'dumbbell shoulder press',
      'barbell lateral raises',
      'lateral raise',
      'dumbell lateral raises',
      'dumbbell lateral raises',
      'cable lateral raises',
      'barbell front raises',
      'front raise',
      'dumbell front raises',
      'dumbbell front raises',
      'dumbell reverse flys',
      'reverse fly',
      'machine reverse flys',
      'rope facepulls',
      'face pull',
      'military press',
      'arnold press'
    ],
    'Legs': [
      'barbell squats',
      'squat',
      'smith machine squats',
      'hack squats',
      'dumbell squats',
      'dumbbell squats',
      'leg press',
      'leg extensions',
      'leg extension',
      'leg hamstring curls',
      'hamstring curl',
      'dumbell romanian deadlifts',
      'romanian deadlift',
      'dumbell lunges',
      'dumbbell lunges',
      'lunge',
      'leg calf raises',
      'calf raise',
      'calf raises',
      'bulgarian split squat',
      'wall sit',
      'step up'
    ],
    'Core': [
      'plank',
      'crunch',
      'sit up',
      'situp',
      'russian twist',
      'mountain climber',
      'bicycle crunch',
      'leg raise',
      'hanging leg raise',
      'ab wheel',
      'dead bug',
      'bird dog',
      'side plank'
    ],
    'Cardio': [
      'running',
      'jogging',
      'walking',
      'treadmill',
      'cycling',
      'bike',
      'elliptical',
      'rowing',
      'swimming',
      'burpee',
      'jumping jack',
      'high knees',
      'butt kicker',
      'mountain climber'
    ]
  };

  @override
  void initState() {
    super.initState();
    _loadWorkoutHistory();
  }

  @override
  Widget build(BuildContext context) {
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
              // Header
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
                        'Workout Statistics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Icon(
                      Icons.history,
                      color: Color(0xFF6e9277),
                      size: 28,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _workoutHistory.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                // Week Statistics
                                if (_weeklyBodyPartStats.isNotEmpty)
                                  _buildWeeklyStats(),

                                // Workout History List
                                _buildWorkoutHistoryList(),
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
            'Loading workout history...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'Poppins',
              fontSize: 16,
            ),
          ),
        ],
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
              Icons.history_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.4),
            ),
            SizedBox(height: 16),
            Text(
              'No workout history yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start completing workouts to see your progress here',
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

  Widget _buildWeeklyStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF6e9277).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.accessibility_new,
                  color: Color(0xFF6e9277),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'This Week\'s Training',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                // Body Diagram
                _buildBodyDiagram(),
                SizedBox(height: 20),
                // Legend
                _buildLegend(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutHistoryList() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
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
              SizedBox(width: 12),
              Text(
                'Recent Workouts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._workoutHistory
              .map((workout) => _buildWorkoutHistoryItem(workout))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildWorkoutHistoryItem(Map<String, dynamic> workout) {
    final workoutName = workout['workoutName'] ?? 'Unknown Workout';
    final completedAt = workout['completedAt'] as Timestamp?;
    final exercises = workout['exercises'] as List<dynamic>? ?? [];
    final duration = workout['duration'] ?? 0;
    final bodyPartsTrained = _getBodyPartsFromWorkout(workout);

    final dateStr = completedAt != null
        ? DateFormat('MMM dd, yyyy • HH:mm').format(completedAt.toDate())
        : 'Unknown date';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  workoutName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF6e9277).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${exercises.length} exercises',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6e9277),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Date and Duration
          Row(
            children: [
              Icon(Icons.schedule,
                  size: 16, color: Colors.white.withOpacity(0.6)),
              SizedBox(width: 4),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                  fontFamily: 'Poppins',
                ),
              ),
              if (duration > 0) ...[
                SizedBox(width: 16),
                Icon(Icons.timer,
                    size: 16, color: Colors.white.withOpacity(0.6)),
                SizedBox(width: 4),
                Text(
                  '${duration}min',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Poppins',
                  ),
                ),
              ]
            ],
          ),

          // Body Parts Trained
          if (bodyPartsTrained.isNotEmpty) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bodyPartsTrained.map((bodyPart) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getBodyPartColor(bodyPart).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getBodyPartColor(bodyPart).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    bodyPart,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getBodyPartColor(bodyPart),
                      fontFamily: 'Poppins',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // Load workout history from Firebase
  Future<void> _loadWorkoutHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get workout history
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workout_history')
          .orderBy('completedAt', descending: true)
          .limit(20)
          .get();

      final workouts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Calculate this week's body part statistics
      final weeklyStats = _calculateWeeklyBodyPartStats(workouts);

      setState(() {
        _workoutHistory = workouts;
        _weeklyBodyPartStats = weeklyStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading workout history: $e');
      setState(() => _isLoading = false);
    }
  }

  // Calculate weekly body part training statistics
  List<Map<String, dynamic>> _calculateWeeklyBodyPartStats(
      List<Map<String, dynamic>> workouts) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));

    // Filter workouts from this week
    final thisWeekWorkouts = workouts.where((workout) {
      final completedAt = workout['completedAt'] as Timestamp?;
      if (completedAt == null) return false;

      final date = completedAt.toDate();
      return date.isAfter(weekStart.subtract(Duration(days: 1))) &&
          date.isBefore(weekEnd.add(Duration(days: 1)));
    }).toList();

    // Count exercises by body part
    final Map<String, int> bodyPartCounts = {};
    int totalExercises = 0;

    for (final workout in thisWeekWorkouts) {
      final exercises = workout['exercises'] as List<dynamic>? ?? [];
      for (final exercise in exercises) {
        final exerciseName = exercise['name']?.toString().toLowerCase() ?? '';
        final bodyPart = _getBodyPartFromExercise(exerciseName);

        if (bodyPart != null) {
          bodyPartCounts[bodyPart] = (bodyPartCounts[bodyPart] ?? 0) + 1;
          totalExercises++;
        }
      }
    }

    // Convert to percentages and sort
    final stats = bodyPartCounts.entries.map((entry) {
      final percentage =
          totalExercises > 0 ? (entry.value / totalExercises) * 100 : 0.0;
      return {
        'bodyPart': entry.key,
        'count': entry.value,
        'percentage': percentage,
      };
    }).toList();

    stats.sort((a, b) =>
        (b['percentage'] as double).compareTo(a['percentage'] as double));
    return stats;
  }

  // Get body parts trained in a specific workout
  Set<String> _getBodyPartsFromWorkout(Map<String, dynamic> workout) {
    final exercises = workout['exercises'] as List<dynamic>? ?? [];
    final bodyParts = <String>{};

    for (final exercise in exercises) {
      final exerciseName = exercise['name']?.toString().toLowerCase() ?? '';
      final bodyPart = _getBodyPartFromExercise(exerciseName);
      if (bodyPart != null) {
        bodyParts.add(bodyPart);
      }
    }

    return bodyParts;
  }

  // Map exercise name to body part
  String? _getBodyPartFromExercise(String exerciseName) {
    final lowerCaseName = exerciseName.toLowerCase().trim();

    for (final entry in _bodyPartExercises.entries) {
      final bodyPart = entry.key;
      final exercises = entry.value;

      for (final exercise in exercises) {
        if (lowerCaseName.contains(exercise.toLowerCase()) ||
            exercise.toLowerCase().contains(lowerCaseName)) {
          return bodyPart;
        }
      }
    }

    return null; // Unknown exercise
  }

  // Build 3D human body diagram
  Widget _buildBodyDiagram() {
    return Container(
      height: 350,
      child: Column(
        children: [
          // Interaction hint
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF6e9277).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app,
                  color: Color(0xFF6e9277),
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Drag to rotate • Front & Back view',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6e9277),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Exercise count legend on the left
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _weeklyBodyPartStats.map((stat) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getIntensityColor(stat['count'] as int),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${stat['bodyPart']}: ${stat['count']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(width: 20),
                // 3D Human body diagram
                Expanded(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _rotationY += details.delta.dx * 0.01;
                        _rotationX += details.delta.dy * 0.01;
                        // Limit X rotation to prevent flipping upside down
                        _rotationX = _rotationX.clamp(-0.5, 0.5);
                      });
                    },
                    child: Container(
                      height: 280,
                      child: Center(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspective
                            ..rotateX(_rotationX)
                            ..rotateY(_rotationY),
                          child: Container(
                            width: 180,
                            height: 280,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Shadow effect
                                Positioned(
                                  bottom: 5,
                                  child: Container(
                                    width: 60,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),

                                // Head
                                Positioned(
                                  top: 10,
                                  child: Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[600],
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Show different body parts based on rotation
                                if (_isShowingFront()) ..._buildFrontView(),
                                if (_isShowingBack()) ..._buildBackView(),
                                if (_isShowingSide()) ..._buildSideView(),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  // Check which view we're showing based on rotation
  bool _isShowingFront() => _rotationY.abs() < 1.2;
  bool _isShowingBack() => _rotationY.abs() > 1.8;
  bool _isShowingSide() => _rotationY.abs() >= 1.2 && _rotationY.abs() <= 1.8;

  // Build front view of body
  List<Widget> _buildFrontView() {
    return [
      // Shoulders
      Positioned(
        top: 55,
        child: Container(
          width: 110,
          height: 35,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Shoulders')),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
      // Chest
      Positioned(
        top: 85,
        child: Container(
          width: 80,
          height: 45,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Chest')),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
      // Arms (Biceps/Triceps) - Front view shows biceps
      // Left arm
      Positioned(
        top: 70,
        left: 10,
        child: Container(
          width: 30,
          height: 85,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Biceps')),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
      // Right arm
      Positioned(
        top: 70,
        right: 10,
        child: Container(
          width: 30,
          height: 85,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Biceps')),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
      // Core/Abs
      Positioned(
        top: 125,
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Core')),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
      // Legs
      // Left leg
      Positioned(
        top: 180,
        left: 60,
        child: Container(
          width: 35,
          height: 110,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Legs')),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
      // Right leg
      Positioned(
        top: 180,
        right: 60,
        child: Container(
          width: 35,
          height: 110,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Legs')),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Build back view of body
  List<Widget> _buildBackView() {
    return [
      // Shoulders (back)
      Positioned(
        top: 55,
        child: Container(
          width: 110,
          height: 35,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Shoulders')),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: Offset(-1, 2),
              ),
            ],
          ),
        ),
      ),
      // Back muscles
      Positioned(
        top: 85,
        child: Container(
          width: 90,
          height: 95,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Back')),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: Offset(-1, 2),
              ),
            ],
          ),
        ),
      ),
      // Arms (Triceps view from back)
      // Left arm
      Positioned(
        top: 70,
        left: 10,
        child: Container(
          width: 30,
          height: 85,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Triceps')),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(-1, 2),
              ),
            ],
          ),
        ),
      ),
      // Right arm
      Positioned(
        top: 70,
        right: 10,
        child: Container(
          width: 30,
          height: 85,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Triceps')),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(-1, 2),
              ),
            ],
          ),
        ),
      ),
      // Legs (back view)
      // Left leg
      Positioned(
        top: 180,
        left: 60,
        child: Container(
          width: 35,
          height: 110,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Legs')),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(-1, 2),
              ),
            ],
          ),
        ),
      ),
      // Right leg
      Positioned(
        top: 180,
        right: 60,
        child: Container(
          width: 35,
          height: 110,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Legs')),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(-1, 2),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Build side view of body (transition state)
  List<Widget> _buildSideView() {
    return [
      // Shoulders (side view)
      Positioned(
        top: 55,
        child: Container(
          width: 40,
          height: 35,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Shoulders')),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      // Side torso (combines chest/back)
      Positioned(
        top: 85,
        child: Container(
          width: 45,
          height: 95,
          decoration: BoxDecoration(
            color: _getIntensityColor(
                (_getExerciseCount('Chest') + _getExerciseCount('Back')) ~/ 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      // Arm (side view)
      Positioned(
        top: 70,
        left: _rotationY > 0 ? 5 : null,
        right: _rotationY < 0 ? 5 : null,
        child: Container(
          width: 25,
          height: 85,
          decoration: BoxDecoration(
            color: _getIntensityColor(
                (_getExerciseCount('Biceps') + _getExerciseCount('Triceps')) ~/
                    2),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      // Legs (side view)
      Positioned(
        top: 180,
        child: Container(
          width: 35,
          height: 110,
          decoration: BoxDecoration(
            color: _getIntensityColor(_getExerciseCount('Legs')),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Build legend for intensity colors
  Widget _buildLegend() {
    return Column(
      children: [
        Text(
          'No Of Exercises',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('No exercises', Colors.grey[700]!),
            _buildLegendItem('Light (1-2)', Colors.red[200]!),
            _buildLegendItem('Moderate (3-4)', Colors.red[400]!),
            _buildLegendItem('Intense (5+)', Colors.red[700]!),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Get exercise count for a specific body part
  int _getExerciseCount(String bodyPart) {
    for (final stat in _weeklyBodyPartStats) {
      if (stat['bodyPart'] == bodyPart) {
        return stat['count'] as int;
      }
    }
    return 0;
  }

  // Get intensity color based on exercise count
  Color _getIntensityColor(int exerciseCount) {
    if (exerciseCount == 0) {
      return Colors.grey[700]!; // No exercises
    } else if (exerciseCount <= 2) {
      return Colors.red[200]!; // Light
    } else if (exerciseCount <= 4) {
      return Colors.red[400]!; // Moderate
    } else {
      return Colors.red[700]!; // Intense
    }
  }

  // Get color for body part
  Color _getBodyPartColor(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'chest':
        return Colors.red[400]!;
      case 'back':
        return Colors.blue[400]!;
      case 'biceps':
        return Colors.purple[400]!;
      case 'triceps':
        return Colors.orange[400]!;
      case 'shoulders':
        return Colors.yellow[600]!;
      case 'legs':
        return Colors.green[400]!;
      case 'core':
        return Colors.pink[400]!;
      case 'cardio':
        return Colors.cyan[400]!;
      default:
        return Color(0xFF6e9277);
    }
  }
}
