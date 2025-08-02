# Exercise Video Integration Guide

This guide explains how to integrate exercise-specific tutorial videos into your workout app.

## Overview

The workout system now supports exercise-specific video tutorials. Each exercise can have its own video ID that links to a YouTube tutorial video.

## How It Works

### 1. Video ID Structure

You can provide video IDs in two ways:

**Option 1: In the exercise details**
```dart
{
  'name': 'Barbell Squats',
  'details': {
    'setsAndReps': '3 sets x 8-12 reps',
    'restPeriod': '2-3 minutes',
    'formTips': 'Keep chest up, knees in line with toes',
    'videoId': 'aclHkVaku9U' // Specific video ID
  }
}
```

**Option 2: At the root level**
```dart
{
  'name': 'Barbell Squats',
  'videoId': 'aclHkVaku9U', // Video ID at root level
  'details': {
    'setsAndReps': '3 sets x 8-12 reps',
    'restPeriod': '2-3 minutes',
    'formTips': 'Keep chest up, knees in line with toes'
  }
}
```

### 2. Video ID Priority

The system checks for video IDs in this order:
1. `exercise['videoId']` (root level)
2. `exercise['details']['videoId']` (in details)
3. Falls back to `YouTubeService.getVideoId(exerciseName)` (predefined mapping)

### 3. Predefined Video Mappings

The `YouTubeService` class contains predefined mappings for common exercises:

```dart
static final Map<String, String> _exerciseVideos = {
  'Barbell Squats': 'aclHkVaku9U',
  'Push-ups': 'IODxDxX7oi4',
  'Deadlift': '1XEDaV7ZZqs',
  'Bench Press': 'rT7DgCr-3pg',
  // ... more exercises
};
```

## Features

### 1. Video Thumbnails
- Each exercise card shows a video thumbnail (if video ID is available)
- Thumbnails are loaded from YouTube's thumbnail API
- Fallback to lower quality if high quality fails
- Play button overlay for better UX

### 2. Video Player
- Tap the video button or thumbnail to open the video player
- Videos open in the `WorkoutVideoPlayer` widget
- Option to watch on YouTube directly

### 3. Responsive Design
- Thumbnails adapt to screen size
- Video buttons are styled consistently
- Works on mobile, tablet, and desktop

## How to Add New Exercise Videos

### 1. Find YouTube Video ID
1. Go to the YouTube video you want to use
2. Copy the video ID from the URL: `https://www.youtube.com/watch?v=VIDEO_ID_HERE`
3. The video ID is the part after `v=`

### 2. Add to YouTubeService
```dart
// In lib/services/youtube_service.dart
static final Map<String, String> _exerciseVideos = {
  // ... existing mappings
  'Your Exercise Name': 'YOUR_VIDEO_ID_HERE',
};
```

### 3. Use in Exercise Data
```dart
// When creating exercise data
Map<String, dynamic> exercise = {
  'name': 'Your Exercise Name',
  'videoId': 'YOUR_VIDEO_ID_HERE', // Will use your specific video
  'details': {
    'setsAndReps': '3 sets x 10 reps',
    'restPeriod': '2 minutes',
    'formTips': 'Your form tips here'
  }
};
```

## Example Usage

### Creating Exercises with Videos
```dart
// Use the helper method
Map<String, dynamic> exercise = _createExerciseWithVideo(
  name: 'Barbell Squats',
  setsAndReps: '3 sets x 8-12 reps',
  restPeriod: '2-3 minutes',
  formTips: 'Keep chest up, knees in line with toes',
  videoId: 'aclHkVaku9U', // Specific video ID
);
```

### Example Exercise List
```dart
List<Map<String, dynamic>> exercises = [
  {
    'name': 'Barbell Squats',
    'videoId': 'aclHkVaku9U',
    'details': {
      'setsAndReps': '3 sets x 8-12 reps',
      'restPeriod': '2-3 minutes',
      'formTips': 'Keep chest up, knees in line with toes'
    }
  },
  {
    'name': 'Push-ups',
    // No videoId - will use default from YouTubeService
    'details': {
      'setsAndReps': '3 sets x 10-15 reps',
      'restPeriod': '1-2 minutes',
      'formTips': 'Maintain straight body line'
    }
  }
];
```

## Video Quality and Performance

### Thumbnail Loading
- High quality thumbnails: `https://img.youtube.com/vi/VIDEO_ID/maxresdefault.jpg`
- Fallback to medium quality: `https://img.youtube.com/vi/VIDEO_ID/hqdefault.jpg`
- Error handling shows a placeholder icon

### Video Player
- Videos open in the app's video player
- Option to watch on YouTube for better quality
- Handles video loading errors gracefully

## Best Practices

1. **Use Specific Video IDs**: Always provide specific video IDs for exercises when possible
2. **Quality Videos**: Choose high-quality tutorial videos with good form demonstrations
3. **Consistent Naming**: Use consistent exercise names that match your predefined mappings
4. **Error Handling**: The system handles missing videos gracefully
5. **User Experience**: Videos should be short, focused tutorials (2-5 minutes ideal)

## Troubleshooting

### Video Not Showing
- Check if the video ID is correct
- Verify the video is public on YouTube
- Check console logs for error messages

### Thumbnail Not Loading
- The system automatically falls back to lower quality thumbnails
- If still not working, check the video ID format

### Video Player Issues
- Ensure the `url_launcher` package is properly configured
- Check internet connectivity
- Verify YouTube app is installed (for mobile)

## API Keys

The YouTube service uses a Google API key for additional features:
- Video details fetching
- Video search functionality
- Channel video listing

Make sure to configure your API key in `lib/services/youtube_service.dart`:
```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
``` 