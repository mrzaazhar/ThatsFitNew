import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get all users with their profile data
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

  /// Create a new user
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

  /// Update user profile
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

  /// Delete user
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
        print('Admin document created with initial count: 0');
        return 0;
      }
    } catch (e) {
      print('Error getting total user count from admin document: $e');
      print('This might be due to Firestore permissions. Using fallback...');
      return 0;
    }
  }

  /// Update total user count in admin document
  static Future<void> updateTotalUserCount(int count) async {
    try {
      print('Updating total user count to: $count');
      await _firestore.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').update({
        'totalUsers': count,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('Total user count updated successfully');
    } catch (e) {
      print('Error updating total user count: $e');
    }
  }

  /// Increment total user count (call this when a new user registers)
  static Future<void> incrementUserCount() async {
    try {
      print('Incrementing user count...');
      final adminDoc = await _firestore
          .collection('admin')
          .doc('71N1ZTeAUol0zHf2ZCiI')
          .get();

      int currentCount = 0;
      if (adminDoc.exists) {
        currentCount = adminDoc.data()?['totalUsers'] ?? 0;
      }

      final newCount = currentCount + 1;
      await updateTotalUserCount(newCount);
      print('User count incremented to: $newCount');
    } catch (e) {
      print('Error incrementing user count: $e');
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
}
