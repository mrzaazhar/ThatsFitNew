const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const axios = require('axios');
const fs = require('fs');
require('dotenv').config();

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

// User-specific endpoints

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

// Update user data
app.put('/api/users/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const userData = req.body;
    await db.collection('users').doc(userId).update({
      ...userData,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    res.json({ message: 'User updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user's step count
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
    
    // Check if we need to reset daily steps
    if (userData.lastResetDate !== currentDate) {
      await userRef.update({
        dailySteps: steps,
        weeklySteps: (userData.weeklySteps || 0) + steps,
        lastResetDate: currentDate,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } else {
      await userRef.update({
        dailySteps: steps,
        weeklySteps: (userData.weeklySteps || 0) + (steps - (userData.dailySteps || 0)),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    res.json({ message: 'Step count updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create workout with user data and Flowise integration
app.post('/api/users/:userId/create-workout', async (req, res) => {
  try {
    const { userId } = req.params;

    // Get user data from Firestore
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Get the user data from Firebase
    const userData = userDoc.data();
    console.log('\n=== Firebase User Data ===');
    console.log('User Data from Firebase:', userData);

    // Prepare data for Flowise using Firebase data
    const flowiseData = {
      question: "Create a workout plan",
      history: [],
      overrideConfig: {},
      returnSourceDocuments: true,
      // Use the data directly from Firebase
      age: userData.age?.toString(),
      weight: userData.weight?.toString(),
      gender: userData.gender,
      trainingExperience: userData.trainingExperience || userData.experience, // Check both possible field names
      stepCount: userData.dailySteps?.toString()
    };

    console.log('\n=== Flowise Request Details ===');
    console.log('User ID:', userId);
    console.log('Flowise Request Data:', flowiseData);

    if (!process.env.FLOWISE_API_URL) {
      throw new Error('FLOWISE_API_URL is not configured');
    }

    if (!process.env.FLOWISE_API_KEY) {
      throw new Error('FLOWISE_API_KEY is not configured');
    }

    // Validate Flowise URL format
    try {
      new URL(process.env.FLOWISE_API_URL);
    } catch (e) {
      throw new Error(`Invalid FLOWISE_API_URL format: ${process.env.FLOWISE_API_URL}`);
    }

    console.log('\n=== Flowise API Call ===');
    console.log('API URL:', process.env.FLOWISE_API_URL);
    console.log('Request Headers:', {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.FLOWISE_API_KEY}`,
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      'timestamp': Date.now().toString()
    });
    console.log('Request Body:', JSON.stringify(flowiseData, null, 2));

    try {
      const flowiseResponse = await axios.post(process.env.FLOWISE_API_URL, flowiseData, {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${process.env.FLOWISE_API_KEY}`,
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'timestamp': Date.now().toString()
        },
        timeout: 30000 // 30 second timeout
      });

      console.log('\n=== Flowise Response ===');
      console.log('Status:', flowiseResponse.status);
      console.log('Response Headers:', flowiseResponse.headers);
      console.log('Response Data:', JSON.stringify(flowiseResponse.data, null, 2));

      // Parse the Flowise response
      const flowiseText = flowiseResponse.data.text || '';
      console.log('Flowise Text Response:', flowiseText);

      // Create a structured workout plan from the response
      const workoutPlan = {
        name: 'Custom Workout Plan',
        duration: '30-45 min',
        calories: '200-300',
        difficulty: userData.trainingExperience || userData.experience,
        description: flowiseText,
        exercises: flowiseText.split('\n').filter(line => line.trim().length > 0),
      };

      console.log('\n=== Processed Workout Plan ===');
      console.log('Workout Plan:', JSON.stringify(workoutPlan, null, 2));

      // Only return the workout plan in the response
      console.log('\n=== Sending Response to Client ===');
      console.log({
        message: 'Workout created successfully',
        workoutPlan
      });
      res.status(201).json({
        message: 'Workout created successfully',
        workoutPlan
      });
    } catch (flowiseError) {
      console.error('\n=== Flowise API Error ===');
      console.error('Error details:', flowiseError.message);
      if (flowiseError.response) {
        console.error('Response status:', flowiseError.response.status);
        console.error('Response data:', flowiseError.response.data);
        console.error('Response headers:', flowiseError.response.headers);
      }
      if (flowiseError.request) {
        console.error('Request details:', {
          method: flowiseError.request.method,
          path: flowiseError.request.path,
          headers: flowiseError.request.getHeaders?.()
        });
      }
      throw new Error(`Flowise API Error: ${flowiseError.message}`);
    }
  } catch (error) {
    console.error('\n=== Error in create-workout ===');
    console.error('Error details:', error.message);
    console.error('Stack trace:', error.stack);
    res.status(500).json({ error: error.message });
  }
});

// Get user's workout history
app.get('/api/users/:userId/workouts', async (req, res) => {
  try {
    const { userId } = req.params;
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();
    res.json({
      currentWorkout: userData.currentWorkout || null,
      lastWorkoutCreated: userData.lastWorkoutCreated || null
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
}); 