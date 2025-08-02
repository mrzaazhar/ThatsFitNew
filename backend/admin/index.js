const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK with service account
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

// Cloud Function to get total user count
exports.getTotalUserCount = functions.https.onCall(async (data, context) => {
  try {
    // Verify the request is from an admin user
    if (!context.auth || context.auth.token.email !== 'thatsfitAdmin@gmail.com') {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    // List all users using Admin SDK
    const listUsersResult = await auth.listUsers();
    const totalUsers = listUsersResult.users.length;

    // Update admin document with the count
    await db.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').update({
      totalUsers: totalUsers,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });

    return { totalUsers: totalUsers };
  } catch (error) {
    console.error('Error getting total user count:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get user count');
  }
});

// Cloud Function to get active users count
exports.getActiveUsersCount = functions.https.onCall(async (data, context) => {
  try {
    // Verify admin access
    if (!context.auth || context.auth.token.email !== 'thatsfitAdmin@gmail.com') {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    // Get all users from Firestore
    const usersSnapshot = await db.collection('users').get();
    let activeUsers = 0;

    for (const userDoc of usersSnapshot.docs) {
      // Check profile for last activity
      const profileSnapshot = await userDoc.ref.collection('profile').limit(1).get();
      if (!profileSnapshot.empty) {
        const profileData = profileSnapshot.docs[0].data();
        
        // Check if user is active (last 7 days)
        if (profileData.updatedAt) {
          const lastActive = profileData.updatedAt.toDate();
          const daysSinceActive = (Date.now() - lastActive.getTime()) / (1000 * 60 * 60 * 24);
          if (daysSinceActive <= 7) {
            activeUsers++;
          }
        }
      }
    }

    return { activeUsers: activeUsers };
  } catch (error) {
    console.error('Error getting active users count:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get active users count');
  }
});

// Cloud Function to create user (Admin SDK)
exports.createUser = functions.https.onCall(async (data, context) => {
  try {
    // Verify admin access
    if (!context.auth || context.auth.token.email !== 'thatsfitAdmin@gmail.com') {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    const { email, password, displayName, name, username, age, weight, gender, experience } = data;
    
    if (!email || !password) {
      throw new functions.https.HttpsError('invalid-argument', 'Email and password are required');
    }

    // Create user in Firebase Auth
    const userRecord = await auth.createUser({ 
      email, 
      password, 
      displayName: displayName || name 
    });

    // Create user document in Firestore
    await db.collection('users').doc(userRecord.uid).set({
      email: email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create profile document
    const profileRef = await db.collection('users').doc(userRecord.uid).collection('profile').add({
      name: name || displayName,
      username: username,
      email: email,
      age: age,
      weight: weight,
      gender: gender,
      experience: experience,
      profileCompleted: true,
      dailySteps: 0,
      weeklySteps: 0,
      lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: userRecord.displayName,
      profileId: profileRef.id,
      message: 'User created successfully'
    };
  } catch (error) {
    console.error('Error creating user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create user');
  }
});

// Cloud Function to update user (Admin SDK)
exports.updateUser = functions.https.onCall(async (data, context) => {
  try {
    // Verify admin access
    if (!context.auth || context.auth.token.email !== 'thatsfitAdmin@gmail.com') {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    const { uid, updateData } = data;
    if (!uid || !updateData) {
      throw new functions.https.HttpsError('invalid-argument', 'User ID and update data are required');
    }

    // Update Firebase Auth user
    const authUpdateData = {};
    if (updateData.email) authUpdateData.email = updateData.email;
    if (updateData.displayName) authUpdateData.displayName = updateData.displayName;
    if (updateData.disabled !== undefined) authUpdateData.disabled = updateData.disabled;

    if (Object.keys(authUpdateData).length > 0) {
      await auth.updateUser(uid, authUpdateData);
    }

    // Update Firestore user document
    const userUpdateData = {};
    if (updateData.email) userUpdateData.email = updateData.email;
    if (Object.keys(userUpdateData).length > 0) {
      userUpdateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      await db.collection('users').doc(uid).update(userUpdateData);
    }

    // Update profile document
    const profileSnapshot = await db.collection('users').doc(uid).collection('profile').limit(1).get();
    if (profileSnapshot.docs.length > 0) {
      const profileDoc = profileSnapshot.docs[0];
      const profileUpdateData = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (updateData.name) profileUpdateData.name = updateData.name;
      if (updateData.username) profileUpdateData.username = updateData.username;
      if (updateData.email) profileUpdateData.email = updateData.email;
      if (updateData.age !== undefined) profileUpdateData.age = updateData.age;
      if (updateData.weight !== undefined) profileUpdateData.weight = updateData.weight;
      if (updateData.gender) profileUpdateData.gender = updateData.gender;
      if (updateData.experience) profileUpdateData.experience = updateData.experience;

      await profileDoc.ref.update(profileUpdateData);
    }

    return { success: true, message: 'User updated successfully' };
  } catch (error) {
    console.error('Error updating user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update user');
  }
});

// Cloud Function to delete user (Admin SDK)
exports.deleteUser = functions.https.onCall(async (data, context) => {
  try {
    // Verify admin access
    if (!context.auth || context.auth.token.email !== 'thatsfitAdmin@gmail.com') {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    const { userId } = data;
    if (!userId) {
      throw new functions.https.HttpsError('invalid-argument', 'User ID is required');
    }

    // Delete user from Firebase Auth using Admin SDK
    await auth.deleteUser(userId);

    // Delete user data from Firestore
    await db.collection('users').doc(userId).delete();

    return { success: true, message: 'User deleted successfully' };
  } catch (error) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to delete user');
  }
});

// Cloud Function to list all users (Admin SDK)
exports.listAllUsers = functions.https.onCall(async (data, context) => {
  try {
    // Verify admin access
    if (!context.auth || context.auth.token.email !== 'thatsfitAdmin@gmail.com') {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    // List all users using Admin SDK
    const listUsersResult = await auth.listUsers(1000);
    const usersWithProfiles = [];

    for (const userRecord of listUsersResult.users) {
      try {
        // Get profile data
        const profileSnapshot = await db.collection('users').doc(userRecord.uid).collection('profile').limit(1).get();
        let profileData = {};
        
        if (!profileSnapshot.empty) {
          profileData = profileSnapshot.docs[0].data();
        }

        // Get workout count
        const workoutsSnapshot = await db.collection('users').doc(userRecord.uid).collection('workout_history').get();

        usersWithProfiles.push({
          uid: userRecord.uid,
          email: userRecord.email,
          displayName: userRecord.displayName,
          emailVerified: userRecord.emailVerified,
          disabled: userRecord.disabled,
          createdAt: userRecord.metadata.creationTime,
          lastSignInTime: userRecord.metadata.lastSignInTime,
          profileCompleted: profileData.profileCompleted || false,
          name: profileData.name || 'Unknown',
          username: profileData.username || 'Unknown',
          age: profileData.age || 0,
          weight: profileData.weight || 0,
          gender: profileData.gender || 'Unknown',
          experience: profileData.experience || 'Unknown',
          workoutCount: workoutsSnapshot.docs.length,
          weeklySteps: profileData.weeklySteps || 0,
          dailySteps: profileData.dailySteps || 0,
          lastActive: profileData.updatedAt || profileData.createdAt,
        });
      } catch (error) {
        console.error(`Error getting profile for user ${userRecord.uid}:`, error);
        // Include user with basic info even if profile fetch fails
        usersWithProfiles.push({
          uid: userRecord.uid,
          email: userRecord.email,
          displayName: userRecord.displayName,
          emailVerified: userRecord.emailVerified,
          disabled: userRecord.disabled,
          createdAt: userRecord.metadata.creationTime,
          lastSignInTime: userRecord.metadata.lastSignInTime,
          profileCompleted: false
        });
      }
    }

    return { users: usersWithProfiles };
  } catch (error) {
    console.error('Error listing users:', error);
    throw new functions.https.HttpsError('internal', 'Failed to list users');
  }
}); 