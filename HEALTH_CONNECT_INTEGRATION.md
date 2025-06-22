# Health Connect Integration Guide

This guide explains how to integrate Health Connect in your Flutter application to get step count data from Samsung Health and your Galaxy Fit 3 wearable.

## Prerequisites

1. **Android Device Requirements:**
   - Android 12 (API level 31) or higher
   - Health Connect app installed from Google Play Store
   - Samsung Health app installed
   - Galaxy Fit 3 connected to Samsung Health

2. **Setup Steps:**
   - Install Health Connect from Google Play Store
   - Open Samsung Health and connect your Galaxy Fit 3
   - In Health Connect, go to "Apps and devices" → "Samsung Health"
   - Enable "Steps" data sharing from Samsung Health to Health Connect

## Implementation Steps

### Step 1: Update Android Manifest

Add Health Connect permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Health Connect permissions -->
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.WRITE_STEPS"/>

<!-- In the queries section -->
<queries>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
    <!-- Health Connect queries -->
    <package android:name="com.google.android.apps.healthdata" />
</queries>
```

### Step 2: Update build.gradle.kts

Update `android/app/build.gradle.kts`:

```kotlin
android {
    // ... existing config ...
    defaultConfig {
        // ... existing config ...
        minSdk = 26  // Health Connect requires API 26+
    }
}

dependencies {
    implementation("androidx.health.connect:connect-client:1.0.0-alpha11")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
```

### Step 3: Create Health Connect Service

Create `lib/services/health_connect_service.dart`:

```dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthConnectService {
  static const String _tag = 'HealthConnectService';
  static const MethodChannel _channel = MethodChannel('health_connect');
  
  final StreamController<int> _stepCountController = StreamController<int>.broadcast();
  Stream<int> get stepCountStream => _stepCountController.stream;

  Future<bool> initialize() async {
    try {
      final bool result = await _channel.invokeMethod('initialize');
      return result;
    } catch (e) {
      print('$_tag: Failed to initialize Health Connect: $e');
      return false;
    }
  }

  Future<bool> isAvailable() async {
    try {
      final bool result = await _channel.invokeMethod('isAvailable');
      return result;
    } catch (e) {
      print('$_tag: Error checking Health Connect availability: $e');
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final bool result = await _channel.invokeMethod('requestPermissions');
      return result;
    } catch (e) {
      print('$_tag: Error requesting permissions: $e');
      return false;
    }
  }

  Future<int> getTodayStepCount() async {
    try {
      final int steps = await _channel.invokeMethod('getTodayStepCount');
      await _updateStepCountInFirestore(steps);
      _stepCountController.add(steps);
      return steps;
    } catch (e) {
      print('$_tag: Error reading step count: $e');
      return 0;
    }
  }

  Future<int> getStepCountForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final int steps = await _channel.invokeMethod('getStepCountForDateRange', {
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
      });
      return steps;
    } catch (e) {
      print('$_tag: Error reading step count for date range: $e');
      return 0;
    }
  }

  Future<void> startStepCountMonitoring() async {
    try {
      await _channel.invokeMethod('startStepCountMonitoring');
      Timer.periodic(const Duration(minutes: 5), (timer) async {
        await getTodayStepCount();
      });
    } catch (e) {
      print('$_tag: Error starting step count monitoring: $e');
    }
  }

  Future<void> _updateStepCountInFirestore(int steps) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'dailySteps': steps,
          'lastUpdated': FieldValue.serverTimestamp(),
          'stepSource': 'health_connect',
        });
      }
    } catch (e) {
      print('$_tag: Error updating Firestore: $e');
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> stepStream() {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots();
  }

  void dispose() {
    _stepCountController.close();
  }
}
```

### Step 4: Update MainActivity.kt

Update `android/app/src/main/kotlin/com/example/flutter_application_1/MainActivity.kt`:

```kotlin
package com.example.flutter_application_1

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity: FlutterActivity() {
    private val CHANNEL = "health_connect"
    private var healthConnectClient: HealthConnectClient? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> initializeHealthConnect(result)
                "isAvailable" -> checkHealthConnectAvailability(result)
                "requestPermissions" -> requestHealthConnectPermissions(result)
                "getTodayStepCount" -> getTodayStepCount(result)
                "getStepCountForDateRange" -> {
                    val startDate = call.argument<Long>("startDate")
                    val endDate = call.argument<Long>("endDate")
                    if (startDate != null && endDate != null) {
                        getStepCountForDateRange(startDate, endDate, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Start and end dates are required", null)
                    }
                }
                "startStepCountMonitoring" -> startStepCountMonitoring(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun initializeHealthConnect(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                if (HealthConnectClient.isAvailable(this@MainActivity)) {
                    healthConnectClient = HealthConnectClient.getOrCreate(this@MainActivity)
                    result.success(true)
                } else {
                    result.success(false)
                }
            } catch (e: Exception) {
                result.error("INITIALIZATION_ERROR", e.message, null)
            }
        }
    }

    private fun checkHealthConnectAvailability(result: MethodChannel.Result) {
        result.success(HealthConnectClient.isAvailable(this))
    }

    private fun requestHealthConnectPermissions(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val permissions = setOf(HealthPermission.READ_STEPS)
                val granted = healthConnectClient?.requestAuthorization(permissions)
                result.success(granted?.isNotEmpty() ?: false)
            } catch (e: Exception) {
                result.error("PERMISSION_ERROR", e.message, null)
            }
        }
    }

    private fun getTodayStepCount(result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val now = LocalDateTime.now()
                val startOfDay = now.toLocalDate().atStartOfDay()
                val endOfDay = startOfDay.plusDays(1)
                
                val request = ReadRecordsRequest(
                    recordType = StepsRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(
                        startOfDay.atZone(ZoneId.systemDefault()).toInstant(),
                        endOfDay.atZone(ZoneId.systemDefault()).toInstant()
                    )
                )
                
                val response = healthConnectClient?.readRecords(request)
                val totalSteps = response?.records?.sumOf { it.count } ?: 0
                result.success(totalSteps)
            } catch (e: Exception) {
                result.error("READ_ERROR", e.message, null)
            }
        }
    }

    private fun getStepCountForDateRange(startDate: Long, endDate: Long, result: MethodChannel.Result) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val request = ReadRecordsRequest(
                    recordType = StepsRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(
                        Instant.ofEpochMilli(startDate),
                        Instant.ofEpochMilli(endDate)
                    )
                )
                
                val response = healthConnectClient?.readRecords(request)
                val totalSteps = response?.records?.sumOf { it.count } ?: 0
                result.success(totalSteps)
            } catch (e: Exception) {
                result.error("READ_ERROR", e.message, null)
            }
        }
    }

    private fun startStepCountMonitoring(result: MethodChannel.Result) {
        result.success(true)
    }
}
```

### Step 5: Integration with Existing Step Counter

The Health Connect service has been integrated into your existing `step_count.dart` file. The app now includes:

1. **Toggle Button**: A button in the app bar to switch between sensor-based and Health Connect step counting
2. **Automatic Detection**: Checks if Health Connect is available on the device
3. **Permission Handling**: Requests necessary permissions when switching to Health Connect
4. **Real-time Updates**: Listens to step count changes from Health Connect
5. **Fallback**: Falls back to sensor-based counting if Health Connect is not available

## Usage

1. **Initial Setup:**
   - Ensure Health Connect and Samsung Health are properly configured
   - Your Galaxy Fit 3 should be connected to Samsung Health
   - Samsung Health should be sharing step data with Health Connect

2. **In the App:**
   - Open the Step Count page
   - If Health Connect is available, you'll see a toggle button in the app bar
   - Tap the toggle to switch between "Sensor" and "Health" modes
   - When in "Health" mode, the app will use step data from your Galaxy Fit 3 via Samsung Health and Health Connect

3. **Data Flow:**
   ```
   Galaxy Fit 3 → Samsung Health → Health Connect → Your Flutter App → Firebase
   ```

## Troubleshooting

1. **Health Connect not available:**
   - Ensure your device runs Android 12 or higher
   - Install Health Connect from Google Play Store
   - Check if Health Connect is enabled in device settings

2. **No step data:**
   - Verify Samsung Health is connected to Health Connect
   - Check that step data sharing is enabled in Health Connect
   - Ensure your Galaxy Fit 3 is properly synced with Samsung Health

3. **Permission errors:**
   - Grant step count permissions when prompted
   - Check Health Connect app permissions in device settings

4. **Build errors:**
   - Ensure all dependencies are properly added
   - Clean and rebuild the project: `flutter clean && flutter pub get`

## Benefits

- **Accurate Data**: Uses your Galaxy Fit 3's dedicated step sensor
- **Battery Efficient**: No need for continuous sensor monitoring
- **Background Sync**: Steps are automatically synced from your wearable
- **Cross-Platform**: Works with any Health Connect-compatible app
- **Privacy**: Uses Android's privacy-focused Health Connect framework

## Testing

1. Take a walk with your Galaxy Fit 3
2. Ensure Samsung Health syncs the steps
3. Check that Health Connect receives the data
4. Switch to "Health" mode in your app
5. Verify the step count matches your wearable

The integration is now complete and ready to use! 