# Notification Troubleshooting Guide

## Why Your Notifications Aren't Showing Up

Based on your code analysis, here are the most common reasons why notifications might not appear and how to fix them:

## 🔧 **IMMEDIATE FIXES**

### 1. **Missing Android Permissions** ✅ FIXED
**Problem**: Your AndroidManifest.xml was missing crucial notification permissions.

**Solution**: I've added the missing permissions:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.VIBRATE" />
```

**Action**: Rebuild your app after this change.

### 2. **Android 13+ Notification Permission**
**Problem**: Android 13+ requires explicit permission for notifications.

**Solution**: 
1. Go to **Settings > Apps > Your App Name**
2. Tap **Permissions**
3. Enable **Notifications**

### 3. **Exact Alarm Permission (Android 12+)**
**Problem**: Android 12+ requires special permission for exact alarms.

**Solution**:
1. Go to **Settings > Apps > Special app access > Alarms & reminders**
2. Find your app and enable it
3. Or go to **Settings > Apps > Your App Name > Permissions > Alarms & reminders**

## 🧪 **TESTING STEPS**

### Step 1: Use the Debug Tool
1. Open your app
2. Go to **Weekly Goals** page
3. Scroll to the bottom to the **Debug Notifications** section
4. Tap **"Debug All"** button
5. Check the debug information in the popup

### Step 2: Test Immediate Notification
1. In the debug section, tap **"Test Notification"**
2. You should see a notification appear immediately
3. If it doesn't appear, check the debug info for errors

### Step 3: Check Pending Notifications
1. Tap **"Check Pending"** to see scheduled notifications
2. This will show you if notifications are being scheduled correctly

## 📱 **DEVICE-SPECIFIC CHECKS**

### Android Device Settings
1. **Do Not Disturb Mode**: Make sure it's off
2. **Battery Optimization**: Disable for your app
   - Settings > Apps > Your App > Battery > Unrestricted
3. **App Notifications**: 
   - Settings > Apps > Your App > Notifications > Allow
4. **Notification Channels**: 
   - Settings > Apps > Your App > Notifications > Workout Reminders > Allow

### Samsung Devices (Common Issues)
1. **Samsung Battery Optimization**:
   - Settings > Device care > Battery > App power management
   - Find your app and set to "Unmonitored apps"
2. **Samsung Do Not Disturb**:
   - Settings > Notifications > Do not disturb > Turn off
3. **Samsung Game Mode**:
   - Settings > Advanced features > Game mode > Turn off for your app

## 🔍 **DEBUGGING COMMON ISSUES**

### Issue 1: "Exact alarms not permitted"
**Symptoms**: Notifications are delayed or don't appear at exact times
**Solution**: Enable exact alarm permission (see Android 12+ section above)

### Issue 2: "Notification permissions not granted"
**Symptoms**: No notifications at all
**Solution**: Grant notification permissions in device settings

### Issue 3: "Scheduled notifications not appearing"
**Symptoms**: Immediate notifications work but scheduled ones don't
**Possible Causes**:
1. Device restart cleared scheduled notifications
2. Battery optimization killed the app
3. Exact alarm permission not granted

### Issue 4: "Notifications appear but are delayed"
**Symptoms**: Notifications show up but not at the exact time
**Solution**: 
1. Enable exact alarm permission
2. Disable battery optimization for your app
3. Check if device is in power saving mode

## 🛠️ **DEVELOPER DEBUGGING**

### Check Console Logs
Look for these messages in your debug console:
- ✅ "Notification service initialized successfully"
- ✅ "Scheduled notification: [title] at [time]"
- ❌ "Error scheduling notification: [error]"
- ❌ "Exact alarms not permitted"

### Test Commands
Add these to your debug section for testing:

```dart
// Test immediate notification
await NotificationService.showNotification(
  id: 9999,
  title: 'Test',
  body: 'This is a test',
);

// Check permissions
final hasPermission = await NotificationService.requestPermissions();
print('Permissions granted: $hasPermission');

// Check exact alarm permission
final hasExactPermission = await NotificationService.checkExactAlarmPermission();
print('Exact alarms permitted: $hasExactPermission');
```

## 📋 **CHECKLIST**

Before reporting an issue, verify:

- [ ] App has notification permissions
- [ ] Exact alarm permission is granted (Android 12+)
- [ ] Battery optimization is disabled for the app
- [ ] Do Not Disturb is off
- [ ] Debug tool shows "success" for both immediate and scheduled tests
- [ ] Console logs show successful scheduling
- [ ] Device is not in power saving mode

## 🚨 **EMERGENCY FIXES**

If nothing else works:

1. **Clear App Data**: Settings > Apps > Your App > Storage > Clear Data
2. **Reinstall App**: Uninstall and reinstall the app
3. **Check Device Compatibility**: Ensure Android 6.0+ (API 23+)
4. **Test on Different Device**: Try on another Android device

## 📞 **GETTING HELP**

If you're still having issues:

1. Run the **"Debug All"** tool
2. Take a screenshot of the debug information
3. Check your device's Android version
4. Note any error messages in the console
5. Try the test notifications in the debug section

The debug tool will help identify exactly what's preventing your notifications from working! 