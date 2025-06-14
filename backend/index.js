const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
require('dotenv').config();
const { getWorkoutRecommendation } = require('./flowise');

const app = express();
const port = 3001; // Force port 3001

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin
const serviceAccount = {
  type: process.env.FIREBASE_TYPE,
  project_id: process.env.FIREBASE_PROJECT_ID,
  private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
  private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
  client_id: process.env.FIREBASE_CLIENT_ID,
  auth_uri: process.env.FIREBASE_AUTH_URI,
  token_uri: process.env.FIREBASE_TOKEN_URI,
  auth_provider_x509_cert_url: process.env.FIREBASE_AUTH_PROVIDER_CERT_URL,
  client_x509_cert_url: process.env.FIREBASE_CLIENT_CERT_URL,
  universe_domain: process.env.FIREBASE_UNIVERSE_DOMAIN
};

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Get all users
app.get('/api/users', async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const users = [];
    snapshot.forEach(doc => {
      users.push({
        id: doc.id,
        ...doc.data()
      });
    });
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get a specific user by ID
app.get('/api/users/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({
      id: userDoc.id,
      ...userDoc.data()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create a new user
app.post('/api/users', async (req, res) => {
  try {
    const userData = req.body;
    const docRef = await db.collection('users').add({
      ...userData,
      dailySteps: 0,
      weeklySteps: 0,
      lastResetDate: new Date().toISOString().split('T')[0],
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    res.status(201).json({
      id: docRef.id,
      message: 'User created successfully'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user's step count - only updates steps, doesn't trigger workout creation
app.put('/api/users/:userId/steps', async (req, res) => {
  try {
    const { userId } = req.params;
    const { steps } = req.body;
    
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();
    const currentDate = new Date().toISOString().split('T')[0];
    
    // Only update step counts, no workout creation
    if (userData.lastResetDate !== currentDate) {
      await userRef.update({
        dailySteps: steps,
        weeklySteps: (userData.weeklySteps || 0) + steps,
        lastResetDate: currentDate,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } else {
      // Calculate the step difference for weekly total
      const stepDifference = steps - (userData.dailySteps || 0);
      await userRef.update({
        dailySteps: steps,
        weeklySteps: (userData.weeklySteps || 0) + stepDifference,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // Return success without triggering workout creation
    res.json({ 
      message: 'Step count updated successfully',
      dailySteps: steps,
      weeklySteps: userData.weeklySteps + (userData.lastResetDate !== currentDate ? steps : stepDifference)
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create workout endpoint - only fetches data when explicitly called
app.post('/api/users/:userId/create-workout', async (req, res) => {
  try {
    const { userId } = req.params;
    console.log('\n=== Create Workout Request Received ===');
    console.log('User ID:', userId);
    console.log('Request headers:', req.headers);
    console.log('Request body:', req.body);

    if (!userId) {
      throw new Error('User ID is required');
    }

    // Get workout recommendation using the flowise functions
    console.log('Calling getWorkoutRecommendation...');
    const result = await getWorkoutRecommendation(userId);
    
    console.log('\n=== Sending Response to Client ===');
    console.log('Response status: 201');
    console.log('Response data:', result);
    
    res.status(201).json(result);
  } catch (error) {
    console.error('Error in create-workout endpoint:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({ 
      error: 'Failed to create workout',
      details: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
}); 