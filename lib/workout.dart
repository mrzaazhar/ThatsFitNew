import 'package:flutter/material.dart';

class WorkoutPage extends StatefulWidget {
  final Map<String, dynamic>? suggestedWorkout;

  const WorkoutPage({Key? key, this.suggestedWorkout}) : super(key: key);

  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  String selectedCategory = 'All'; // Track selected category
  late List<Map<String, dynamic>> workoutCategories;

  @override
  void initState() {
    super.initState();
    // Initialize workout categories
    workoutCategories = [
      {
        'title': 'Suggested Workout',
        'icon': Icons.star,
        'workouts': widget.suggestedWorkout != null
            ? [
                {
                  'name': widget.suggestedWorkout!['name'] ?? 'Custom Workout',
                  'duration': widget.suggestedWorkout!['duration'] ?? '30 min',
                  'calories': widget.suggestedWorkout!['calories'] ?? '200-300',
                  'difficulty':
                      widget.suggestedWorkout!['difficulty'] ?? 'Intermediate',
                  'image': 'assets/JPG/workout_image.jpg',
                  'description': widget.suggestedWorkout!['description'] ??
                      'A personalized workout plan based on your profile and activity.',
                  'exercises': widget.suggestedWorkout!['exercises'] != null
                      ? (widget.suggestedWorkout!['exercises'] is List
                          ? List<String>.from(
                              widget.suggestedWorkout!['exercises'])
                          : widget.suggestedWorkout!['exercises']
                              .toString()
                              .split('\n'))
                      : ['Custom exercises will be displayed here'],
                  'category':
                      widget.suggestedWorkout!['category'] ?? 'Suggested',
                  'equipment':
                      widget.suggestedWorkout!['equipment'] ?? 'None required',
                  'targetMuscles':
                      widget.suggestedWorkout!['targetMuscles'] ?? 'Full body',
                  'restPeriods': widget.suggestedWorkout!['restPeriods'] ??
                      '30 seconds between sets',
                },
              ]
            : [],
      },
      {
        'title': 'Cardio',
        'icon': Icons.directions_run,
        'workouts': [
          {
            'name': 'HIIT Cardio',
            'duration': '30 min',
            'calories': '300-400',
            'difficulty': 'Intermediate',
            'image': 'assets/JPG/workout_image.jpg',
            'description':
                'High-intensity interval training to boost your heart rate and burn calories.',
            'exercises': [
              'Jumping Jacks - 1 min',
              'Mountain Climbers - 1 min',
              'High Knees - 1 min',
              'Burpees - 1 min',
              'Rest - 30 sec',
              'Repeat 5 times',
            ],
          },
          {
            'name': 'Steady State Cardio',
            'duration': '45 min',
            'calories': '250-350',
            'difficulty': 'Beginner',
            'image': 'assets/JPG/workout_image.jpg',
            'description':
                'Moderate intensity cardio to improve endurance and burn fat.',
            'exercises': [
              'Brisk Walking - 10 min',
              'Jogging - 20 min',
              'Walking - 10 min',
              'Cool Down - 5 min',
            ],
          },
        ],
      },
      {
        'title': 'Strength',
        'icon': Icons.fitness_center,
        'workouts': [
          {
            'name': 'Full Body Strength',
            'duration': '45 min',
            'calories': '200-300',
            'difficulty': 'Intermediate',
            'image': 'assets/JPG/workout_image.jpg',
            'description':
                'Complete full body workout targeting all major muscle groups.',
            'exercises': [
              'Squats - 3 sets x 12 reps',
              'Push-ups - 3 sets x 10 reps',
              'Lunges - 3 sets x 10 reps each leg',
              'Plank - 3 sets x 30 sec',
              'Dumbbell Rows - 3 sets x 12 reps',
            ],
          },
          {
            'name': 'Upper Body Focus',
            'duration': '40 min',
            'calories': '180-250',
            'difficulty': 'Beginner',
            'image': 'assets/JPG/workout_image.jpg',
            'description':
                'Target your arms, chest, and back with this upper body workout.',
            'exercises': [
              'Push-ups - 3 sets x 8 reps',
              'Tricep Dips - 3 sets x 10 reps',
              'Bicep Curls - 3 sets x 12 reps',
              'Shoulder Press - 3 sets x 10 reps',
            ],
          },
        ],
      },
      {
        'title': 'Flexibility',
        'icon': Icons.self_improvement,
        'workouts': [
          {
            'name': 'Yoga Flow',
            'duration': '30 min',
            'calories': '150-200',
            'difficulty': 'Beginner',
            'image': 'assets/JPG/workout_image.jpg',
            'description':
                'Gentle yoga flow to improve flexibility and reduce stress.',
            'exercises': [
              'Sun Salutations - 5 rounds',
              'Warrior Poses - 1 min each',
              'Tree Pose - 1 min each side',
              'Child\'s Pose - 2 min',
              'Savasana - 5 min',
            ],
          },
          {
            'name': 'Stretching Routine',
            'duration': '20 min',
            'calories': '100-150',
            'difficulty': 'Beginner',
            'image': 'assets/JPG/workout_image.jpg',
            'description':
                'Basic stretching routine to improve flexibility and prevent injury.',
            'exercises': [
              'Neck Stretches - 2 min',
              'Shoulder Stretches - 3 min',
              'Hamstring Stretches - 3 min',
              'Hip Stretches - 3 min',
              'Back Stretches - 3 min',
            ],
          },
        ],
      },
    ];
  }

  // Get filtered workouts based on selected category
  List<Map<String, dynamic>> getFilteredWorkouts() {
    if (selectedCategory == 'All') {
      return workoutCategories;
    }
    return workoutCategories
        .where((category) => category['title'] == selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF008000),
      appBar: AppBar(
        title: Text(
          'Workout Plans',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFamily: 'DM Sans',
          ),
        ),
        backgroundColor: Color(0xFF008000),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  SizedBox(width: 8),
                  _buildFilterChip('Cardio'),
                  SizedBox(width: 8),
                  _buildFilterChip('Strength'),
                  SizedBox(width: 8),
                  _buildFilterChip('Flexibility'),
                ],
              ),
            ),
          ),
          // Workout List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: getFilteredWorkouts().length,
              itemBuilder: (context, categoryIndex) {
                final category = getFilteredWorkouts()[categoryIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Icon(category['icon'], color: Colors.white, size: 30),
                          SizedBox(width: 10),
                          Text(
                            category['title'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...category['workouts'].map<Widget>((workout) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFFbfbfbf),
                          borderRadius: BorderRadius.circular(15),
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
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                                image: DecorationImage(
                                  image: AssetImage(workout['image']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        workout['name'],
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'DM Sans',
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getDifficultyColor(
                                            workout['difficulty'],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          workout['difficulty'],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontFamily: 'DM Sans',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    workout['description'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoChip(
                                        Icons.timer,
                                        workout['duration'],
                                      ),
                                      _buildInfoChip(
                                        Icons.local_fire_department,
                                        workout['calories'],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      _showWorkoutDetails(context, workout);
                                    },
                                    child: Text(
                                      'View Details',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'DM Sans',
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF6e9277),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category) {
    final isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF6e9277) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category),
              color: isSelected ? Colors.white : Color(0xFF33443c),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFF33443c),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.fitness_center;
      case 'Cardio':
        return Icons.directions_run;
      case 'Strength':
        return Icons.fitness_center;
      case 'Flexibility':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFF33443c)),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Color(0xFF33443c),
              fontSize: 14,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showWorkoutDetails(BuildContext context, Map<String, dynamic> workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Color(0xFFbfbfbf),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                image: DecorationImage(
                  image: AssetImage(workout['image']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout['name'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoChip(Icons.timer, workout['duration']),
                        _buildInfoChip(
                          Icons.local_fire_department,
                          workout['calories'],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(
                              workout['difficulty'],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            workout['difficulty'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Additional workout details
                    if (workout['category'] != null) ...[
                      _buildDetailSection('Category', workout['category']),
                    ],
                    if (workout['equipment'] != null) ...[
                      _buildDetailSection('Equipment', workout['equipment']),
                    ],
                    if (workout['targetMuscles'] != null) ...[
                      _buildDetailSection(
                          'Target Muscles', workout['targetMuscles']),
                    ],
                    if (workout['restPeriods'] != null) ...[
                      _buildDetailSection(
                          'Rest Periods', workout['restPeriods']),
                    ],
                    SizedBox(height: 20),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      workout['description'],
                      style: TextStyle(fontSize: 16, fontFamily: 'DM Sans'),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Exercises',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    SizedBox(height: 8),
                    ...workout['exercises'].map<Widget>((exercise) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fiber_manual_record,
                              size: 8,
                              color: Color(0xFF33443c),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                exercise,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement start workout functionality
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Start Workout',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'DM Sans',
                            fontSize: 18,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6e9277),
                          padding: EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
            ),
          ),
          SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }
}
