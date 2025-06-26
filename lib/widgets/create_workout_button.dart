import 'package:flutter/material.dart';
import '../services/workout_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateWorkoutButton extends StatelessWidget {
  final String userId;
  final Function(Map<String, dynamic>) onWorkoutCreated;

  const CreateWorkoutButton({
    Key? key,
    required this.userId,
    required this.onWorkoutCreated,
  }) : super(key: key);

  String _getCurrentDay() {
    final now = DateTime.now();
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[now.weekday - 1]; // weekday returns 1-7, where 1 is Monday
  }

  Future<void> _createWorkout(BuildContext context) async {
    try {
      print('\n=== Create Workout Button Clicked ===');
      print('User ID being passed: $userId');

      if (userId.isEmpty) {
        throw Exception('User ID is empty');
      }

      // Get current day and update Firebase
      final currentDay = _getCurrentDay();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the profile document first
        final profileSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .limit(1)
            .get();

        if (profileSnapshot.docs.isNotEmpty) {
          final profileDoc = profileSnapshot.docs[0];
          await profileDoc.reference.update({
            'currentDay': currentDay,
            'lastWorkoutDay': FieldValue.serverTimestamp(),
          });
          print('Updated current day in Firebase: $currentDay');
        } else {
          print('No profile document found for user');
          // Show a more helpful error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please complete your profile setup first'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
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
        String errorMessage = 'Error creating workout: $e';
        
        // Provide more helpful error messages
        if (e.toString().contains('User profile not found')) {
          errorMessage = 'Please complete your profile setup first. Go to Profile > Edit Profile to set up your fitness information.';
        } else if (e.toString().contains('Cannot connect to server')) {
          errorMessage = 'Cannot connect to server. Please check your internet connection and try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
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
