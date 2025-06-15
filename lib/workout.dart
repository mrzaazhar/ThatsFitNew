import 'package:flutter/material.dart';

class WorkoutPage extends StatefulWidget {
  final Map<String, dynamic>? suggestedWorkout;

  const WorkoutPage({Key? key, this.suggestedWorkout}) : super(key: key);

  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  @override
  Widget build(BuildContext context) {
    // Debug print to see what data we're receiving
    print('Suggested Workout Data: ${widget.suggestedWorkout}');

    if (widget.suggestedWorkout == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Workout Plan')),
        body: Center(child: Text('No workout data available')),
      );
    }

    // The workout data is directly in suggestedWorkout
    final summary = widget.suggestedWorkout!['summary'] ??
        {
          'title': 'Custom Workout',
          'subtitle': 'Workout Plan',
          'intensity': 'Moderate',
          'stepCount': 'N/A',
          'restPeriods': 'N/A'
        };

    final exercises = widget.suggestedWorkout!['exercises'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Workout Plan'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout Summary Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary['title'] ?? 'Workout Plan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    summary['subtitle'] ?? 'Custom Workout',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        Icons.fitness_center,
                        'Intensity',
                        summary['intensity'] ?? 'N/A',
                      ),
                      _buildSummaryItem(
                        Icons.directions_walk,
                        'Step Count',
                        (summary['stepCount'] ?? 'N/A').toString(),
                      ),
                      _buildSummaryItem(
                        Icons.timer,
                        'Rest Periods',
                        summary['restPeriods'] ?? 'N/A',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Exercises List
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exercises',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  if (exercises.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No exercises available'),
                      ),
                    )
                  else
                    ...exercises.map((exercise) {
                      if (exercise is Map<String, dynamic>) {
                        return _buildExerciseCard(exercise);
                      }
                      return SizedBox.shrink();
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise['name'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _buildExerciseDetail(
              Icons.fitness_center,
              'Sets & Reps',
              exercise['details']['setsAndReps'],
            ),
            SizedBox(height: 8),
            _buildExerciseDetail(
              Icons.timer,
              'Rest Period',
              exercise['details']['restPeriod'],
            ),
            SizedBox(height: 8),
            _buildExerciseDetail(
              Icons.info_outline,
              'Form Tips',
              exercise['details']['formTips'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetail(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
