import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'goal_check_service.dart';

class WorkoutRecordingService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Record a completed workout
  static Future<void> recordWorkout({
    required String workoutName,
    required List<Map<String, dynamic>> exercises,
    required int duration,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final workoutData = {
        'workoutName': workoutName,
        'exercises': exercises,
        'duration': duration,
        'notes': notes,
        'completedAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'weekStart': _getWeekStart(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_history')
          .add(workoutData);

      await _updateWeeklyProgress();

      // Check goals progress (notification functionality removed)
      await GoalCheckService.checkGoalsAndNotify();

      print('Workout recorded successfully: $workoutName');
    } catch (e) {
      print('Error recording workout: $e');
      throw e;
    }
  }

  /// Update weekly progress
  static Future<void> _updateWeeklyProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final weekStart = _getWeekStart();

      final workoutsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_history')
          .where('weekStart', isEqualTo: weekStart)
          .get();

      final completedWorkouts = workoutsSnapshot.docs.length;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weekly_progress')
          .doc(weekStart)
          .set({
        'completedWorkouts': completedWorkouts,
        'lastUpdated': FieldValue.serverTimestamp(),
        'weekStart': weekStart,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating weekly progress: $e');
    }
  }

  /// Get weekly progress
  static Future<Map<String, dynamic>> getWeeklyProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final weekStart = _getWeekStart();

      final progressDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weekly_progress')
          .doc(weekStart)
          .get();

      if (progressDoc.exists) {
        return progressDoc.data()!;
      }

      return {'completedWorkouts': 0};
    } catch (e) {
      print('Error getting weekly progress: $e');
      return {};
    }
  }

  /// Check goal progress
  static Future<Map<String, dynamic>> checkGoalProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final weekStart = _getWeekStart();

      final goalsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weekly_goals')
          .doc(weekStart)
          .get();

      if (!goalsDoc.exists) return {};

      final goals = goalsDoc.data()!;
      final progress = await getWeeklyProgress();

      final workoutGoal = goals['workoutGoal'] ?? 0;
      final completedWorkouts = progress['completedWorkouts'] ?? 0;

      final workoutProgress =
          workoutGoal > 0 ? (completedWorkouts / workoutGoal) : 0.0;

      final currentDay = DateTime.now().weekday;
      final expectedProgress = currentDay / 7.0;

      final isBehindOnWorkouts = workoutProgress < expectedProgress;

      return {
        'isBehindOnWorkouts': isBehindOnWorkouts,
        'workoutProgress': workoutProgress,
        'expectedProgress': expectedProgress,
        'completedWorkouts': completedWorkouts,
        'workoutGoal': workoutGoal,
        'focusBodyPart': goals['focusBodyPart'] ?? 'Full Body',
      };
    } catch (e) {
      print('Error checking goal progress: $e');
      return {};
    }
  }

  /// Get week start date string
  static String _getWeekStart() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
  }

  /// Get workout history for a user
  static Future<List<Map<String, dynamic>>> getWorkoutHistory({
    int limit = 10,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final historySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_history')
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return historySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting workout history: $e');
      return [];
    }
  }

  /// Delete a workout record
  static Future<void> deleteWorkout(String workoutId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_history')
          .doc(workoutId)
          .delete();

      // Update weekly progress after deletion
      await _updateWeeklyProgress();

      print('Workout deleted successfully: $workoutId');
    } catch (e) {
      print('Error deleting workout: $e');
      throw e;
    }
  }

  /// Get workout statistics
  static Future<Map<String, dynamic>> getWorkoutStats({
    int days = 30,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final startDate = DateTime.now().subtract(Duration(days: days));

      final historySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_history')
          .where('completedAt', isGreaterThanOrEqualTo: startDate)
          .get();

      final workouts = historySnapshot.docs;

      if (workouts.isEmpty) {
        return {
          'totalWorkouts': 0,
          'totalDuration': 0,
          'averageDuration': 0,
          'mostFrequentWorkout': null,
          'totalExercises': 0,
        };
      }

      num totalDuration = 0;
      Map<String, int> workoutCounts = {};
      int totalExercises = 0;

      for (final doc in workouts) {
        final data = doc.data();
        totalDuration += data['duration'] ?? 0;
        totalExercises += (data['exercises'] as List?)?.length ?? 0;

        final workoutName = data['workoutName'] ?? 'Unknown';
        workoutCounts[workoutName] = (workoutCounts[workoutName] ?? 0) + 1;
      }

      final mostFrequentWorkout =
          workoutCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      return {
        'totalWorkouts': workouts.length,
        'totalDuration': totalDuration,
        'averageDuration': totalDuration / workouts.length,
        'mostFrequentWorkout': mostFrequentWorkout,
        'totalExercises': totalExercises,
      };
    } catch (e) {
      print('Error getting workout stats: $e');
      return {};
    }
  }
}
