import 'dart:async';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthConnectService {
  static const String _tag = 'HealthConnectService';

  // Global Health instance
  final Health _health = Health();

  // Stream controller for step count updates
  final StreamController<int> _stepCountController =
      StreamController<int>.broadcast();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize Health Connect
  Future<bool> initialize() async {
    try {
      // Configure the health plugin
      await _health.configure();

      print('$_tag: Health Connect initialized successfully');
      return true;
    } catch (e) {
      print('$_tag: Error initializing Health Connect: $e');
      return false;
    }
  }

  /// Check if Health Connect is available
  Future<bool> isAvailable() async {
    try {
      // Try to configure to check availability
      await _health.configure();
      return true;
    } catch (e) {
      print('$_tag: Error checking Health Connect availability: $e');
      return false;
    }
  }

  /// Check if permissions are already granted
  Future<bool> hasPermissions() async {
    try {
      final types = [HealthDataType.STEPS];
      final hasAuth = await _health
          .hasPermissions(types, permissions: [HealthDataAccess.READ]);
      print('$_tag: Has permissions: ${hasAuth ?? false}');
      return hasAuth ?? false;
    } catch (e) {
      print('$_tag: Error checking permissions: $e');
      return false;
    }
  }

  /// Request permissions for steps data
  Future<bool> requestPermissions() async {
    try {
      // First check if permissions are already granted
      final alreadyGranted = await hasPermissions();
      if (alreadyGranted) {
        print('$_tag: Health Connect permissions already granted');
        return true;
      }

      // Request activity recognition permission first
      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) {
        print('$_tag: Activity recognition permission denied');
        return false;
      }

      // Define the types to get
      final types = [HealthDataType.STEPS];

      // Request authorization for reading and writing steps
      final permissions = [HealthDataAccess.READ_WRITE];

      final requested =
          await _health.requestAuthorization(types, permissions: permissions);

      if (requested) {
        print('$_tag: Health Connect permissions granted');
      } else {
        print('$_tag: Health Connect permissions denied');
      }

      return requested;
    } catch (e) {
      print('$_tag: Error requesting Health Connect permissions: $e');
      return false;
    }
  }

  /// Get today's step count
  Future<int> getTodayStepCount() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay =
          DateTime(now.year, now.month, now.day, 23, 59, 59); // Use end of day

      print('$_tag: Current time: ${now.toIso8601String()}');
      print('$_tag: Start of day: ${startOfDay.toIso8601String()}');
      print('$_tag: End time: ${endOfDay.toIso8601String()}');

      // Get total steps for today
      final steps = await _health.getTotalStepsInInterval(startOfDay, endOfDay);

      final stepCount = steps ?? 0;

      print('$_tag: Raw steps from health plugin: $steps');
      print('$_tag: Final step count: $stepCount');

      // Emit the new step count to update UI immediately
      _stepCountController.add(stepCount);
      print('$_tag: Retrieved $stepCount steps for today');
      return stepCount;
    } catch (e) {
      print('$_tag: Error getting today\'s step count: $e');
      return 0;
    }
  }

  /// Get step count for a specific date range
  Future<int> getStepCountForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final steps = await _health.getTotalStepsInInterval(startDate, endDate);
      final stepCount = steps ?? 0;

      print('$_tag: Retrieved $stepCount steps for date range');
      return stepCount;
    } catch (e) {
      print('$_tag: Error getting step count for date range: $e');
      return 0;
    }
  }

  /// Write steps data to Health Connect
  Future<bool> writeSteps(
      int steps, DateTime startTime, DateTime endTime) async {
    try {
      final success = await _health.writeHealthData(
        value: steps.toDouble(),
        type: HealthDataType.STEPS,
        startTime: startTime,
        endTime: endTime,
        recordingMethod: RecordingMethod.manual,
      );

      if (success) {
        print('$_tag: Successfully wrote $steps steps to Health Connect');
      } else {
        print('$_tag: Failed to write steps to Health Connect');
      }

      return success;
    } catch (e) {
      print('$_tag: Error writing steps to Health Connect: $e');
      return false;
    }
  }

  /// Start monitoring step count changes
  Future<bool> startStepCountMonitoring() async {
    try {
      // Request permissions first
      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        print('$_tag: Cannot start monitoring without permissions');
        return false;
      }

      // Set up periodic step count checking
      Timer.periodic(Duration(minutes: 5), (timer) async {
        await getTodayStepCount();
      });

      print('$_tag: Health Connect step count monitoring started');
      return true;
    } catch (e) {
      print('$_tag: Error starting step count monitoring: $e');
      return false;
    }
  }

  /// Stop monitoring step count changes
  void stopStepCountMonitoring() {
    print('$_tag: Health Connect step count monitoring stopped');
  }

  /// Get stream of step count updates
  Stream<int> get stepCountStream => _stepCountController.stream;

  /// Check if health data history is authorized
  Future<bool> isHealthDataHistoryAuthorized() async {
    try {
      final isAuthorized = await _health.isHealthDataHistoryAuthorized();
      return isAuthorized;
    } catch (e) {
      print('$_tag: Error checking health data history authorization: $e');
      return false;
    }
  }

  /// Request health data history authorization
  Future<bool> requestHealthDataHistoryAuthorization() async {
    try {
      final granted = await _health.requestHealthDataHistoryAuthorization();
      return granted;
    } catch (e) {
      print('$_tag: Error requesting health data history authorization: $e');
      return false;
    }
  }

  /// Check if background health data reading is available
  Future<bool> isHealthDataInBackgroundAvailable() async {
    try {
      final isAvailable = await _health.isHealthDataInBackgroundAvailable();
      return isAvailable;
    } catch (e) {
      print('$_tag: Error checking background health data availability: $e');
      return false;
    }
  }

  /// Check if background health data reading is authorized
  Future<bool> isHealthDataInBackgroundAuthorized() async {
    try {
      final isAuthorized = await _health.isHealthDataInBackgroundAuthorized();
      return isAuthorized;
    } catch (e) {
      print('$_tag: Error checking background health data authorization: $e');
      return false;
    }
  }

  /// Request background health data reading authorization
  Future<bool> requestHealthDataInBackgroundAuthorization() async {
    try {
      final granted =
          await _health.requestHealthDataInBackgroundAuthorization();
      return granted;
    } catch (e) {
      print('$_tag: Error requesting background health data authorization: $e');
      return false;
    }
  }

  /// Update step count in Firestore
  Future<void> _updateStepCountInFirestore(int stepCount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'dailySteps': stepCount,
          'lastUpdated': FieldValue.serverTimestamp(),
          'stepSource': 'health_connect',
        });

        print('$_tag: Updated user document with $stepCount steps');
      }
    } catch (e) {
      print('$_tag: Error updating Firestore: $e');
    }
  }

  /// Debug method to test different step count retrieval methods
  Future<void> debugStepCount() async {
    try {
      print('=== Debug Step Count ===');

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = now;

      print(
          'Time range: ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}');

      // Try different methods
      final method1 =
          await _health.getTotalStepsInInterval(startOfDay, endOfDay);
      print('Method 1 (getTotalStepsInInterval): $method1');

      // Try with a broader range
      final yesterday = startOfDay.subtract(Duration(days: 1));
      final method2 =
          await _health.getTotalStepsInInterval(yesterday, endOfDay);
      print('Method 2 (including yesterday): $method2');

      // Try with just today's range
      final todayEnd =
          startOfDay.add(Duration(days: 1)).subtract(Duration(milliseconds: 1));
      final method3 =
          await _health.getTotalStepsInInterval(startOfDay, todayEnd);
      print('Method 3 (full day): $method3');

      print('=== End Debug ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _stepCountController.close();
  }
}
