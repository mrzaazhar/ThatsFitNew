import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuth {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Admin credentials
  static const String ADMIN_EMAIL = 'thatsfitAdmin@gmail.com';
  static const String ADMIN_PASSWORD = 'thatsfitAdmin';

  /// Check if current user is admin
  static Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user is the admin
      return user.email == ADMIN_EMAIL;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Login as admin
  static Future<bool> loginAsAdmin() async {
    try {
      // Try to sign in with admin credentials
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
      );

      if (userCredential.user != null) {
        print('Admin login successful');
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during admin login: ${e.code} - ${e.message}');
      
      // If user doesn't exist, create the admin account
      if (e.code == 'user-not-found') {
        print('Admin account not found, creating new admin account...');
        return await _createAdminAccount();
      }
      
      return false;
    } catch (e) {
      print('Error logging in as admin: $e');
      return false;
    }
  }

  /// Create admin account
  static Future<bool> _createAdminAccount() async {
    try {
      // Create user with admin credentials
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
      );

      if (userCredential.user != null) {
        print('Admin account created successfully');
        
        // Try to create admin document in Firestore (optional)
        try {
          await _firestore
              .collection('admin')
              .doc(userCredential.user!.uid)
              .set({
            'email': ADMIN_EMAIL,
            'role': 'admin',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
          print('Admin document created in Firestore');
        } catch (firestoreError) {
          print('Warning: Could not create admin document in Firestore: $firestoreError');
          print('Admin login will still work without Firestore access');
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error creating admin account: $e');
      return false;
    }
  }

  /// Logout admin
  static Future<void> logoutAdmin() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error logging out admin: $e');
    }
  }

  /// Get admin info
  static Future<Map<String, dynamic>?> getAdminInfo() async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email == ADMIN_EMAIL) {
        return {
          'email': user.email,
          'role': 'admin',
          'uid': user.uid,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting admin info: $e');
      return null;
    }
  }
} 