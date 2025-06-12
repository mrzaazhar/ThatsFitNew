import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkoutService {
  static const String baseUrl =
      'http://192.168.1.4:3001/api'; // Updated port to 3001

  Future<Map<String, dynamic>> createWorkout({
    required String userId,
    required int dailySteps,
    required int age,
    required String experience,
    required String gender,
    required double weight,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/create-workout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'dailySteps': dailySteps,
          'age': age,
          'experience': experience,
          'gender': gender,
          'weight': weight,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to create workout: ${response.body}');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Error creating workout: $e');
    }
  }
}
