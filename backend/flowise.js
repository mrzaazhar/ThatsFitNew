const axios = require('axios');
const admin = require('firebase-admin');

// Function to fetch latest user data from Firebase - only called when create workout is clicked
async function fetchLatestUserData(userId) {
    try {
        console.log('\n=== Fetching User Data for Workout Creation ===');
        console.log('User ID:', userId);

        // Get user document
        const userDoc = await admin.firestore()
            .collection('users')
            .doc(userId)
            .get();

        if (!userDoc.exists) {
            throw new Error('User not found');
        }

        const userData = userDoc.data();
        console.log('User Profile Data:', userData);
        
        // Only use dailySteps from user profile, don't check activity collection
        const latestStepCount = userData.dailySteps || 0;
        console.log('Step count from profile (dailySteps):', latestStepCount);

        // Return all data in a single data object
        const flowiseData = {
            age: userData.age,
            weight: userData.weight,
            gender: userData.gender,
            trainingExperience: userData.trainingExperience,
            stepCount: latestStepCount
        };

        console.log('\nFinal data being sent to Flowise:', flowiseData);
        return { flowiseData };
    } catch (error) {
        console.error('Error fetching latest user data:', error);
        throw error;
    }
}

async function query(data) {
    try {
        console.log('\n=== Calling Flowise API ===');
        console.log('Data being sent to Flowise:', data);
        
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
        
        console.log('Flowise API Response Status:', response.status);
        const result = await response.json();
        console.log('Flowise API Response:', result);
        
        if (!response.ok) {
            throw new Error(`Flowise API error: ${response.status} ${result.message || ''}`);
        }
        
        return result;
    } catch (error) {
        console.error('Error calling Flowise API:', error);
        throw error;
    }
}

// Main function to get workout recommendation
async function getWorkoutRecommendation(userId) {
    try {
        console.log('\n=== Starting Workout Recommendation Process ===');
        
        // Get the user data
        const userData = await fetchLatestUserData(userId);
        console.log('User data fetched successfully');
        
        // Send the raw flowiseData to Flowise
        console.log('Preparing to call Flowise with data:', userData.flowiseData);
        const response = await query({
            question: userData.flowiseData
        });
        console.log('Flowise response received:', response);

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

