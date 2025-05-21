import 'package:flutter/material.dart';
import '../services/workout_service.dart';

class CreateWorkoutButton extends StatelessWidget {
  final String userId;
  final int stepCount;
  final int age;
  final String trainingExperience;
  final String gender;
  final double weight;
  final Function(Map<String, dynamic>) onWorkoutCreated;

  const CreateWorkoutButton({
    Key? key,
    required this.userId,
    required this.stepCount,
    required this.age,
    required this.trainingExperience,
    required this.gender,
    required this.weight,
    required this.onWorkoutCreated,
  }) : super(key: key);

  Future<void> _createWorkout(BuildContext context) async {
    try {
      final workoutService = WorkoutService();
      final result = await workoutService.createWorkout(
        userId: userId,
        stepCount: stepCount,
        age: age,
        trainingExperience: trainingExperience,
        gender: gender,
        weight: weight,
      );

      onWorkoutCreated(result);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _createWorkout(context),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Create Workout',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
