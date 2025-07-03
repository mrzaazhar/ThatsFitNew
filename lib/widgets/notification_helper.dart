import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/goal_check_service.dart';

class NotificationHelper {
  /// Request notification permissions and set up notifications
  static Future<void> setupNotifications() async {
    try {
      // Request permissions
      final granted = await NotificationService.requestPermissions();

      if (granted) {
        // Schedule recurring notifications
        await NotificationService.scheduleGoalCheckNotifications();
        print('Notifications set up successfully');
      } else {
        print('Notification permissions not granted');
      }
    } catch (e) {
      print('Error setting up notifications: $e');
    }
  }

  /// Manually check goals and send notifications
  static Future<void> checkGoalsNow() async {
    try {
      await NotificationService.checkGoalsAndNotify();
    } catch (e) {
      print('Error checking goals: $e');
    }
  }

  /// Show a test notification
  static Future<void> showTestNotification() async {
    await NotificationService.showNotification(
      id: 999,
      title: 'Test Notification',
      body: 'This is a test notification from ThatsFit!',
    );
  }

  /// Show step goal reminder
  static Future<void> showStepReminder(int currentSteps, int stepGoal) async {
    await NotificationService.showStepGoalReminder(
      currentSteps: currentSteps,
      stepGoal: stepGoal,
    );
  }
}

/// Widget to test notifications
class NotificationTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => NotificationHelper.setupNotifications(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6e9277),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Setup Notifications',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => NotificationHelper.showTestNotification(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Test Notification',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => NotificationHelper.checkGoalsNow(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Check Goals Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
