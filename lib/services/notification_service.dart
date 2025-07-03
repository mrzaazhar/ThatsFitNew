import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'goal_check_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    _initialized = true;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to goals page
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule weekly goal reminder
  static Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await initialize();

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_goals',
          'Weekly Goals',
          channelDescription: 'Reminders for weekly fitness goals',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Schedule daily workout reminder
  static Future<void> scheduleDailyWorkoutReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await initialize();

    await _notifications.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_workout',
          'Daily Workout',
          channelDescription: 'Daily workout reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'immediate',
          'Immediate',
          channelDescription: 'Immediate notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Check goals and send notifications if needed
  static Future<void> checkGoalsAndNotify() async {
    try {
      final goalSummary = await GoalCheckService.getGoalSummary();

      if (goalSummary.isEmpty) return;

      final workoutGoal = goalSummary['workoutGoal'] ?? 0;
      final completedWorkouts = goalSummary['completedWorkouts'] ?? 0;
      final isBehindOnWorkouts = goalSummary['isBehindOnWorkouts'] ?? false;
      final focusBodyPart = goalSummary['focusBodyPart'] ?? 'Full Body';
      final workoutsLeft = goalSummary['workoutsLeft'] ?? 0;

      // Check if user is behind schedule
      if (isBehindOnWorkouts && workoutGoal > 0 && workoutsLeft > 0) {
        await showBehindScheduleNotification(
          focusBodyPart: focusBodyPart,
          completedWorkouts: completedWorkouts,
          workoutGoal: workoutGoal,
        );
      }

      // Check if user achieved their goal
      if (completedWorkouts >= workoutGoal && workoutGoal > 0) {
        await showGoalAchievementNotification(
          goalType: 'workout',
          achieved: completedWorkouts,
          goal: workoutGoal,
        );
      }
    } catch (e) {
      print('Error checking goals and notifying: $e');
    }
  }

  /// Schedule goal check notifications
  static Future<void> scheduleGoalCheckNotifications() async {
    // Cancel existing notifications
    await cancelAllNotifications();

    // Schedule mid-week check (Wednesday)
    final now = DateTime.now();
    final wednesday = now.add(Duration(days: (3 - now.weekday) % 7));
    final wednesdayTime =
        DateTime(wednesday.year, wednesday.month, wednesday.day, 18, 0); // 6 PM

    if (wednesdayTime.isAfter(now)) {
      await scheduleWeeklyReminder(
        id: 1,
        title: 'Weekly Goal Check-in',
        body: 'How are your fitness goals coming along this week?',
        scheduledDate: wednesdayTime,
      );
    }

    // Schedule end-of-week reminder (Saturday)
    final saturday = now.add(Duration(days: (6 - now.weekday) % 7));
    final saturdayTime =
        DateTime(saturday.year, saturday.month, saturday.day, 10, 0); // 10 AM

    if (saturdayTime.isAfter(now)) {
      await scheduleWeeklyReminder(
        id: 2,
        title: 'Weekend Workout Reminder',
        body: 'Don\'t forget to complete your weekly workout goals!',
        scheduledDate: saturdayTime,
      );
    }

    // Schedule daily workout reminder (every day at 7 AM)
    await scheduleDailyWorkoutReminder(
      id: 3,
      title: 'Time for Your Workout!',
      body: 'Start your day with a great workout session.',
      hour: 7,
      minute: 0,
    );
  }

  /// Show behind-schedule notification
  static Future<void> showBehindScheduleNotification({
    required String focusBodyPart,
    required int completedWorkouts,
    required int workoutGoal,
  }) async {
    final remainingWorkouts = workoutGoal - completedWorkouts;

    await showNotification(
      id: 4,
      title: 'Behind on Your Weekly Goals',
      body:
          'You have $remainingWorkouts workouts left to reach your goal. Focus on $focusBodyPart today!',
      payload: 'goals_page',
    );
  }

  /// Show goal achievement notification
  static Future<void> showGoalAchievementNotification({
    required String goalType,
    required int achieved,
    required int goal,
  }) async {
    await showNotification(
      id: 5,
      title: 'Goal Achieved! 🎉',
      body:
          'Congratulations! You\'ve reached your $goalType goal: $achieved/$goal',
      payload: 'goals_page',
    );
  }

  /// Show step goal reminder
  static Future<void> showStepGoalReminder({
    required int currentSteps,
    required int stepGoal,
  }) async {
    final stepsRemaining = stepGoal - currentSteps;

    await showNotification(
      id: 6,
      title: 'Step Goal Reminder',
      body: 'You need $stepsRemaining more steps to reach your daily goal!',
      payload: 'goals_page',
    );
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    await initialize();

    final androidGranted = await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;

    final iosGranted = await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
        false;

    return androidGranted || iosGranted;
  }
}
