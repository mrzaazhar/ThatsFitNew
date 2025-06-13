const axios = require('axios');
const admin = require('firebase-admin');

// Function to fetch latest user data from Firebase
async function fetchLatestUserData(userId) {
    try {
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(userId)
            .get();

        if (!userDoc.exists) {
            throw new Error('User not found');
        }

        const userData = userDoc.data();
        
        // Get the latest step count from user's activity data
        const activitySnapshot = await admin.firestore()
            .collection('users')
            .doc(userId)
            .collection('activity')
            .orderBy('timestamp', 'desc')
            .limit(1)
            .get();

        let latestStepCount = userData.stepCount || 0;
        if (!activitySnapshot.empty) {
            const latestActivity = activitySnapshot.docs[0].data();
            latestStepCount = latestActivity.stepCount || latestStepCount;
        }

        // Return all data in a single data object
        return {
            flowiseData: {
                age: userData.age,
                weight: userData.weight,
                gender: userData.gender,
                trainingExperience: userData.trainingExperience,
                stepCount: latestStepCount
            }
        };
    } catch (error) {
        console.error('Error fetching latest user data:', error);
        throw error;
    }
}

async function query(data) {
    const response = await fetch(
        "http://localhost:3000/api/v1/prediction/5bdfeb41-b68c-4eba-b643-52ffd8900b3a",
        {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(data)
        }
    );
    const result = await response.json();
    return result;
}

// Main function to get workout recommendation
async function getWorkoutRecommendation(userId) {
    try {
        // Get the user data
        const userData = await fetchLatestUserData(userId);
        
        // Send the raw flowiseData to Flowise
        const response = await query({
            question: userData.flowiseData
        });

        return {
            message: 'Workout recommendation generated successfully',
            workoutPlan: response,
            userData: userData.flowiseData
        };
    } catch (error) {
        console.error('Error getting workout recommendation:', error);
        throw error;
    }
}

module.exports = {
    getWorkoutRecommendation,
    fetchLatestUserData,
    query
};

