const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK with service account
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

const app = express();
const PORT = 3002;

// Middleware
app.use(cors());
app.use(express.json());

// Helper function to get total users with fallback
async function getTotalUsersWithFallback() {
  try {
    console.log('Trying direct Firebase Auth...');
    const listUsersResult = await auth.listUsers();
    const totalUsers = listUsersResult.users.length;
    console.log(`Found ${totalUsers} users via direct Firebase Auth`);
    return totalUsers;
  } catch (error) {
    console.log('Direct Firebase Auth failed, trying Cloud Functions...');
    // You could call Cloud Functions here if needed
    return 0;
  }
}

// Helper function to get active users with fallback
async function getActiveUsersWithFallback() {
  try {
    console.log('Trying direct Firestore...');
    const usersSnapshot = await db.collection('users').get();
    let activeUsers = 0;

    for (const userDoc of usersSnapshot.docs) {
      const profileSnapshot = await userDoc.ref.collection('profile').limit(1).get();
      if (!profileSnapshot.empty) {
        const profileData = profileSnapshot.docs[0].data();
        if (profileData.updatedAt) {
          const lastActive = profileData.updatedAt.toDate();
          const daysSinceActive = (Date.now() - lastActive.getTime()) / (1000 * 60 * 60 * 24);
          if (daysSinceActive <= 7) {
            activeUsers++;
          }
        }
      }
    }
    console.log(`Found ${activeUsers} active users via direct Firestore`);
    return activeUsers;
  } catch (error) {
    console.log('Direct Firestore failed, trying Cloud Functions...');
    // You could call Cloud Functions here if needed
    return 0;
  }
}

// API Routes
app.get('/api/admin/users', async (req, res) => {
  console.log('=== GET /api/admin/users ===');
  console.log('Request received at:', new Date().toISOString());
  
  try {
    console.log('Fetching users from Firebase Auth...');
    // List all users using Admin SDK
    const listUsersResult = await auth.listUsers(1000);
    console.log(`Found ${listUsersResult.users.length} users in Firebase Auth`);
    
    const usersWithProfiles = [];

    for (const userRecord of listUsersResult.users) {
      console.log(`Processing user: ${userRecord.email} (${userRecord.uid})`);
      try {
        // Get profile data
        console.log(`  Fetching profile for user ${userRecord.uid}...`);
        const profileSnapshot = await db.collection('users').doc(userRecord.uid).collection('profile').limit(1).get();
        let profileData = {};
        
        if (!profileSnapshot.empty) {
          profileData = profileSnapshot.docs[0].data();
          console.log(`  Profile found:`, profileData);
        } else {
          console.log(`  No profile found for user ${userRecord.uid}`);
        }

        // Get workout count
        console.log(`  Fetching workout history for user ${userRecord.uid}...`);
        const workoutsSnapshot = await db.collection('users').doc(userRecord.uid).collection('workout_history').get();
        console.log(`  Found ${workoutsSnapshot.docs.length} workouts for user ${userRecord.uid}`);

        const userData = {
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
        };
        
        usersWithProfiles.push(userData);
        console.log(`  User data prepared:`, userData);
      } catch (error) {
        console.error(`Error getting profile for user ${userRecord.uid}:`, error);
        // Include user with basic info even if profile fetch fails
        const basicUserData = {
          uid: userRecord.uid,
          email: userRecord.email,
          displayName: userRecord.displayName,
          emailVerified: userRecord.emailVerified,
          disabled: userRecord.disabled,
          createdAt: userRecord.metadata.creationTime,
          lastSignInTime: userRecord.metadata.lastSignInTime,
          profileCompleted: false
        };
        usersWithProfiles.push(basicUserData);
        console.log(`  Added basic user data due to error:`, basicUserData);
      }
    }

    console.log(`Returning ${usersWithProfiles.length} users to client`);
    res.json({ users: usersWithProfiles });
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ error: 'Failed to get users' });
  }
  console.log('=== END GET /api/admin/users ===\n');
});

app.get('/api/admin/users/count', async (req, res) => {
  console.log('=== GET /api/admin/users/count ===');
  console.log('Request received at:', new Date().toISOString());
  
  try {
    const totalUsers = await getTotalUsersWithFallback();
    console.log(`Total users: ${totalUsers}`);

    console.log('Updating admin document with user count...');
    // Update admin document with the count
    await db.collection('admin').doc('71N1ZTeAUol0zHf2ZCiI').update({
      totalUsers: totalUsers,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('Admin document updated successfully');

    console.log(`Returning total users count: ${totalUsers}`);
    res.json({ totalUsers: totalUsers });
  } catch (error) {
    console.error('Error getting user count:', error);
    res.status(500).json({ error: 'Failed to get user count' });
  }
  console.log('=== END GET /api/admin/users/count ===\n');
});

app.get('/api/admin/users/active', async (req, res) => {
  console.log('=== GET /api/admin/users/active ===');
  console.log('Request received at:', new Date().toISOString());
  
  try {
    const activeUsers = await getActiveUsersWithFallback();
    console.log(`Total active users: ${activeUsers}`);
    res.json({ activeUsers: activeUsers });
  } catch (error) {
    console.error('Error getting active users count:', error);
    res.status(500).json({ error: 'Failed to get active users count' });
  }
  console.log('=== END GET /api/admin/users/active ===\n');
});

app.post('/api/admin/users', async (req, res) => {
  console.log('=== POST /api/admin/users ===');
  console.log('Request received at:', new Date().toISOString());
  console.log('Request body:', req.body);
  
  try {
    const { email, password, displayName, name, username, age, weight, gender, experience } = req.body;
    
    if (!email || !password) {
      console.log('Validation failed: Email and password are required');
      return res.status(400).json({ error: 'Email and password are required' });
    }

    console.log(`Creating user in Firebase Auth with email: ${email}`);
    // Create user in Firebase Auth
    const userRecord = await auth.createUser({ 
      email, 
      password, 
      displayName: displayName || name 
    });
    console.log(`User created in Firebase Auth: ${userRecord.uid}`);

    console.log(`Creating user document in Firestore for: ${userRecord.uid}`);
    // Create user document in Firestore
    await db.collection('users').doc(userRecord.uid).set({
      email: email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log('User document created in Firestore');

    console.log(`Creating profile document for: ${userRecord.uid}`);
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
    console.log(`Profile document created with ID: ${profileRef.id}`);

    const response = {
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: userRecord.displayName,
      profileId: profileRef.id,
      message: 'User created successfully'
    };
    console.log('User creation successful, returning:', response);
    res.status(201).json(response);
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Failed to create user' });
  }
  console.log('=== END POST /api/admin/users ===\n');
});

app.put('/api/admin/users/:uid', async (req, res) => {
  console.log('=== PUT /api/admin/users/:uid ===');
  console.log('Request received at:', new Date().toISOString());
  console.log('User ID:', req.params.uid);
  console.log('Update data:', req.body);
  
  try {
    const { uid } = req.params;
    const { updateData } = req.body;
    
    if (!uid || !updateData) {
      console.log('Validation failed: User ID and update data are required');
      return res.status(400).json({ error: 'User ID and update data are required' });
    }

    console.log(`Updating Firebase Auth user: ${uid}`);
    // Update Firebase Auth user
    const authUpdateData = {};
    if (updateData.email) authUpdateData.email = updateData.email;
    if (updateData.displayName) authUpdateData.displayName = updateData.displayName;
    if (updateData.disabled !== undefined) authUpdateData.disabled = updateData.disabled;

    if (Object.keys(authUpdateData).length > 0) {
      await auth.updateUser(uid, authUpdateData);
      console.log('Firebase Auth user updated successfully');
    } else {
      console.log('No Firebase Auth updates needed');
    }

    console.log(`Updating Firestore user document: ${uid}`);
    // Update Firestore user document
    const userUpdateData = {};
    if (updateData.email) userUpdateData.email = updateData.email;
    if (Object.keys(userUpdateData).length > 0) {
      userUpdateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      await db.collection('users').doc(uid).update(userUpdateData);
      console.log('Firestore user document updated successfully');
    } else {
      console.log('No Firestore user document updates needed');
    }

    console.log(`Updating profile document for user: ${uid}`);
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
      console.log('Profile document updated successfully');
    } else {
      console.log('No profile document found to update');
    }

    console.log('User update completed successfully');
    res.json({ success: true, message: 'User updated successfully' });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
  console.log('=== END PUT /api/admin/users/:uid ===\n');
});

app.delete('/api/admin/users/:uid', async (req, res) => {
  console.log('=== DELETE /api/admin/users/:uid ===');
  console.log('Request received at:', new Date().toISOString());
  console.log('User ID:', req.params.uid);
  
  try {
    const { uid } = req.params;
    
    if (!uid) {
      console.log('Validation failed: User ID is required');
      return res.status(400).json({ error: 'User ID is required' });
    }

    console.log(`Deleting user from Firebase Auth: ${uid}`);
    // Delete user from Firebase Auth using Admin SDK
    await auth.deleteUser(uid);
    console.log('User deleted from Firebase Auth successfully');

    console.log(`Deleting user data from Firestore: ${uid}`);
    // Delete user data from Firestore
    await db.collection('users').doc(uid).delete();
    console.log('User data deleted from Firestore successfully');

    console.log('User deletion completed successfully');
    res.json({ success: true, message: 'User deleted successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Failed to delete user' });
  }
  console.log('=== END DELETE /api/admin/users/:uid ===\n');
});

// Health check endpoint
app.get('/api/admin/health', (req, res) => {
  console.log('=== GET /api/admin/health ===');
  console.log('Health check request received at:', new Date().toISOString());
  res.json({ status: 'OK', message: 'Admin server is running' });
  console.log('=== END GET /api/admin/health ===\n');
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log('==========================================');
  console.log('🚀 ADMIN SERVER STARTED SUCCESSFULLY');
  console.log('==========================================');
  console.log(`📍 Server running on port: ${PORT}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/api/admin/health`);
  console.log(`📊 Admin API: http://localhost:${PORT}/api/admin`);
  console.log('==========================================');
  console.log('📝 Available endpoints:');
  console.log('   GET  /api/admin/health');
  console.log('   GET  /api/admin/users');
  console.log('   GET  /api/admin/users/count');
  console.log('   GET  /api/admin/users/active');
  console.log('   POST /api/admin/users');
  console.log('   PUT  /api/admin/users/:uid');
  console.log('   DELETE /api/admin/users/:uid');
  console.log('==========================================\n');
}); 