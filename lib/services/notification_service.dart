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

  /// Schedule workout notifications for a specific day and time
  static Future<void> scheduleWorkoutNotifications({
    required String dayKey, // Format: YYYY-MM-DD
    required String workoutTime, // Format: HH:MM
    required List<String> bodyParts,
    required int baseNotificationId, // Base ID for this workout day
  }) async {
    await initialize();

    // Parse the workout time
    final timeParts = workoutTime.split(':');
    if (timeParts.length != 2) {
      print('Invalid workout time format: $workoutTime');
      return;
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    
    if (hour == null || minute == null) {
      print('Invalid workout time: $workoutTime');
      return;
    }

    // Parse the day
    final dayParts = dayKey.split('-');
    if (dayParts.length != 3) {
      print('Invalid day format: $dayKey');
      return;
    }

    final year = int.tryParse(dayParts[0]);
    final month = int.tryParse(dayParts[1]);
    final day = int.tryParse(dayParts[2]);

    if (year == null || month == null || day == null) {
      print('Invalid day format: $dayKey');
      return;
    }

    // Create the workout date
    final workoutDate = DateTime(year, month, day, hour, minute);
    
    // Check if the workout time has already passed for today
    final now = DateTime.now();
    if (workoutDate.isBefore(now)) {
      print('Workout time has already passed for $dayKey at $workoutTime');
      return;
    }

    // Create notification messages
    final bodyPartsText = bodyParts.join(' & ');
    
    // 1. 1 hour before notification
    final oneHourBefore = workoutDate.subtract(Duration(hours: 1));
    if (oneHourBefore.isAfter(now)) {
      await _notifications.zonedSchedule(
        baseNotificationId,
        'Workout Reminder - 1 Hour',
        'Your $bodyPartsText workout starts in 1 hour! Time to prepare.',
        tz.TZDateTime.from(oneHourBefore, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_reminder',
            'Workout Reminders',
            channelDescription: 'Reminders for scheduled workouts',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('Scheduled 1-hour reminder for $dayKey at ${oneHourBefore.toString()}');
    }

    // 2. 30 minutes before notification
    final thirtyMinutesBefore = workoutDate.subtract(Duration(minutes: 30));
    if (thirtyMinutesBefore.isAfter(now)) {
      await _notifications.zonedSchedule(
        baseNotificationId + 1,
        'Workout Reminder - 30 Minutes',
        'Your $bodyPartsText workout starts in 30 minutes! Get ready to crush it!',
        tz.TZDateTime.from(thirtyMinutesBefore, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_reminder',
            'Workout Reminders',
            channelDescription: 'Reminders for scheduled workouts',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('Scheduled 30-minute reminder for $dayKey at ${thirtyMinutesBefore.toString()}');
    }

    // 3. At the scheduled time notification
    await _notifications.zonedSchedule(
      baseNotificationId + 2,
      'Time for Your Workout! 💪',
      'Your $bodyPartsText workout is starting now! Let\'s get moving!',
      tz.TZDateTime.from(workoutDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_reminder',
          'Workout Reminders',
          channelDescription: 'Reminders for scheduled workouts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    print('Scheduled workout time notification for $dayKey at ${workoutDate.toString()}');
  }

  /// Schedule all workout notifications for the week
  static Future<void> scheduleWeeklyWorkoutNotifications({
    required Map<String, dynamic> weeklySchedule,
  }) async {
    await initialize();

    // Cancel existing workout notifications (IDs 1000-9999 are reserved for workout notifications)
    await _notifications.cancelAll();

    int notificationId = 1000; // Start with ID 1000 for workout notifications

    for (String dayKey in weeklySchedule.keys) {
      final dayData = weeklySchedule[dayKey];
      
      if (dayData is Map<String, dynamic> && 
          dayData['isWorkoutDay'] == true && 
          dayData['bodyParts'] != null && 
          dayData['bodyParts'].length > 0) {
        
        final bodyParts = List<String>.from(dayData['bodyParts']);
        final workoutTime = dayData['workoutTime'] ?? '09:00';

        await scheduleWorkoutNotifications(
          dayKey: dayKey,
          workoutTime: workoutTime,
          bodyParts: bodyParts,
          baseNotificationId: notificationId,
        );

        notificationId += 10; // Increment by 10 to leave space for 3 notifications per workout
      }
    }

    print('Scheduled workout notifications for the week');
  }

  /// Cancel workout notifications for a specific day
  static Future<void> cancelWorkoutNotificationsForDay(String dayKey) async {
    // Calculate the base notification ID for this day
    // This is a simple hash-based approach - in a real app, you might want to store the IDs
    final dayHash = dayKey.hashCode;
    final baseId = 1000 + (dayHash % 1000);
    
    // Cancel the 3 notifications for this day
    await _notifications.cancel(baseId);
    await _notifications.cancel(baseId + 1);
    await _notifications.cancel(baseId + 2);
    
    print('Cancelled workout notifications for $dayKey');
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
