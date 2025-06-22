import 'dart:async';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthConnectService {
  static const String _tag = 'HealthConnectService';

  // Global Health instance
  final Health _health = Health();

  // Stream controller for step count updates
  final StreamController<int> _stepCountController =
      StreamController<int>.broadcast();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // Get total steps for today
      final steps = await _health.getTotalStepsInInterval(startOfDay, now);

      final stepCount = steps ?? 0;

      await _updateStepCountInFirestore(stepCount);
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
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await _firestore
          .collection('step_counts')
          .doc(today.toIso8601String())
          .set({
        'stepCount': stepCount,
        'date': today.toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('$_tag: Updated step count in Firestore: $stepCount');
    } catch (e) {
      print('$_tag: Error updating step count in Firestore: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _stepCountController.close();
  }
}
