import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/health_connect_service.dart';

class HealthConnectExample extends StatefulWidget {
  const HealthConnectExample({super.key});

  @override
  State<HealthConnectExample> createState() => _HealthConnectExampleState();
}

class _HealthConnectExampleState extends State<HealthConnectExample> {
  final HealthConnectService _healthService = HealthConnectService();
  int _currentSteps = 0;
  bool _isInitialized = false;
  bool _hasPermissions = false;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeHealthConnect();
  }

  Future<void> _initializeHealthConnect() async {
    try {
      // Initialize Health Connect
      final initialized = await _healthService.initialize();
      if (!initialized) {
        setState(() {
          _statusMessage = 'Health Connect not available';
        });
        return;
      }

      setState(() {
        _isInitialized = true;
        _statusMessage = 'Health Connect initialized';
      });

      // Request permissions
      await _requestPermissions();

      // Start monitoring
      await _startMonitoring();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Request activity recognition permission
      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) {
        setState(() {
          _statusMessage = 'Activity recognition permission denied';
        });
        return;
      }

      // Request Health Connect permissions
      final permissionsGranted = await _healthService.requestPermissions();
      setState(() {
        _hasPermissions = permissionsGranted;
        _statusMessage =
            permissionsGranted ? 'Permissions granted' : 'Permissions denied';
      });

      if (permissionsGranted) {
        // Get initial step count
        await _getTodaySteps();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Permission error: $e';
      });
    }
  }

  Future<void> _getTodaySteps() async {
    try {
      final steps = await _healthService.getTodayStepCount();
      setState(() {
        _currentSteps = steps;
        _statusMessage = 'Retrieved $steps steps';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error getting steps: $e';
      });
    }
  }

  Future<void> _startMonitoring() async {
    try {
      final started = await _healthService.startStepCountMonitoring();
      if (started) {
        // Listen to step count updates
        _healthService.stepCountStream.listen((steps) {
          setState(() {
            _currentSteps = steps;
            _statusMessage = 'Updated: $steps steps';
          });
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Monitoring error: $e';
      });
    }
  }

  Future<void> _writeSteps() async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(minutes: 5));

      final success = await _healthService.writeSteps(100, startTime, now);
      setState(() {
        _statusMessage =
            success ? 'Successfully wrote 100 steps' : 'Failed to write steps';
      });

      if (success) {
        // Refresh step count
        await _getTodaySteps();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Write error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Connect Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Today\'s Steps',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_currentSteps',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isInitialized ? _getTodaySteps : null,
                    child: const Text('Refresh Steps'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasPermissions ? _writeSteps : null,
                    child: const Text('Write 100 Steps'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isInitialized ? _requestPermissions : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Request Permissions'),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                        '1. Tap "Request Permissions" to grant Health Connect access'),
                    Text('2. Tap "Refresh Steps" to get current step count'),
                    Text(
                        '3. Tap "Write 100 Steps" to add steps to Health Connect'),
                    Text(
                        '4. Step count will update automatically every 5 minutes'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _healthService.dispose();
    super.dispose();
  }
}
