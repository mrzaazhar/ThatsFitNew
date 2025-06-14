import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkoutService {
  final String baseUrl = 'http://192.168.1.4:3001/api';

  Future<Map<String, dynamic>> createWorkout({
    required String userId,
  }) async {
    try {
      print('\n=== Creating Workout Request ===');
      print('User ID: $userId');
      print('URL: ${baseUrl}/users/$userId/create-workout');

      final url = Uri.parse('$baseUrl/users/$userId/create-workout');
      print('Making POST request to: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        print('Successfully decoded response: $result');
        return result;
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to create workout: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error creating workout: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error creating workout: $e');
    }
  }
}
