import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepCounterService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  int _currentSteps = 0;
  double _lastMagnitude = 0;
  double _threshold = 12.0;
  DateTime? _lastStepTime;

  void start() {
    _subscription = accelerometerEvents.listen((event) async {
      double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > _threshold && _lastMagnitude <= _threshold) {
        if (_lastStepTime == null ||
            DateTime.now().difference(_lastStepTime!).inMilliseconds > 300) {
          _currentSteps++;
          _lastStepTime = DateTime.now();
          await _updateStepCountInFirestore(_currentSteps);
        }
      }
      _lastMagnitude = magnitude;
    });
  }

  void stop() {
    _subscription?.cancel();
  }

  Future<void> _updateStepCountInFirestore(int steps) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'dailySteps': steps,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> stepStream() {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots();
  }
}
