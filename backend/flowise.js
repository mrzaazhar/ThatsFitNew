const axios = require('axios');
const admin = require('firebase-admin');

// Function to fetch latest user data from Firebase - only called when create workout is clicked
async function fetchLatestUserData(userId) {
    try {
        console.log('\n=== Fetching User Data for Workout Creation ===');
        console.log('User ID:', userId);

        // Get profile document from the profile subcollection
        const profileSnapshot = await admin.firestore()
            .collection('users')
            .doc(userId)
            .collection('profile')
            .limit(1)
            .get();

        console.log('Profile snapshot size:', profileSnapshot.size);
        console.log('Profile snapshot empty:', profileSnapshot.empty);

        if (profileSnapshot.empty) {
            throw new Error(`User profile not found for userId: ${userId}`);
        }

        // Get the first (and should be only) profile document
        const profileDoc = profileSnapshot.docs[0];
        const userData = profileDoc.data();
        console.log('User Profile Data:', userData);
        
        // Only use dailySteps from user profile, don't check activity collection
        const latestStepCount = userData.dailySteps || 0;
        console.log('Step count from profile (dailySteps):', latestStepCount);

        // Return all data in a single data object
        const flowiseData = {
            stepCount: latestStepCount,
            trainingExperience: userData.experience || 'Beginner',
            currentDay: userData.currentDay || 'Monday'
        };

        console.log('\nFinal data being sent to Flowise:', flowiseData);

        // Create the prompt template with actual user data
        const promptTemplate = `User Information:
- Step Count = ${flowiseData.stepCount}
- Training Experience = ${flowiseData.trainingExperience}
- Current Day = ${flowiseData.currentDay}

Step Count Guidelines:
- < 5000 steps: High intensity workout (more reps and sets)
- 5000-7000 steps: Moderate intensity workout
- 7000-10000 steps: Light intensity workout (fewer reps and sets)

Rest Period Guidelines Based On Training Experience:
- Beginner: Longer rest periods (90-120 seconds)
- Intermediate: Moderate rest periods (60-90 seconds)
- Expert: Shorter rest periods (30-60 seconds)

Workout Schedule Based On Current Day:
- Monday: Back and Biceps
- Tuesday: Chest and Triceps
- Wednesday: Legs
- Thursday: Shoulders, Triceps, and Biceps
- Friday: Chest and Back
- Saturday: Legs
- Sunday: Shoulders

List Of Exercises Names Based On Body Part:
1. Chest:
    - Bench Press
    - Dumbell bench press
    - Incline bench press
    - Incline dumbell press
    - Pec Fly
    - Dumbell Fly
    - Cable Fly
    - Dips

2. Back:
    - Lat Pull Downs
    - Cable Rows
    - Barbell Rows
    - Dumbell Rows
    - Rope Pull Downs
    - Pull Ups
    - Deadlifts

3. Biceps:
    - Barbell Curls
    - Dumbell Curls
    - Wide Grip Curls 
    - Hammer Curls
    - Preacher Curls
    - Concentration Curls
    - Rope Hammer Curls

4. Triceps:
    - Tricep Rope Extensions
    - Tricep Cable Push Downs
    - Tricep Close Grip Cable Push Downs
    - Dumbell Tricep Extensions
    - Barbell Skull Crushers

5. Shoulders:
    - Barbell Shoulder Press
    - Dumbell Shoulder Press
    - Barbell Lateral Raises
    - Dumbell Lateral Raises
    - Barbell Front Raises
    - Dumbell Front Raises
    - Dumbell Reverse Flys
    - Machine Reverse Flys

6. Legs:
    - Barbell Squats
    - Hack Squats
    - Leg Press (Machine)
    - Leg Extensions (Machine)
    - Leg Hamstring Curls (Machine)
    - Leg Calf Raises (Machine)
     
Please provide a detailed workout plan that includes:
1. Exercise name (adjusted based on the list of exercises names)
2. Sets and reps (adjusted based on step count)
3. Rest periods (adjusted based on experience level)
4. Brief form tips

Format the response in a clear, structured way that's easy to read. 
Please ensure that the exercise name is in the list of exercises names.
For each body part's exercise, please provide 3-4 exercises.
Please randomize the exercises for each body part when a new workout is created.
Please format the response as:

Workout Plan:
1. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

2. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]
...`;

        // Send the prompt template to Flowise
        console.log('Preparing to call Flowise with prompt template');
        const response = await query({
            question: promptTemplate
        });
        console.log('Flowise response received:', response);

        // Parse the workout plan text
        const workoutText = response.text;
        
        // Extract workout summary
        const workoutSummary = {
            title: `${flowiseData.currentDay}'s Workout Plan`,
            subtitle: `For ${flowiseData.trainingExperience} Level`,
            intensity: flowiseData.stepCount < 5000 ? 'High Intensity' : 
                     flowiseData.stepCount > 7000 ? 'Light Intensity' : 'Moderate Intensity',
            stepCount: flowiseData.stepCount,
            restPeriods: flowiseData.trainingExperience === 'Beginner' ? '90-120 seconds' :
                        flowiseData.trainingExperience === 'Intermediate' ? '60-90 seconds' : '30-60 seconds'
        };

        // Parse exercises into a clean format
        const exercises = [];
        const exerciseRegex = /\d+\.\s*([^\n]+)\n\s*-([^\n]+)\n\s*-([^\n]+)\n\s*-([^\n]+)/g;
        let match;
        
        while ((match = exerciseRegex.exec(workoutText)) !== null) {
            exercises.push({
                name: match[1].trim(),
                details: {
                    setsAndReps: match[2].trim().replace(/^-\s*/, ''),
                    restPeriod: match[3].trim().replace(/^-\s*/, ''),
                    formTips: match[4].trim().replace(/^-\s*/, '')
                }
            });
        }

        // Create the final structured response
        const formattedResponse = {
            summary: workoutSummary,
            exercises: exercises
        };

        return { workoutPlan: formattedResponse };
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
        
        // Get the user data and workout plan
        const { workoutPlan } = await fetchLatestUserData(userId);
        console.log('Workout plan fetched successfully');
        
        return {
            message: 'Workout recommendation generated successfully',
            workoutPlan: workoutPlan
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

