# Weekly Schedule Integration

## Overview

This feature allows users to set their weekly workout schedule in the Weekly Goals page, and when they create a workout on a scheduled day, the system will automatically generate workouts based on their preferences instead of using the default day-based workout schedule.

## How It Works

### 1. Setting Weekly Schedule
- Users can set their weekly workout schedule in the Weekly Goals page (`lib/weekly_goals.dart`)
- They can select specific body parts for each day of the week
- The schedule is saved to Firebase under `users/{userId}/Weekly_Goals/current_week`

### 2. Workout Generation Logic
When a user clicks "Create Workout", the system:

1. **Fetches User Data**: Gets the user's profile information (step count, experience level, etc.)
2. **Checks Weekly Schedule**: Looks for any scheduled workouts for today
3. **Generates Appropriate Workout**:
   - **If scheduled workout exists**: Creates a workout focused on the user's selected body parts
   - **If no scheduled workout**: Uses the default day-based workout schedule

### 3. Backend Implementation

#### New Functions Added to `backend/flowise.js`:

- `fetchWeeklyGoals(userId)`: Fetches the user's weekly goals from Firebase
- `getCurrentDayScheduledWorkout(weeklyGoals)`: Checks if there's a scheduled workout for today
- `createScheduledWorkoutPrompt(flowiseData, scheduledWorkout)`: Creates a prompt for scheduled workouts
- `createDefaultWorkoutPrompt(flowiseData)`: Creates the default prompt (original functionality)

#### Key Changes:

1. **Date Formatting**: Uses `padStart()` instead of `padLeft()` for proper date formatting
2. **Conditional Prompt Generation**: The system now chooses between scheduled and default prompts
3. **Enhanced Response**: The workout summary now includes information about whether it's a scheduled workout

### 4. Response Structure

The response structure remains the same but includes additional information:

```json
{
  "workoutPlan": {
    "summary": {
      "title": "Chest & Tricep Workout Options", // or "Monday's Workout Options"
      "subtitle": "For Beginner Level",
      "intensity": "High Intensity",
      "stepCount": 3000,
      "restPeriods": "90-120 seconds",
      "scheduledWorkout": true, // or false
      "bodyParts": ["Chest", "Tricep"] // or null
    },
    "workoutOptions": [
      {
        "id": 1,
        "name": "Workout 1",
        "exercises": [...]
      }
    ]
  }
}
```

## Example Scenarios

### Scenario 1: User has scheduled Chest & Tricep for Monday
- User sets Monday to focus on Chest and Tricep in Weekly Goals
- On Monday, when they click "Create Workout"
- System generates 3 workout options focused ONLY on Chest and Tricep exercises
- Response title: "Chest & Tricep Workout Options"

### Scenario 2: User has no scheduled workout for Monday
- User hasn't set any specific body parts for Monday
- On Monday, when they click "Create Workout"
- System uses the default day-based schedule (Monday = Back and Biceps)
- Response title: "Monday's Workout Options"

## Technical Details

### Date Format
The system uses the format `YYYY-MM-DD` to match the date keys stored in the weekly schedule.

### Body Part Mapping
The system supports these body parts:
- Chest
- Back
- Bicep
- Tricep
- Shoulder
- Legs

### Exercise Lists
Each body part has a predefined list of exercises that the AI can choose from, ensuring consistency and quality.

## Testing

To test this functionality:

1. Set up a weekly schedule in the Weekly Goals page
2. Schedule specific body parts for today's date
3. Click "Create Workout" on the homepage
4. Verify that the generated workout focuses on your scheduled body parts
5. Try the same on a day without scheduled workouts to see the default behavior

## Error Handling

- If no weekly goals are found, the system falls back to the default workout schedule
- If the date format doesn't match, no scheduled workout is detected
- If the user profile is missing, appropriate error messages are shown

## Future Enhancements

- Add support for multiple workout times per day
- Include rest day scheduling
- Add workout intensity preferences per day
- Support for custom exercise lists per user 