import 'package:flutter/material.dart';
import '../services/workout_service.dart';

class CreateWorkoutButton extends StatelessWidget {
  final String userId;
  final Function(Map<String, dynamic>) onWorkoutCreated;

  const CreateWorkoutButton({
    Key? key,
    required this.userId,
    required this.onWorkoutCreated,
  }) : super(key: key);

  Future<void> _createWorkout(BuildContext context) async {
    try {
      print('\n=== Create Workout Button Clicked ===');
      print('User ID being passed: $userId');

      if (userId.isEmpty) {
        throw Exception('User ID is empty');
      }

      final workoutService = WorkoutService();
      print('Calling workout service...');

      // Only send userId to backend
      final result = await workoutService.createWorkout(userId: userId);
      print('Workout service response received: $result');

      onWorkoutCreated(result);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error in _createWorkout: $e');
      print('Stack trace: $stackTrace');

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
