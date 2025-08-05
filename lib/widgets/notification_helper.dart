import 'package:flutter/material.dart';

// This file previously contained notification helper functions
// All notification functionality has been removed as requested

class NotificationHelper {
  // Placeholder class - notification functionality removed

  /// Placeholder method - notification functionality removed
  static Future<bool> setupNotifications() async {
    print(
        'NotificationHelper: All notification functionality has been removed');
    return false;
  }

  /// Placeholder method - notification functionality removed
  static Future<Map<String, dynamic>> checkNotificationStatus() async {
    return {
      'permissions_granted': false,
      'exact_alarms_permitted': false,
      'pending_notifications': 0,
      'status': 'disabled',
      'message': 'Notification functionality has been removed',
    };
  }
}

/// Placeholder widget - notification functionality removed
class NotificationTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Text(
        'Notification functionality has been removed',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
