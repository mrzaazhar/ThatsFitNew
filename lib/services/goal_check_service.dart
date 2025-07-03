import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'workout_recording_service.dart';
import 'notification_service.dart';

class GoalCheckService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check and notify about goal progress
  static Future<void> checkAndNotifyGoalProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final progress = await WorkoutRecordingService.checkGoalProgress();

      if (progress.isEmpty) return;

      final isBehindOnWorkouts = progress['isBehindOnWorkouts'] ?? false;
      final completedWorkouts = progress['completedWorkouts'] ?? 0;
      final workoutGoal = progress['workoutGoal'] ?? 0;
      final focusBodyPart = progress['focusBodyPart'] ?? 'Full Body';

      // Check if user is behind schedule
      if (isBehindOnWorkouts && workoutGoal > 0) {
        NotificationService.showBehindScheduleNotification(
          focusBodyPart: focusBodyPart,
          completedWorkouts: completedWorkouts,
          workoutGoal: workoutGoal,
        );
      }

      // Check if user achieved their goal
      if (completedWorkouts >= workoutGoal && workoutGoal > 0) {
        NotificationService.showGoalAchievementNotification(
          goalType: 'workout',
          achieved: completedWorkouts,
          goal: workoutGoal,
        );
      }
    } catch (e) {
      print('Error checking goal progress: $e');
    }
  }

  /// Get goal summary for dashboard
  static Future<Map<String, dynamic>> getGoalSummary() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final progress = await WorkoutRecordingService.checkGoalProgress();
      final weeklyProgress = await WorkoutRecordingService.getWeeklyProgress();

      if (progress.isEmpty) return {};

      final workoutGoal = progress['workoutGoal'] ?? 0;
      final completedWorkouts = progress['completedWorkouts'] ?? 0;
      final workoutProgress = progress['workoutProgress'] ?? 0.0;
      final isBehindOnWorkouts = progress['isBehindOnWorkouts'] ?? false;
      final focusBodyPart = progress['focusBodyPart'] ?? 'Full Body';

      // Calculate days left in week
      final now = DateTime.now();
      final daysLeft = 7 - now.weekday;
      final workoutsLeft = workoutGoal - completedWorkouts;

      return {
        'workoutGoal': workoutGoal,
        'completedWorkouts': completedWorkouts,
        'workoutProgress': workoutProgress,
        'isBehindOnWorkouts': isBehindOnWorkouts,
        'focusBodyPart': focusBodyPart,
        'daysLeft': daysLeft,
        'workoutsLeft': workoutsLeft > 0 ? workoutsLeft : 0,
        'onTrack': !isBehindOnWorkouts && workoutsLeft <= daysLeft,
        'needsAttention': isBehindOnWorkouts || workoutsLeft > daysLeft,
      };
    } catch (e) {
      print('Error getting goal summary: $e');
      return {};
    }
  }

  /// Update user's weekly step count
  static Future<void> updateWeeklySteps(int steps) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final weekStart = _getWeekStart();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weekly_progress')
          .doc(weekStart)
          .set({
        'weeklySteps': steps,
        'lastUpdated': FieldValue.serverTimestamp(),
        'weekStart': weekStart,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating weekly steps: $e');
    }
  }

  /// Get step progress
  static Future<Map<String, dynamic>> getStepProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final weekStart = _getWeekStart();

      // Get current goals
      final goalsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weekly_goals')
          .doc(weekStart)
          .get();

      if (!goalsDoc.exists) return {};

      final goals = goalsDoc.data()!;
      final stepGoal = goals['stepGoal'] ?? 0;

      // Get current step count
      final progressDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weekly_progress')
          .doc(weekStart)
          .get();

      final currentSteps =
          progressDoc.exists ? (progressDoc.data()?['weeklySteps'] ?? 0) : 0;
      final stepProgress =
          stepGoal > 0 ? (currentSteps / stepGoal).clamp(0.0, 1.0) : 0.0;

      return {
        'stepGoal': stepGoal,
        'currentSteps': currentSteps,
        'stepProgress': stepProgress,
        'stepsRemaining': stepGoal - currentSteps,
      };
    } catch (e) {
      print('Error getting step progress: $e');
      return {};
    }
  }

  /// Get week start date string
  static String _getWeekStart() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
  }

  /// Reset weekly goals for new week
  static Future<void> resetWeeklyGoals() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final weekStart = _getWeekStart();

      // Clear previous week's progress
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weekly_progress')
          .doc(weekStart)
          .set({
        'completedWorkouts': 0,
        'weeklySteps': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
        'weekStart': weekStart,
      });

      print('Weekly goals reset for new week');
    } catch (e) {
      print('Error resetting weekly goals: $e');
    }
  }

  /// Check goals and send notifications automatically
  static Future<void> checkGoalsAndNotify() async {
    try {
      final progress = await WorkoutRecordingService.checkGoalProgress();

      if (progress.isEmpty) return;

      final isBehindOnWorkouts = progress['isBehindOnWorkouts'] ?? false;
      final completedWorkouts = progress['completedWorkouts'] ?? 0;
      final workoutGoal = progress['workoutGoal'] ?? 0;
      final focusBodyPart = progress['focusBodyPart'] ?? 'Full Body';

      // Check if user is behind schedule
      if (isBehindOnWorkouts && workoutGoal > 0) {
        await NotificationService.showBehindScheduleNotification(
          focusBodyPart: focusBodyPart,
          completedWorkouts: completedWorkouts,
          workoutGoal: workoutGoal,
        );
      }

      // Check if user achieved their goal
      if (completedWorkouts >= workoutGoal && workoutGoal > 0) {
        await NotificationService.showGoalAchievementNotification(
          goalType: 'workout',
          achieved: completedWorkouts,
          goal: workoutGoal,
        );
      }
    } catch (e) {
      print('Error checking goal progress: $e');
    }
  }
}
