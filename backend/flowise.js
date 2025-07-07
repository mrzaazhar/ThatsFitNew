const axios = require('axios');
const admin = require('firebase-admin');

// Function to fetch weekly goals from Firebase
async function fetchWeeklyGoals(userId) {
    try {
        console.log('\n=== Fetching Weekly Goals ===');
        console.log('User ID:', userId);

        const goalsDoc = await admin.firestore()
            .collection('users')
            .doc(userId)
            .collection('Weekly_Goals')
            .doc('current_week')
            .get();

        if (!goalsDoc.exists) {
            console.log('No weekly goals found for user');
            return null;
        }

        const goalsData = goalsDoc.data();
        console.log('Weekly Goals Data:', goalsData);
        
        return goalsData;
    } catch (error) {
        console.error('Error fetching weekly goals:', error);
        return null;
    }
}

// Function to get current day's scheduled workout
function getCurrentDayScheduledWorkout(weeklyGoals) {
    if (!weeklyGoals || !weeklyGoals.weeklySchedule) {
        return null;
    }

    const today = new Date();
    const todayKey = `${today.getFullYear()}-${(today.getMonth() + 1).toString().padStart(2, '0')}-${today.getDate().toString().padStart(2, '0')}`;
    
    console.log('Today\'s key:', todayKey);
    console.log('Available schedule keys:', Object.keys(weeklyGoals.weeklySchedule));
    
    const todaySchedule = weeklyGoals.weeklySchedule[todayKey];
    
    if (todaySchedule && todaySchedule.isWorkoutDay && todaySchedule.bodyParts && todaySchedule.bodyParts.length > 0) {
        console.log('Found scheduled workout for today:', todaySchedule);
        return {
            bodyParts: todaySchedule.bodyParts,
            workoutTime: todaySchedule.workoutTime || '09:00'
        };
    }
    
    return null;
}

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

        // Fetch weekly goals to check for scheduled workouts
        const weeklyGoals = await fetchWeeklyGoals(userId);
        const scheduledWorkout = getCurrentDayScheduledWorkout(weeklyGoals);

        // Return all data in a single data object
        const flowiseData = {
            stepCount: latestStepCount,
            trainingExperience: userData.experience || 'Beginner',
            currentDay: userData.currentDay || 'Monday',
            scheduledWorkout: scheduledWorkout
        };

        console.log('\nFinal data being sent to Flowise:', flowiseData);

        // Create the prompt template based on whether user has scheduled workout or not
        let promptTemplate;
        
        if (scheduledWorkout) {
            // User has scheduled workout for today - create specific workout prompt
            promptTemplate = createScheduledWorkoutPrompt(flowiseData, scheduledWorkout);
        } else {
            // No scheduled workout - use default prompt template
            promptTemplate = createDefaultWorkoutPrompt(flowiseData);
        }

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
            title: scheduledWorkout ? 
                `${scheduledWorkout.bodyParts.join(' & ')} Workout Options` :
                `${flowiseData.currentDay}'s Workout Options`,
            subtitle: `For ${flowiseData.trainingExperience} Level`,
            intensity: flowiseData.stepCount < 5000 ? 'High Intensity' : 
                     flowiseData.stepCount > 7000 ? 'Light Intensity' : 'Moderate Intensity',
            stepCount: flowiseData.stepCount,
            restPeriods: flowiseData.trainingExperience === 'Beginner' ? '90-120 seconds' :
                        flowiseData.trainingExperience === 'Intermediate' ? '60-90 seconds' : '30-60 seconds',
            scheduledWorkout: scheduledWorkout ? true : false,
            bodyParts: scheduledWorkout ? scheduledWorkout.bodyParts : null
        };

        // Parse multiple workout options
        const workoutOptions = [];
        
        // Split the text by workout sections
        const workoutSections = workoutText.split(/Workout \d+:/);
        
        // Process each workout section (skip the first empty element)
        for (let i = 1; i < workoutSections.length; i++) {
            const section = workoutSections[i];
            const exercises = [];
            
            // Parse exercises in this workout section
            const exerciseRegex = /\d+\.\s*([^\n]+)\n\s*-([^\n]+)\n\s*-([^\n]+)\n\s*-([^\n]+)/g;
            let match;
            
            while ((match = exerciseRegex.exec(section)) !== null) {
                exercises.push({
                    name: match[1].trim(),
                    details: {
                        setsAndReps: match[2].trim().replace(/^-\s*/, ''),
                        restPeriod: match[3].trim().replace(/^-\s*/, ''),
                        formTips: match[4].trim().replace(/^-\s*/, '')
                    }
                });
            }
            
            if (exercises.length > 0) {
                workoutOptions.push({
                    id: i,
                    name: `Workout ${i}`,
                    exercises: exercises
                });
            }
        }

        // Create the final structured response
        const formattedResponse = {
            summary: workoutSummary,
            workoutOptions: workoutOptions
        };

        return { workoutPlan: formattedResponse };
    } catch (error) {
        console.error('Error fetching latest user data:', error);
        throw error;
    }
}

// Function to create prompt for scheduled workout
function createScheduledWorkoutPrompt(flowiseData, scheduledWorkout) {
    const bodyParts = scheduledWorkout.bodyParts;
    
    return `User Information:
- Step Count = ${flowiseData.stepCount}
- Training Experience = ${flowiseData.trainingExperience}
- Current Day = ${flowiseData.currentDay}
- Scheduled Body Parts = ${bodyParts.join(', ')}

Step Count Guidelines:
- < 5000 steps: High intensity workout (more reps and sets)
- 5000-7000 steps: Moderate intensity workout
- 7000-10000 steps: Light intensity workout (fewer reps and sets)

Rest Period Guidelines Based On Training Experience:
- Beginner: Longer rest periods (90-120 seconds)
- Intermediate: Moderate rest periods (60-90 seconds)
- Expert: Shorter rest periods (30-60 seconds)

List Of Exercises Names Based On Body Part:
1. Chest:
    - Smith Machine Bench Press
    - Bench Press
    - Dumbell bench press
    - Seated Bench Press (Machine)
    - Incline bench press
    - Incline dumbell press
    - Incline Smith Machine Bench Press
    - Pec Fly
    - Dumbell Fly
    - Cable Fly

2. Back:
    - Wide Grip Lat Pull Downs
    - V-Bar Pull Downs
    - Wide Grip Cable Rows
    - V-Bar Cable Rows
    - Lying Rows (Machine)
    - Barbell Rows
    - Dumbell Rows
    - Rope Pull Downs
    - Pull Ups
    - Deadlifts

3. Biceps:
    - Barbell Curls
    - EZ Bar Curls
    - Dumbell Curls
    - Cable Bar Curls
    - Seated Wide Grip Curls 
    - Hammer Curls
    - Preacher Curls
    - Preacher Dumbell Curls
    - Concentration Curls
    - Rope Hammer Curls

4. Triceps:
    - Tricep Push Downs
    - Tricep V-Bar Push Downs
    - Tricep Rope Push Downs
    - Tricep Overhead Extension
    - Tricep Overhead Rope Extension
    - Dumbell Tricep Extensions
    - Dumbell Tricep Single Hand Extensions
    - Barbell Skull Crushers
    - Incline Skull Crushers
    - Tricep Dips

5. Shoulders:
    - Barbell Shoulder Press
    - Dumbell Shoulder Press
    - Barbell Lateral Raises
    - Dumbell Lateral Raises
    - Cable Lateral Raises
    - Barbell Front Raises
    - Dumbell Front Raises
    - Dumbell Reverse Flys
    - Machine Reverse Flys
    - Rope Facepulls

6. Legs:
    - Barbell Squats
    - Smith Machine Squats
    - Hack Squats
    - Dumbell Squats
    - Leg Press (Machine)
    - Leg Extensions (Machine)
    - Leg Hamstring Curls (Machine)
    - Dumbell Romanian Deadlifts
    - Dumbell Lunges
    - Leg Calf Raises (Machine)

IMPORTANT: The user has scheduled a ${bodyParts.join(' & ')} workout for today. Please create THREE different workout options focusing ONLY on the scheduled body parts: ${bodyParts.join(', ')}.

Each workout should include:
1. Exercise name (from the list of exercises names for the scheduled body parts)
2. Sets and reps (adjusted based on step count)
3. Rest periods (adjusted based on experience level)
4. Brief form tips

IMPORTANT GUIDELINES:
- Create exactly 3 workout options (Workout 1, Workout 2, Workout 3)
- Focus ONLY on the scheduled body parts: ${bodyParts.join(', ')}
- For each body part, include 3-4 exercises (minimum 3, maximum 4)
- Randomize the exercises for each workout to provide variety
- Ensure no workout has the exact same combination of exercises
- Use exercises ONLY from the provided list for the scheduled body parts
- Adjust intensity based on step count guidelines
- Adjust rest periods based on training experience

Please format the response exactly as follows:

WORKOUT OPTIONS:

Workout 1:
1. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

2. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

[Continue with 3-4 exercises for each scheduled body part...]

Workout 2:
1. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

2. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

[Continue with 3-4 exercises for each scheduled body part...]

Workout 3:
1. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

2. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

[Continue with 3-4 exercises for each scheduled body part...]

Please ensure each workout option is different and provides variety while maintaining the appropriate intensity and rest periods for the user's fitness level and daily activity.`;
}

// Function to create default workout prompt (original template)
function createDefaultWorkoutPrompt(flowiseData) {
    return `User Information:
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
    - Smith Machine Bench Press
    - Bench Press
    - Dumbell bench press
    - Seated Bench Press (Machine)
    - Incline bench press
    - Incline dumbell press
    - Incline Smith Machine Bench Press
    - Pec Fly
    - Dumbell Fly
    - Cable Fly
    

2. Back:
    - Wide Grip Lat Pull Downs
    - V-Bar Pull Downs
    - Wide Grip Cable Rows
    - V-Bar Cable Rows
    - Lying Rows (Machine)
    - Barbell Rows
    - Dumbell Rows
    - Rope Pull Downs
    - Pull Ups
    - Deadlifts

3. Biceps:
    - Barbell Curls
    - EZ Bar Curls
    - Dumbell Curls
    - Cable Bar Curls
    - Seated Wide Grip Curls 
    - Hammer Curls
    - Preacher Curls
    - Preacher Dumbell Curls
    - Concentration Curls
    - Rope Hammer Curls

4. Triceps:
    - Tricep Push Downs
    - Tricep V-Bar Push Downs
    - Tricep Rope Push Downs
    - Tricep Overhead Extension
    - Tricep Overhead Rope Extension
    - Dumbell Tricep Extensions
    - Dumbell Tricep Single Hand Extensions
    - Barbell Skull Crushers
    - Incline Skull Crushers
    - Tricep Dips

5. Shoulders:
    - Barbell Shoulder Press
    - Dumbell Shoulder Press
    - Barbell Lateral Raises
    - Dumbell Lateral Raises
    - Cable Lateral Raises
    - Barbell Front Raises
    - Dumbell Front Raises
    - Dumbell Reverse Flys
    - Machine Reverse Flys
    - Rope Facepulls
    

6. Legs:
    - Barbell Squats
    - Smith Machine Squats
    - Hack Squats
    - Dumbell Squats
    - Leg Press (Machine)
    - Leg Extensions (Machine)
    - Leg Hamstring Curls (Machine)
    - Dumbell Romanian Deadlifts
    - Dumbell Lunges
    - Leg Calf Raises (Machine)
    
     
Please provide THREE different workout options for the user to choose from. Each workout should include:
1. Exercise name (from the list of exercises names)
2. Sets and reps (adjusted based on step count)
3. Rest periods (adjusted based on experience level)
4. Brief form tips

IMPORTANT GUIDELINES:
- Create exactly 3 workout options (Workout 1, Workout 2, Workout 3)
- For each body part, include 3-4 exercises (minimum 3, maximum 4)
- Randomize the exercises for each workout to provide variety
- Ensure no workout has the exact same combination of exercises
- Use exercises ONLY from the provided list
- Adjust intensity based on step count guidelines
- Adjust rest periods based on training experience

Please format the response exactly as follows:

WORKOUT OPTIONS:

Workout 1:
1. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

2. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

[Continue with 3-4 exercises for each body part...]

Workout 2:
1. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

2. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

[Continue with 3-4 exercises for each body part...]

Workout 3:
1. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

2. [Exercise Name] 
   -[Sets and reps]
   -[Rest periods]
   -[Brief form tips]

[Continue with 3-4 exercises for each body part...]

Please ensure each workout option is different and provides variety while maintaining the appropriate intensity and rest periods for the user's fitness level and daily activity.`;
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
    query,
    fetchWeeklyGoals,
    getCurrentDayScheduledWorkout,
    createScheduledWorkoutPrompt,
    createDefaultWorkoutPrompt
};

