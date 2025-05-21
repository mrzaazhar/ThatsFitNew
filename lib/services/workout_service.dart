import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkoutService {
  static const String baseUrl ='http://172.20.10.3:3000/api'; // replace with your actual IP

  Future<Map<String, dynamic>> createWorkout({
    required String userId,
    required int stepCount,
    required int age,
    required String trainingExperience,
    required String gender,
    required double weight,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-workout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'stepCount': stepCount,
          'age': age,
          'trainingExperience': trainingExperience,
          'gender': gender,
          'weight': weight,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create workout: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating workout: $e');
    }
  }
}
