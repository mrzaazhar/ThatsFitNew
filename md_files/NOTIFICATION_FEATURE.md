# Workout Notification Feature

## Overview

This feature provides intelligent push notifications for scheduled workouts, helping users stay on track with their fitness goals. When users set their weekly workout schedule, the system automatically schedules notifications to remind them about their workouts.

## How It Works

### 1. Notification Scheduling
When a user saves their weekly goals in the Weekly Goals page, the system automatically schedules notifications for all scheduled workouts:

- **1 hour before workout**: Early preparation reminder
- **30 minutes before workout**: Get ready reminder  
- **At workout time**: Start your workout now!

### 2. Notification Content
Each notification includes:
- **Title**: Clear indication of timing (e.g., "Workout Reminder - 1 Hour")
- **Body**: Specific body parts and motivational message
- **Example**: "Your Chest & Tricep workout starts in 1 hour! Time to prepare."

### 3. Smart Scheduling
- Notifications are only scheduled for future workout times
- If a workout time has already passed, no notifications are scheduled
- Each workout day gets 3 unique notification IDs to avoid conflicts

## Technical Implementation

### Notification Service (`lib/services/notification_service.dart`)

#### New Methods Added:

1. **`scheduleWorkoutNotifications()`**
   - Schedules 3 notifications for a specific workout day
   - Handles time parsing and validation
   - Creates appropriate notification messages

2. **`scheduleWeeklyWorkoutNotifications()`**
   - Processes the entire weekly schedule
   - Schedules notifications for all workout days
   - Cancels existing notifications before scheduling new ones

3. **`cancelWorkoutNotificationsForDay()`**
   - Cancels notifications for a specific day
   - Uses hash-based ID calculation for consistency

### Integration with Weekly Goals (`lib/weekly_goals.dart`)

#### Changes Made:

1. **Import Added**: `import 'services/notification_service.dart';`

2. **Permission Request**: Added `_requestNotificationPermissions()` method
   - Called in `initState()` to request permissions when page loads
   - Handles both Android and iOS permission requests

3. **Notification Scheduling**: Modified `_saveGoals()` method
   - Calls `NotificationService.scheduleWeeklyWorkoutNotifications()` after saving goals
   - Includes error handling to prevent notification failures from affecting goal saving

4. **UI Enhancement**: Added notification settings section
   - Shows users what notifications they'll receive
   - Explains the notification timing
   - Provides visual feedback about the feature

## Notification Details

### Timing
- **1 hour before**: "Your [Body Parts] workout starts in 1 hour! Time to prepare."
- **30 minutes before**: "Your [Body Parts] workout starts in 30 minutes! Get ready to crush it!"
- **At workout time**: "Your [Body Parts] workout is starting now! Let's get moving! 💪"

### Channel Configuration
- **Channel ID**: `workout_reminder`
- **Channel Name**: `Workout Reminders`
- **Importance**: High
- **Priority**: High
- **Schedule Mode**: `exactAllowWhileIdle` (Android)

### Notification IDs
- **Range**: 1000-9999 (reserved for workout notifications)
- **Per Workout**: 3 IDs (base, base+1, base+2)
- **Spacing**: 10 IDs between workouts to avoid conflicts

## User Experience

### Setting Up Notifications
1. User goes to Weekly Goals page
2. Sets workout schedule with specific times and body parts
3. Clicks "Save Weekly Goals"
4. System automatically requests notification permissions
5. Notifications are scheduled for all workout days

### Receiving Notifications
1. **1 hour before**: User gets early reminder to prepare
2. **30 minutes before**: User gets ready reminder
3. **At workout time**: User gets start notification

### Example Scenario
- User schedules Monday 5:00 PM Chest & Tricep workout
- System schedules notifications for:
  - Monday 4:00 PM: "Your Chest & Tricep workout starts in 1 hour! Time to prepare."
  - Monday 4:30 PM: "Your Chest & Tricep workout starts in 30 minutes! Get ready to crush it!"
  - Monday 5:00 PM: "Your Chest & Tricep workout is starting now! Let's get moving! 💪"

## Error Handling

### Permission Denied
- System logs the denial but doesn't show error to user
- Notifications won't be scheduled but goals still save successfully

### Invalid Times
- System validates workout times before scheduling
- Invalid times are logged but don't prevent goal saving

### Past Times
- Notifications for past times are automatically skipped
- System logs skipped notifications for debugging

## Testing

### Manual Testing Steps:
1. Set up a weekly schedule with workout times
2. Save the goals
3. Check notification permissions are granted
4. Wait for scheduled notification times
5. Verify notifications appear with correct content

### Debug Information:
- All notification scheduling is logged to console
- Check logs for "Scheduled X-hour reminder" messages
- Verify notification IDs are unique and properly spaced

## Future Enhancements

### Potential Improvements:
1. **Customizable Timing**: Allow users to choose notification intervals
2. **Notification Preferences**: Let users enable/disable specific notification types
3. **Smart Reminders**: Adjust notification timing based on user behavior
4. **Workout Completion**: Send notifications when workouts are completed
5. **Goal Achievement**: Notify when weekly goals are met

### Advanced Features:
1. **Location-based**: Remind when user is near a gym
2. **Weather-aware**: Adjust notifications based on weather conditions
3. **Social**: Share workout achievements with friends
4. **Integration**: Connect with calendar apps for better scheduling

## Troubleshooting

### Common Issues:

1. **Notifications not appearing**
   - Check notification permissions are granted
   - Verify device is not in Do Not Disturb mode
   - Check app notification settings in device settings

2. **Wrong notification times**
   - Verify timezone settings
   - Check device clock accuracy
   - Review scheduled notification logs

3. **Duplicate notifications**
   - Clear all notifications and reschedule
   - Check for multiple app instances
   - Verify notification ID spacing

### Debug Commands:
```dart
// Check scheduled notifications
await NotificationService.cancelAllNotifications();

// Request permissions again
await NotificationService.requestPermissions();

// Test immediate notification
await NotificationService.showNotification(
  id: 9999,
  title: 'Test Notification',
  body: 'This is a test notification',
);
``` 