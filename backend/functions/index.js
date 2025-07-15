const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

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

// Cloud Function to increment user count when new user registers
exports.incrementUserCount = functions.auth.user().onCreate(async (user) => {
  try {
    console.log('New user created:', user.uid);
    
    // Get current count from admin document
    const adminDoc = await db.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').get();
    let currentCount = 0;
    
    if (adminDoc.exists) {
      currentCount = adminDoc.data().totalUsers || 0;
    } else {
      // Create admin document if it doesn't exist
      await db.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').set({
        email: 'thatsfitAdmin@gmail.com',
        role: 'admin',
        totalUsers: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // Increment the count
    const newCount = currentCount + 1;
    await db.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').update({
      totalUsers: newCount,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`User count incremented to: ${newCount}`);
  } catch (error) {
    console.error('Error incrementing user count:', error);
  }
});

// Cloud Function to get user analytics
exports.getUserAnalytics = functions.https.onCall(async (data, context) => {
  try {
    // Verify admin access
    if (!context.auth || context.auth.token.email !== 'thatsfitAdmin@gmail.com') {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    // Get total users from Admin SDK
    const listUsersResult = await auth.listUsers();
    const totalUsers = listUsersResult.users.length;

    // Get additional analytics from Firestore
    const usersSnapshot = await db.collection('users').get();
    let completedProfiles = 0;
    let activeUsers = 0;
    let usersWithWorkouts = 0;

    for (const userDoc of usersSnapshot.docs) {
      // Check profile completion
      const profileSnapshot = await userDoc.ref.collection('profile').limit(1).get();
      if (!profileSnapshot.empty) {
        const profileData = profileSnapshot.docs[0].data();
        if (profileData.profileCompleted === true) {
          completedProfiles++;
        }

        // Check if user is active (last 7 days)
        if (profileData.updatedAt) {
          const lastActive = profileData.updatedAt.toDate();
          const daysSinceActive = (Date.now() - lastActive.getTime()) / (1000 * 60 * 60 * 24);
          if (daysSinceActive <= 7) {
            activeUsers++;
          }
        }
      }

      // Check if user has workouts
      const workoutsSnapshot = await userDoc.ref.collection('workout_history').get();
      if (!workoutsSnapshot.empty) {
        usersWithWorkouts++;
      }
    }

    return {
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      completedProfiles: completedProfiles,
      usersWithWorkouts: usersWithWorkouts,
      completionRate: totalUsers > 0 ? Math.round((completedProfiles / totalUsers) * 100) : 0,
      activityRate: totalUsers > 0 ? Math.round((activeUsers / totalUsers) * 100) : 0
    };
  } catch (error) {
    console.error('Error getting user analytics:', error);
    throw new functions.https.HttpsError('internal', 'Failed to get analytics');
  }
});

// Cloud Function to delete user (Admin SDK required)
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

    // Decrement user count
    const adminDoc = await db.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').get();
    if (adminDoc.exists) {
      const currentCount = adminDoc.data().totalUsers || 0;
      const newCount = Math.max(0, currentCount - 1);
      await db.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').update({
        totalUsers: newCount,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    return { success: true, message: 'User deleted successfully' };
  } catch (error) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to delete user');
  }
}); 