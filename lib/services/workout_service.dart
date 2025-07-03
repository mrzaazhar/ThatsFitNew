import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkoutService {
  // Configuration for real device testing
  // This should be the IP address of your development machine where the backend server is running
  final String baseUrl = 'http://192.168.1.4:3001/api';

  Future<Map<String, dynamic>> createWorkout({
    required String userId,
  }) async {
    try {
      print('\n=== Creating Workout Request ===');
      print('User ID: $userId');
      print('Base URL: $baseUrl');
      print('Full URL: ${baseUrl}/users/$userId/create-workout');

      if (userId.isEmpty) {
        throw Exception('User ID is empty');
      }

      final url = Uri.parse('$baseUrl/users/$userId/create-workout');
      print('Parsed URL: $url');
      print('URL scheme: ${url.scheme}');
      print('URL host: ${url.host}');
      print('URL port: ${url.port}');
      print('URL path: ${url.path}');

      print('Making POST request to: $url');
      print('Request headers: {"Content-Type": "application/json"}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 120));

      print('Response received!');
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        print('Successfully decoded response: $result');
        return result;
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw Exception('User profile not found: ${errorData['details']}');
      } else {
        print('Error response: ${response.body}');
        throw Exception(
            'Failed to create workout: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error creating workout: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
            'Cannot connect to server. Please check if the backend server is running on $baseUrl');
      }

      throw Exception('Error creating workout: $e');
    }
  }
}
