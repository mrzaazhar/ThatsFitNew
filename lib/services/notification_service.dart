import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'goal_check_service.dart';
import 'package:flutter/widgets.dart'; // Added for BuildContext

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
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
      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
      throw e;
    }
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

    try {
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
      print('Scheduled weekly reminder: $title at ${scheduledDate.toString()}');
    } catch (e) {
      print('Error scheduling weekly reminder: $e');
      throw e;
    }
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

    try {
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
      print('Scheduled daily workout reminder: $title at $hour:$minute');
    } catch (e) {
      print('Error scheduling daily workout reminder: $e');
      throw e;
    }
  }

  /// Schedule workout notifications for a specific day and time
  static Future<void> scheduleWorkoutNotifications({
    required String dayKey, // Format: YYYY-MM-DD
    required String workoutTime, // Format: HH:MM
    required List<String> bodyParts,
    required int baseNotificationId, // Base ID for this workout day
  }) async {
    await initialize();

    try {
      print('Scheduling workout notifications for $dayKey at $workoutTime');

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

      print('Scheduling notifications for workout on $dayKey at $workoutTime');
      print('Current time: ${now.toString()}');
      print('Workout time: ${workoutDate.toString()}');

      // Helper function to schedule notification with fallback
      Future<void> scheduleNotificationWithFallback({
        required int id,
        required String title,
        required String body,
        required DateTime scheduledTime,
      }) async {
        try {
          await _notifications.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(scheduledTime, tz.local),
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
            androidScheduleMode: AndroidScheduleMode.exact,
          );
          print(
              '✅ Scheduled notification: $title at ${scheduledTime.toString()}');
        } catch (e) {
          print('⚠️ Exact scheduling failed: $e');
          if (e.toString().contains('exact_alarms_not_permitted')) {
            print('🔄 Trying with inexact scheduling...');
            try {
              await _notifications.zonedSchedule(
                id,
                '$title (Inexact)',
                body,
                tz.TZDateTime.from(scheduledTime, tz.local),
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
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              );
              print('✅ Scheduled notification with inexact timing: $title');
            } catch (e2) {
              print('❌ Error with inexact scheduling: $e2');
            }
          } else {
            print('❌ Error scheduling notification: $e');
          }
        }
      }

      // 1. 1 hour before notification
      final oneHourBefore = workoutDate.subtract(Duration(hours: 1));
      if (oneHourBefore.isAfter(now)) {
        await scheduleNotificationWithFallback(
          id: baseNotificationId,
          title: 'Workout Reminder - 1 Hour',
          body:
              'Your $bodyPartsText workout starts in 1 hour! Time to prepare.',
          scheduledTime: oneHourBefore,
        );
      } else {
        print('⏰ 1-hour reminder time has passed');
      }

      // 2. 30 minutes before notification
      final thirtyMinutesBefore = workoutDate.subtract(Duration(minutes: 30));
      if (thirtyMinutesBefore.isAfter(now)) {
        await scheduleNotificationWithFallback(
          id: baseNotificationId + 1,
          title: 'Workout Reminder - 30 Minutes',
          body:
              'Your $bodyPartsText workout starts in 30 minutes! Get ready to crush it!',
          scheduledTime: thirtyMinutesBefore,
        );
      } else {
        print('⏰ 30-minute reminder time has passed');
      }

      // 3. At the scheduled time notification
      await scheduleNotificationWithFallback(
        id: baseNotificationId + 2,
        title: 'Time for Your Workout! 💪',
        body: 'Your $bodyPartsText workout is starting now! Let\'s get moving!',
        scheduledTime: workoutDate,
      );
    } catch (e) {
      print('Error in scheduleWorkoutNotifications: $e');
      throw e;
    }
  }

  /// Schedule all workout notifications for the week
  static Future<void> scheduleWeeklyWorkoutNotifications({
    required Map<String, dynamic> weeklySchedule,
  }) async {
    await initialize();

    try {
      print('=== Scheduling Weekly Workout Notifications ===');
      print('Weekly schedule: $weeklySchedule');

      // Cancel existing workout notifications (IDs 1000-9999 are reserved for workout notifications)
      await _notifications.cancelAll();
      print('Cancelled existing notifications');

      int notificationId = 1000; // Start with ID 1000 for workout notifications
      int scheduledCount = 0;

      for (String dayKey in weeklySchedule.keys) {
        final dayData = weeklySchedule[dayKey];

        print('Processing day: $dayKey');
        print('Day data: $dayData');

        if (dayData is Map<String, dynamic> &&
            dayData['isWorkoutDay'] == true &&
            dayData['bodyParts'] != null &&
            dayData['bodyParts'].length > 0) {
          final bodyParts = List<String>.from(dayData['bodyParts']);
          final workoutTime = dayData['workoutTime'] ?? '09:00';

          print(
              'Scheduling workout for $dayKey at $workoutTime with body parts: $bodyParts');

          await scheduleWorkoutNotifications(
            dayKey: dayKey,
            workoutTime: workoutTime,
            bodyParts: bodyParts,
            baseNotificationId: notificationId,
          );

          scheduledCount++;
          notificationId +=
              10; // Increment by 10 to leave space for 3 notifications per workout
        } else {
          print(
              'Skipping $dayKey - not a workout day or no body parts selected');
        }
      }

      print('✅ Scheduled $scheduledCount workout days with notifications');
    } catch (e) {
      print('❌ Error scheduling weekly workout notifications: $e');
      throw e;
    }
  }

  /// Test method to schedule a notification for testing
  static Future<void> scheduleTestNotification() async {
    await initialize();

    try {
      // Schedule a test notification for 10 seconds from now
      final testTime = DateTime.now().add(Duration(seconds: 10));

      await _notifications.zonedSchedule(
        9999, // Use a unique ID for test
        'Test Workout Notification',
        'This is a test notification to verify the system is working!',
        tz.TZDateTime.from(testTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_notification',
            'Test Notifications',
            channelDescription: 'Test notifications for debugging',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode:
            AndroidScheduleMode.exact, // Changed from exactAllowWhileIdle
      );

      print('✅ Test notification scheduled for ${testTime.toString()}');
    } catch (e) {
      print('❌ Error scheduling test notification: $e');

      // If exact alarms are not permitted, try with inexact scheduling
      if (e.toString().contains('exact_alarms_not_permitted')) {
        print(
            '⚠️ Exact alarms not permitted, trying with inexact scheduling...');
        try {
          final fallbackTime = DateTime.now().add(Duration(seconds: 10));
          await _notifications.zonedSchedule(
            9999,
            'Test Workout Notification (Inexact)',
            'This is a test notification with inexact timing!',
            tz.TZDateTime.from(fallbackTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'test_notification',
                'Test Notifications',
                channelDescription: 'Test notifications for debugging',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          print('✅ Test notification scheduled with inexact timing');
        } catch (e2) {
          print('❌ Error with inexact scheduling: $e2');
          throw e2;
        }
      } else {
        throw e;
      }
    }
  }

  /// Get pending notifications for debugging
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    await initialize();
    return await _notifications.pendingNotificationRequests();
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

    try {
      // For Android 13+ (API 33+), we need to request POST_NOTIFICATIONS permission
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      bool androidGranted = false;
      if (androidPlugin != null) {
        // Request notification permission for Android 13+
        androidGranted =
            await androidPlugin.requestNotificationsPermission() ?? false;

        // Also check if exact alarms are permitted
        final hasExactAlarmPermission = await checkExactAlarmPermission();
        if (!hasExactAlarmPermission) {
          print('⚠️ Exact alarms not permitted - notifications may be delayed');
        }
      }

      // For iOS
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      bool iosGranted = false;
      if (iosPlugin != null) {
        iosGranted = await iosPlugin.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }

      final granted = androidGranted || iosGranted;
      print(
          'Notification permissions granted: $granted (Android: $androidGranted, iOS: $iosGranted)');
      return granted;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Check if exact alarms are permitted (Android 12+)
  static Future<bool> checkExactAlarmPermission() async {
    try {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Try to schedule a test notification with exact timing
        final testTime = DateTime.now().add(Duration(seconds: 1));
        await _notifications.zonedSchedule(
          9998,
          'Test',
          'Test',
          tz.TZDateTime.from(testTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'test',
              'Test',
              channelDescription: 'Test',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exact,
        );
        await _notifications.cancel(9998);
        return true;
      }
      return false;
    } catch (e) {
      print('Exact alarms not permitted: $e');
      return false;
    }
  }

  /// Get exact alarm permission instructions
  static String getExactAlarmPermissionInstructions() {
    return 'For precise workout reminders, please enable exact alarms:\n\n'
        '1. Go to Settings > Apps > ThatsFit\n'
        '2. Tap "Permissions"\n'
        '3. Enable "Alarms & reminders"\n'
        '4. Or go to Settings > Apps > Special app access > Alarms & reminders\n'
        '5. Enable ThatsFit';
  }

  /// Comprehensive debugging method to identify notification issues
  static Future<Map<String, dynamic>> debugNotificationIssues() async {
    await initialize();

    Map<String, dynamic> debugInfo = {};

    try {
      // Check if service is initialized
      debugInfo['service_initialized'] = _initialized;

      // Check Android plugin availability
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      debugInfo['android_plugin_available'] = androidPlugin != null;

      // Check iOS plugin availability
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      debugInfo['ios_plugin_available'] = iosPlugin != null;

      // Check notification permissions
      bool androidGranted = false;
      bool iosGranted = false;

      if (androidPlugin != null) {
        androidGranted =
            await androidPlugin.requestNotificationsPermission() ?? false;
      }

      if (iosPlugin != null) {
        iosGranted = await iosPlugin.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }

      debugInfo['android_permissions_granted'] = androidGranted;
      debugInfo['ios_permissions_granted'] = iosGranted;
      debugInfo['any_permissions_granted'] = androidGranted || iosGranted;

      // Check exact alarm permissions
      final exactAlarmPermission = await checkExactAlarmPermission();
      debugInfo['exact_alarm_permitted'] = exactAlarmPermission;

      // Get pending notifications
      final pendingNotifications = await getPendingNotifications();
      debugInfo['pending_notifications_count'] = pendingNotifications.length;
      debugInfo['pending_notifications'] = pendingNotifications
          .map((n) => {
                'id': n.id,
                'title': n.title,
                'body': n.body,
              })
          .toList();

      // Test immediate notification
      try {
        await showNotification(
          id: 9997,
          title: 'Debug Test',
          body: 'This is a debug test notification',
        );
        debugInfo['immediate_notification_test'] = 'success';
      } catch (e) {
        debugInfo['immediate_notification_test'] = 'failed: $e';
      }

      // Test scheduled notification
      try {
        final testTime = DateTime.now().add(Duration(seconds: 5));
        await _notifications.zonedSchedule(
          9996,
          'Debug Scheduled Test',
          'This is a debug scheduled notification',
          tz.TZDateTime.from(testTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'debug_test',
              'Debug Test',
              channelDescription: 'Debug test notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exact,
        );
        debugInfo['scheduled_notification_test'] = 'success';

        // Clean up test notification
        await Future.delayed(Duration(seconds: 6));
        await _notifications.cancel(9996);
      } catch (e) {
        debugInfo['scheduled_notification_test'] = 'failed: $e';
      }
    } catch (e) {
      debugInfo['error'] = e.toString();
    }

    return debugInfo;
  }
}
