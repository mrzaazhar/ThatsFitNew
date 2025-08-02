import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Backend server configuration
  static const String baseUrl = 'http://192.168.0.171:3002/api/admin';

  /// Get all users from backend server
  static Future<List<Map<String, dynamic>>> getAllUsersFromBackend() async {
    try {
      print('🌐 Making HTTP request to: $baseUrl/users');
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final users = List<Map<String, dynamic>>.from(data['users'] ?? []);
        print('✅ Users parsed: ${users.length} users');
        return users;
      } else {
        print(
            '❌ Error getting users: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error connecting to backend: $e');
      return [];
    }
  }

  /// Get total user count from backend
  static Future<int> getTotalUserCount() async {
    try {
      print('🌐 Making HTTP request to: $baseUrl/users/count');
      final response = await http.get(
        Uri.parse('$baseUrl/users/count'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final totalUsers = data['totalUsers'] ?? 0;
        print('✅ Total users parsed: $totalUsers');
        return totalUsers;
      } else {
        print(
            '❌ Error getting user count: ${response.statusCode} - ${response.body}');
        return 0;
      }
    } catch (e) {
      print('❌ Error connecting to backend: $e');
      return 0;
    }
  }

  /// Get active users count from backend
  static Future<int> getActiveUsersCount() async {
    try {
      print('🌐 Making HTTP request to: $baseUrl/users/active');
      final response = await http.get(
        Uri.parse('$baseUrl/users/active'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final activeUsers = data['activeUsers'] ?? 0;
        print('✅ Active users parsed: $activeUsers');
        return activeUsers;
      } else {
        print(
            '❌ Error getting active users count: ${response.statusCode} - ${response.body}');
        return 0;
      }
    } catch (e) {
      print('❌ Error connecting to backend: $e');
      return 0;
    }
  }

  /// Create user through backend
  static Future<Map<String, dynamic>> createUserViaBackend({
    required String email,
    required String password,
    required String name,
    String? username,
    int? age,
    double? weight,
    String? gender,
    String? experience,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
              'displayName': name,
              'name': name,
              'username': username,
              'age': age,
              'weight': weight,
              'gender': gender,
              'experience': experience,
            }),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create user');
      }
    } catch (e) {
      print('Error creating user via backend: $e');
      rethrow;
    }
  }

  /// Update user through backend
  static Future<bool> updateUserViaBackend({
    required String uid,
    String? name,
    String? username,
    String? email,
    int? age,
    double? weight,
    String? gender,
    String? experience,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;
      if (age != null) updateData['age'] = age;
      if (weight != null) updateData['weight'] = weight;
      if (gender != null) updateData['gender'] = gender;
      if (experience != null) updateData['experience'] = experience;

      final response = await http
          .put(
            Uri.parse('$baseUrl/users/$uid'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'updateData': updateData}),
          )
          .timeout(Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user via backend: $e');
      return false;
    }
  }

  /// Delete user through backend
  static Future<bool> deleteUserViaBackend(String uid) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$uid'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting user via backend: $e');
      return false;
    }
  }

  /// Get all users with their profile data (legacy method)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final users = <Map<String, dynamic>>[];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();

        // Get profile data
        final profileSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('profile')
            .limit(1)
            .get();

        Map<String, dynamic> profileData = {};
        if (profileSnapshot.docs.isNotEmpty) {
          profileData = profileSnapshot.docs[0].data();
        }

        // Get workout count
        final workoutsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('workout_history')
            .get();

        // Get weekly goals
        final weeklyGoalsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('Weekly_Goals')
            .doc('current_week')
            .get();

        users.add({
          'uid': userDoc.id,
          'email': userData['email'] ?? 'No email',
          'name': profileData['name'] ?? 'Unknown',
          'username': profileData['username'] ?? 'Unknown',
          'age': profileData['age'] ?? 0,
          'weight': profileData['weight'] ?? 0,
          'gender': profileData['gender'] ?? 'Unknown',
          'experience': profileData['experience'] ?? 'Unknown',
          'workoutCount': workoutsSnapshot.docs.length,
          'weeklySteps': profileData['weeklySteps'] ?? 0,
          'dailySteps': profileData['dailySteps'] ?? 0,
          'lastActive': profileData['updatedAt'] ?? profileData['createdAt'],
          'profileCompleted': profileData['profileCompleted'] ?? false,
          'hasWeeklyGoals': weeklyGoalsSnapshot.exists,
          'createdAt': userData['createdAt'],
        });
      }

      // Sort by last activity
      users.sort((a, b) {
        final aTime = a['lastActive'] as Timestamp?;
        final bTime = b['lastActive'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return users;
    } catch (e) {
      print('Error getting all users: $e');
      // Return empty list if Firestore access is denied
      return [];
    }
  }

  /// Create a new user (legacy method)
  static Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    required String username,
    int? age,
    double? weight,
    String? gender,
    String? experience,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create profile document
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .collection('profile')
            .add({
          'name': name,
          'username': username,
          'email': email,
          'age': age,
          'weight': weight,
          'gender': gender,
          'experience': experience,
          'profileCompleted': true,
          'dailySteps': 0,
          'weeklySteps': 0,
          'lastResetDate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      }

      return false;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  /// Update user profile (legacy method)
  static Future<bool> updateUser({
    required String userId,
    String? name,
    String? username,
    String? email,
    int? age,
    double? weight,
    String? gender,
    String? experience,
  }) async {
    try {
      // Update user document
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (email != null) updateData['email'] = email;

      await _firestore.collection('users').doc(userId).update(updateData);

      // Update profile document
      final profileSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .limit(1)
          .get();

      if (profileSnapshot.docs.isNotEmpty) {
        final profileDoc = profileSnapshot.docs[0];
        final profileUpdateData = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (name != null) profileUpdateData['name'] = name;
        if (username != null) profileUpdateData['username'] = username;
        if (email != null) profileUpdateData['email'] = email;
        if (age != null) profileUpdateData['age'] = age;
        if (weight != null) profileUpdateData['weight'] = weight;
        if (gender != null) profileUpdateData['gender'] = gender;
        if (experience != null) profileUpdateData['experience'] = experience;

        await profileDoc.reference.update(profileUpdateData);
      }

      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  /// Delete user (legacy method)
  static Future<bool> deleteUser(String userId) async {
    try {
      // Delete user document and all subcollections
      await _firestore.collection('users').doc(userId).delete();

      // Note: Deleting from Firebase Auth requires admin SDK
      // This would typically be done through a backend API
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  /// Get total user count from Cloud Function
  static Future<int> getTotalUserCountFromAuth() async {
    try {
      print('Calling Cloud Function to get total user count...');

      final callable = _functions.httpsCallable('getTotalUserCount');
      final result = await callable.call();

      final totalUsers = result.data['totalUsers'] as int;
      print('Total users from Cloud Function: $totalUsers');
      return totalUsers;
    } catch (e) {
      print('Error getting total user count from Cloud Function: $e');
      // Fallback to admin document
      return await getTotalUserCountFromAdminDoc();
    }
  }

  /// Get total user count from admin document (fallback)
  static Future<int> getTotalUserCountFromAdminDoc() async {
    try {
      print('Trying to get total user count from admin document...');
      final adminDoc = await _firestore
          .collection('admin')
          .doc('71N1ZTeAUol0zHf2ZCiI')
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data();
        final totalUsers = data?['totalUsers'] ?? 0;
        print('Total users from admin document: $totalUsers');
        return totalUsers;
      } else {
        print('Admin document not found, creating it...');
        // Create admin document if it doesn't exist
        await _firestore.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').set({
          'email': 'thatsfitAdmin@gmail.com',
          'role': 'admin',
          'totalUsers': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        return 0;
      }
    } catch (e) {
      print('Error getting total user count from admin document: $e');
      return 0;
    }
  }

  /// Get active users count from Cloud Function
  static Future<int> getActiveUsersCountFromAuth() async {
    try {
      print('Calling Cloud Function to get active user count...');

      final callable = _functions.httpsCallable('getActiveUsersCount');
      final result = await callable.call();

      final activeUsers = result.data['activeUsers'] as int;
      print('Active users from Cloud Function: $activeUsers');
      return activeUsers;
    } catch (e) {
      print('Error getting active user count from Cloud Function: $e');
      return 0;
    }
  }

  /// Get user analytics from Cloud Function
  static Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      print('Calling Cloud Function to get user analytics...');

      final callable = _functions.httpsCallable('getUserAnalytics');
      final result = await callable.call();

      final analytics = Map<String, dynamic>.from(result.data);
      print('Analytics from Cloud Function: $analytics');
      return analytics;
    } catch (e) {
      print('Error getting user analytics from Cloud Function: $e');
      // Fallback to basic analytics
      return await getBasicAnalytics();
    }
  }

  /// Get basic analytics (fallback)
  static Future<Map<String, dynamic>> getBasicAnalytics() async {
    try {
      final totalUsers = await getTotalUserCountFromAdminDoc();

      return {
        'totalUsers': totalUsers,
        'activeUsers': 0,
        'completedProfiles': 0,
        'usersWithWorkouts': 0,
        'completionRate': 0,
        'activityRate': 0,
      };
    } catch (e) {
      print('Error getting basic analytics: $e');
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'completedProfiles': 0,
        'usersWithWorkouts': 0,
        'completionRate': 0,
        'activityRate': 0,
      };
    }
  }

  /// Get daily user activity
  static Future<List<Map<String, dynamic>>> getDailyActivity() async {
    try {
      // This would typically query activity logs
      // For now, return sample data
      return [
        {'date': 'Mon', 'users': 12},
        {'date': 'Tue', 'users': 15},
        {'date': 'Wed', 'users': 8},
        {'date': 'Thu', 'users': 20},
        {'date': 'Fri', 'users': 18},
        {'date': 'Sat', 'users': 25},
        {'date': 'Sun', 'users': 22},
      ];
    } catch (e) {
      print('Error getting daily activity: $e');
      return [];
    }
  }

  /// Test Firestore access
  static Future<void> testFirestoreAccess() async {
    try {
      print('=== FIRESTORE ACCESS TEST ===');
      print('Testing access to users collection...');

      final usersSnapshot = await _firestore.collection('users').get();
      print('Users collection access: SUCCESS');
      print(
          'Total documents in users collection: ${usersSnapshot.docs.length}');

      if (usersSnapshot.docs.isNotEmpty) {
        print('User documents found:');
        for (int i = 0; i < usersSnapshot.docs.length; i++) {
          final doc = usersSnapshot.docs[i];
          print('Document ${i + 1}:');
          print('  ID: ${doc.id}');
          print('  Data: ${doc.data()}');
        }
      } else {
        print('No user documents found in the collection');
      }

      print('=== END FIRESTORE ACCESS TEST ===');
    } catch (e) {
      print('=== FIRESTORE ACCESS TEST FAILED ===');
      print('Error: $e');
      print('=== END FIRESTORE ACCESS TEST ===');
    }
  }

  /// Set initial user count (for testing)
  static Future<void> setInitialUserCount(int count) async {
    try {
      print('Setting initial user count to: $count');
      await _firestore.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').set({
        'email': 'thatsfitAdmin@gmail.com',
        'role': 'admin',
        'totalUsers': count,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('Initial user count set successfully');
    } catch (e) {
      print('Error setting initial user count: $e');
    }
  }

  /// Create admin document with initial data (bypasses permissions)
  static Future<void> createAdminDocument() async {
    try {
      print('Creating admin document with initial data...');

      // Try to create the admin document
      await _firestore.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').set({
        'email': 'thatsfitAdmin@gmail.com',
        'role': 'admin',
        'totalUsers': 1, // Set initial count to 1 for testing
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Admin document created successfully');
    } catch (e) {
      print('Error creating admin document: $e');
      print('This might be due to Firestore permissions.');
    }
  }

  /// Get total user count with fallback (no Firestore dependency)
  static Future<int> getTotalUserCountSimple() async {
    try {
      print('Getting total user count with simple approach...');

      // For now, return a hardcoded value for testing
      // This will be replaced by Cloud Functions later
      return 1; // Return 1 for testing
    } catch (e) {
      print('Error in simple user count: $e');
      return 0;
    }
  }

  /// Make requests to all GET endpoints and store responses in Firebase
  static Future<void> refreshAllEndpoints() async {
    try {
      print('🔄 Making requests to all GET endpoints...');

      final responses = <String, dynamic>{};

      // GET /api/admin/health
      try {
        print('📡 Requesting: GET /api/admin/health');
        final healthResponse = await http.get(
          Uri.parse('$baseUrl/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: 30));

        responses['health'] = {
          'statusCode': healthResponse.statusCode,
          'body': healthResponse.body,
          'timestamp': DateTime.now().toIso8601String(),
        };
        print('✅ Health endpoint response: ${healthResponse.statusCode}');
      } catch (e) {
        print('❌ Health endpoint error: $e');
        responses['health'] = {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      // GET /api/admin/users
      try {
        print('📡 Requesting: GET /api/admin/users');
        final usersResponse = await http.get(
          Uri.parse('$baseUrl/users'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: 30));

        responses['users'] = {
          'statusCode': usersResponse.statusCode,
          'body': usersResponse.body,
          'timestamp': DateTime.now().toIso8601String(),
        };
        print('✅ Users endpoint response: ${usersResponse.statusCode}');
      } catch (e) {
        print('❌ Users endpoint error: $e');
        responses['users'] = {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      // GET /api/admin/users/count
      try {
        print('📡 Requesting: GET /api/admin/users/count');
        final countResponse = await http.get(
          Uri.parse('$baseUrl/users/count'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: 30));

        responses['users_count'] = {
          'statusCode': countResponse.statusCode,
          'body': countResponse.body,
          'timestamp': DateTime.now().toIso8601String(),
        };
        print('✅ Users count endpoint response: ${countResponse.statusCode}');
      } catch (e) {
        print('❌ Users count endpoint error: $e');
        responses['users_count'] = {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      // GET /api/admin/users/active
      try {
        print('📡 Requesting: GET /api/admin/users/active');
        final activeResponse = await http.get(
          Uri.parse('$baseUrl/users/active'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: 30));

        responses['users_active'] = {
          'statusCode': activeResponse.statusCode,
          'body': activeResponse.body,
          'timestamp': DateTime.now().toIso8601String(),
        };
        print('✅ Users active endpoint response: ${activeResponse.statusCode}');
      } catch (e) {
        print('❌ Users active endpoint error: $e');
        responses['users_active'] = {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      // Store all responses in Firebase admin document
      await _firestore.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').set({
        'endpointResponses': responses,
        'lastRefresh': FieldValue.serverTimestamp(),
        'refreshStatus': 'completed',
      }, SetOptions(merge: true));

      print('✅ All endpoint responses stored in Firebase');
    } catch (e) {
      print('❌ Error refreshing endpoints: $e');

      // Store error status in Firebase
      await _firestore.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').set({
        'refreshStatus': 'error',
        'lastError': e.toString(),
        'lastRefresh': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Get admin data from Firebase
  static Future<Map<String, dynamic>> getAdminDataFromFirebase() async {
    try {
      print('📊 Loading admin data from Firebase...');
      final adminDoc = await _firestore
          .collection('admin')
          .doc('71N1ZTeAUol0zHf2ZCiI')
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data()!;
        print('✅ Admin data loaded from Firebase');
        return data;
      } else {
        print(
            '⚠️ No admin data found in Firebase, creating initial document...');
        // Create initial admin document
        await _firestore.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').set({
          'totalUsers': 0,
          'activeUsers': 0,
          'recentUsers': [],
          'lastUpdated': FieldValue.serverTimestamp(),
          'serverStatus': 'initialized',
        });
        return {
          'totalUsers': 0,
          'activeUsers': 0,
          'recentUsers': [],
          'serverStatus': 'initialized',
        };
      }
    } catch (e) {
      print('❌ Error loading admin data from Firebase: $e');
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'recentUsers': [],
        'serverStatus': 'error',
      };
    }
  }

  /// Get total users from Firebase (for UI)
  static Future<int> getTotalUsersFromFirebase() async {
    try {
      final adminData = await getAdminDataFromFirebase();
      return adminData['totalUsers'] ?? 0;
    } catch (e) {
      print('❌ Error getting total users from Firebase: $e');
      return 0;
    }
  }

  /// Get active users from Firebase (for UI)
  static Future<int> getActiveUsersFromFirebase() async {
    try {
      final adminData = await getAdminDataFromFirebase();
      return adminData['activeUsers'] ?? 0;
    } catch (e) {
      print('❌ Error getting active users from Firebase: $e');
      return 0;
    }
  }

  /// Get recent users from Firebase (for UI)
  static Future<List<Map<String, dynamic>>> getRecentUsersFromFirebase() async {
    try {
      final adminData = await getAdminDataFromFirebase();
      final recentUsers = adminData['recentUsers'] ?? [];
      return List<Map<String, dynamic>>.from(recentUsers);
    } catch (e) {
      print('❌ Error getting recent users from Firebase: $e');
      return [];
    }
  }

  /// Get total users from stored endpoint response
  static Future<int> getTotalUsersFromStoredResponse() async {
    try {
      final adminData = await getAdminDataFromFirebase();
      final endpointResponses =
          adminData['endpointResponses'] as Map<String, dynamic>?;

      if (endpointResponses != null &&
          endpointResponses['users_count'] != null) {
        final response = endpointResponses['users_count'];
        if (response['statusCode'] == 200) {
          final data = json.decode(response['body']);
          final totalUsers = data['totalUsers'] ?? 0;
          print('✅ Total users from stored response: $totalUsers');
          return totalUsers;
        }
      }

      // Fallback to existing method
      return await getTotalUsersFromFirebase();
    } catch (e) {
      print('❌ Error getting total users from stored response: $e');
      return await getTotalUsersFromFirebase();
    }
  }

  /// Get active users from stored endpoint response
  static Future<int> getActiveUsersFromStoredResponse() async {
    try {
      final adminData = await getAdminDataFromFirebase();
      final endpointResponses =
          adminData['endpointResponses'] as Map<String, dynamic>?;

      if (endpointResponses != null &&
          endpointResponses['users_active'] != null) {
        final response = endpointResponses['users_active'];
        if (response['statusCode'] == 200) {
          final data = json.decode(response['body']);
          final activeUsers = data['activeUsers'] ?? 0;
          print('✅ Active users from stored response: $activeUsers');
          return activeUsers;
        }
      }

      // Fallback to existing method
      return await getActiveUsersFromFirebase();
    } catch (e) {
      print('❌ Error getting active users from stored response: $e');
      return await getActiveUsersFromFirebase();
    }
  }

  /// Get recent users from stored endpoint response
  static Future<List<Map<String, dynamic>>>
      getRecentUsersFromStoredResponse() async {
    try {
      final adminData = await getAdminDataFromFirebase();
      final endpointResponses =
          adminData['endpointResponses'] as Map<String, dynamic>?;

      if (endpointResponses != null && endpointResponses['users'] != null) {
        final response = endpointResponses['users'];
        if (response['statusCode'] == 200) {
          final data = json.decode(response['body']);
          final users = List<Map<String, dynamic>>.from(data['users'] ?? []);
          print('✅ Recent users from stored response: ${users.length} users');
          return users.take(5).toList(); // Return only first 5rs
        }
      }

      // Fallback to existing method
      return await getRecentUsersFromFirebase();
    } catch (e) {
      print('❌ Error getting recent users from stored response: $e');
      return await getRecentUsersFromFirebase();
    }
  }

  /// Get server health status from stored response
  static Future<String> getServerHealthStatus() async {
    try {
      final adminData = await getAdminDataFromFirebase();
      final endpointResponses =
          adminData['endpointResponses'] as Map<String, dynamic>?;

      if (endpointResponses != null && endpointResponses['health'] != null) {
        final response = endpointResponses['health'];
        if (response['statusCode'] == 200) {
          return 'Online';
        } else {
          return 'Error (${response['statusCode']})';
        }
      }

      return 'Unknown';
    } catch (e) {
      print('❌ Error getting server health status: $e');
      return 'Unknown';
    }
  }

  /// Get last refresh timestamp
  static Future<String> getLastRefreshTime() async {
    try {
      final adminData = await getAdminDataFromFirebase();
      final lastRefresh = adminData['lastRefresh'] as Timestamp?;

      if (lastRefresh != null) {
        final dateTime = lastRefresh.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }

      return 'Never';
    } catch (e) {
      print('❌ Error getting last refresh time: $e');
      return 'Unknown';
    }
  }

  /// Check if admin data needs refresh (older than 5 minutes)
  static Future<bool> shouldRefreshAdminData() async {
    try {
      final adminDoc = await _firestore
          .collection('admin')
          .doc('71N1ZTeAUol0zHf2ZCiI')
          .get();

      if (!adminDoc.exists) return true;

      final data = adminDoc.data()!;
      final lastUpdated = data['lastUpdated'] as Timestamp?;

      if (lastUpdated == null) return true;

      final now = DateTime.now();
      final lastUpdate = lastUpdated.toDate();
      final difference = now.difference(lastUpdate).inMinutes;

      print('⏰ Last update: $lastUpdate, Minutes ago: $difference');
      return difference > 5; // Refresh if older than 5 minutes
    } catch (e) {
      print('❌ Error checking refresh status: $e');
      return true;
    }
  }

  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  static Future<void> createAdminDocumentIfNotExists() async {
    try {
      print('🔧 Creating admin document if not exists...');

      final adminDoc = await _firestore
          .collection('admin')
          .doc('71N1ZTeAUol0zHf2ZCiI')
          .get();

      if (!adminDoc.exists) {
        await _firestore.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').set({
          'email': 'thatsfitAdmin@gmail.com',
          'role': 'admin',
          'totalUsers': 0,
          'activeUsers': 0,
          'recentUsers': [],
          'lastUpdated': FieldValue.serverTimestamp(),
          'serverStatus': 'initialized',
          'endpointResponses': {},
          'lastRefresh': FieldValue.serverTimestamp(),
          'refreshStatus': 'initialized',
        });
        print('✅ Admin document created successfully');
      } else {
        print('✅ Admin document already exists');
      }
    } catch (e) {
      print('❌ Error creating admin document: $e');
    }
  }
}
