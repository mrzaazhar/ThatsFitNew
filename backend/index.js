const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const axios = require('axios');
const fs = require('fs');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin
// You'll need to download your Firebase service account key and save it as 'serviceAccountKey.json'
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Example REST endpoints

// Get all documents from a collection
app.get('/api/:collection', async (req, res) => {
  try {
    const { collection } = req.params;
    const snapshot = await db.collection(collection).get();
    const documents = [];
    snapshot.forEach(doc => {
      documents.push({
        id: doc.id,
        ...doc.data()
      });
    });
    res.json(documents);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get a specific document by ID
app.get('/api/:collection/:id', async (req, res) => {
  try {
    const { collection, id } = req.params;
    const doc = await db.collection(collection).doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Document not found' });
    }
    res.json({
      id: doc.id,
      ...doc.data()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create a new document
app.post('/api/:collection', async (req, res) => {
  try {
    const { collection } = req.params;
    const data = req.body;
    const docRef = await db.collection(collection).add(data);
    res.status(201).json({
      id: docRef.id,
      message: 'Document created successfully'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update a document
app.put('/api/:collection/:id', async (req, res) => {
  try {
    const { collection, id } = req.params;
    const data = req.body;
    await db.collection(collection).doc(id).update(data);
    res.json({ message: 'Document updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete a document
app.delete('/api/:collection/:id', async (req, res) => {
  try {
    const { collection, id } = req.params;
    await db.collection(collection).doc(id).delete();
    res.json({ message: 'Document deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create workout with user data and Flowise integration
app.post('/api/create-workout', async (req, res) => {
  try {
    const { userId, stepCount, age, trainingExperience, gender, weight } = req.body;

    // Validate required fields
    if (!userId || !stepCount || !age || !trainingExperience || !gender || !weight) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Get user data from Firestore
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Prepare data for Flowise
    const flowiseData = {
      stepCount,
      age,
      trainingExperience,
      gender,
      weight
    };

    console.log('Calling Flowise API...');
    console.log('URL:', process.env.FLOWISE_API_URL);
    console.log('Headers:', {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.FLOWISE_API_KEY}`,
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      'timestamp': Date.now().toString()
    });
    console.log('Body:', flowiseData);

    const flowiseResponse = await axios.post(process.env.FLOWISE_API_URL, flowiseData, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.FLOWISE_API_KEY}`,
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'timestamp': Date.now().toString()
      }
    });

    console.log('Flowise Response Status:', flowiseResponse.status);
    console.log('Flowise Response Data (truncated):', JSON.stringify(flowiseResponse.data).substring(0, 500) + '...');

    // Map Flowise response to expected format
    const flowiseDataRaw = flowiseResponse.data;
    const workoutPlan = {
      name: flowiseDataRaw.name || 'Custom Workout',
      duration: flowiseDataRaw.duration || '30 min',
      calories: flowiseDataRaw.calories || '200-300',
      difficulty: flowiseDataRaw.difficulty || 'Intermediate',
      description: flowiseDataRaw.description || 'A personalized workout plan based on your profile and activity.',
      exercises: Array.isArray(flowiseDataRaw.exercises)
        ? flowiseDataRaw.exercises
        : (typeof flowiseDataRaw.exercises === 'string'
            ? flowiseDataRaw.exercises.split('\n')
            : ['Custom exercises will be displayed here']),
    };

    // Save workout data to Firestore
    const workoutData = {
      userId,
      stepCount,
      age,
      trainingExperience,
      gender,
      weight,
      workoutPlan,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const workoutRef = await db.collection('workouts').add(workoutData);

    res.status(201).json({
      id: workoutRef.id,
      message: 'Workout created successfully',
      workoutPlan
    });
  } catch (error) {
    console.error('Error creating workout:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get step counts and user data for Flowise
app.get('/api/user-data/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    // Get user data from Firestore
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Get step counts for the last 7 days
    const today = new Date();
    const sevenDaysAgo = new Date(today);
    sevenDaysAgo.setDate(today.getDate() - 7);

    const stepCountsSnapshot = await db
      .collection('step_counts')
      .doc(userId)
      .collection('daily_counts')
      .where('date', '>=', sevenDaysAgo.toISOString().split('T')[0])
      .get();

    const stepCounts = stepCountsSnapshot.docs.map(doc => ({
      date: doc.data().date,
      steps: doc.data().steps,
      timestamp: doc.data().timestamp?.toDate()
    }));

    // Prepare data for Flowise
    const userData = userDoc.data();
    const flowiseData = {
      userProfile: {
        age: userData.age,
        weight: userData.weight,
        gender: userData.gender,
        trainingExperience: userData.experience
      },
      stepData: {
        dailyCounts: stepCounts,
        weeklyTotal: stepCounts.reduce((sum, day) => sum + day.steps, 0),
        averageDailySteps: Math.round(stepCounts.reduce((sum, day) => sum + day.steps, 0) / stepCounts.length)
      }
    };

    // Call Flowise API
    const flowiseResponse = await axios.post(process.env.FLOWISE_API_URL, flowiseData, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.FLOWISE_API_KEY}`
      }
    });

    // Return the combined data
    res.json({
      userProfile: flowiseData.userProfile,
      stepData: flowiseData.stepData,
      flowiseResponse: flowiseResponse.data
    });

  } catch (error) {
    console.error('Error fetching user data:', error);
    res.status(500).json({ error: 'Failed to fetch user data' });
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
}); 