# Health Connect Permission Troubleshooting Guide

## Common Issues and Solutions

### 1. **"Permission not granted" Error**

**Problem**: Your app says permission is not granted even though you've granted it in Health Connect.

**Solutions**:

#### A. Check Health Connect App Settings
1. Open **Health Connect** app
2. Go to **Apps and devices**
3. Find your app name (`flutter_application_1`)
4. Make sure **Steps** is enabled (toggle should be ON)
5. If not enabled, tap on it and grant permission

#### B. Check Android System Permissions
1. Go to **Settings** → **Apps** → **Health Connect**
2. Tap **Permissions**
3. Make sure **Physical activity** and **Health data** are allowed
4. If not, enable them

#### C. Check Your App Permissions
1. Go to **Settings** → **Apps** → **Your App Name**
2. Tap **Permissions**
3. Make sure **Physical activity** is allowed
4. If not, enable it

### 2. **Health Connect Not Available**

**Problem**: App says "Health Connect not available"

**Solutions**:
1. **Check Android Version**: Health Connect requires Android 12 (API 31) or higher
2. **Install Health Connect**: Download from Google Play Store
3. **Enable Health Connect**: Go to Settings → Apps → Health Connect → Enable

### 3. **No Step Data**

**Problem**: Permissions granted but no step data appears

**Solutions**:
1. **Check Samsung Health Connection**:
   - Open Samsung Health
   - Go to Settings → Connected services
   - Make sure Health Connect is connected
   - Enable step data sharing

2. **Check Galaxy Fit 3 Sync**:
   - Ensure your Galaxy Fit 3 is connected to Samsung Health
   - Check if step data is syncing properly
   - Try syncing manually in Samsung Health

3. **Check Health Connect Data Sources**:
   - Open Health Connect app
   - Go to Data sources
   - Make sure Samsung Health is listed and enabled for Steps

### 4. **App Crashes or Errors**

**Problem**: App crashes when trying to access Health Connect

**Solutions**:
1. **Clear App Data**: Go to Settings → Apps → Your App → Storage → Clear Data
2. **Restart Device**: Sometimes a simple restart helps
3. **Reinstall App**: Uninstall and reinstall your app
4. **Check Logs**: Look at the console output for specific error messages

## Step-by-Step Verification Process

### Step 1: Verify Health Connect Installation
```bash
# Check if Health Connect is installed
adb shell pm list packages | grep healthdata
```

### Step 2: Check Permissions in Code
Add this debug code to your app:

```dart
// Add this to your step_count.dart initState
Future<void> _debugPermissions() async {
  try {
    final hasPerms = await _healthConnectService.hasPermissions();
    print('Has permissions: $hasPerms');
    
    final isAvail = await _healthConnectService.isAvailable();
    print('Health Connect available: $isAvail');
    
    if (hasPerms) {
      final steps = await _healthConnectService.getTodayStepCount();
      print('Today steps: $steps');
    }
  } catch (e) {
    print('Debug error: $e');
  }
}
```

### Step 3: Manual Health Connect Setup
1. **Open Health Connect app**
2. **Go to "Apps and devices"**
3. **Find your app** (should be listed as `flutter_application_1`)
4. **Enable Steps permission**
5. **Go to "Data sources"**
6. **Make sure Samsung Health is connected and enabled for Steps**

### Step 4: Test with Samsung Health
1. **Open Samsung Health**
2. **Check if step data is being recorded**
3. **Go to Settings → Connected services**
4. **Verify Health Connect connection**
5. **Enable step data sharing**

## Debug Information

### Check Your Current Setup
Run this in your app to get debug information:

```dart
void _printDebugInfo() async {
  print('=== Health Connect Debug Info ===');
  print('Android version: ${Platform.operatingSystemVersion}');
  
  final available = await _healthConnectService.isAvailable();
  print('Health Connect available: $available');
  
  final hasPerms = await _healthConnectService.hasPermissions();
  print('Has permissions: $hasPerms');
  
  if (hasPerms) {
    try {
      final steps = await _healthConnectService.getTodayStepCount();
      print('Today steps: $steps');
    } catch (e) {
      print('Error getting steps: $e');
    }
  }
}
```

### Common Error Messages and Solutions

| Error Message | Solution |
|---------------|----------|
| "Health Connect not available" | Install Health Connect from Play Store |
| "Permission denied" | Grant permissions in Health Connect app |
| "No data available" | Check Samsung Health connection and sync |
| "Activity recognition permission denied" | Grant physical activity permission in Android settings |
| "Health Connect not installed" | Install Health Connect app |

## Testing Checklist

- [ ] Health Connect app is installed
- [ ] Health Connect app is enabled
- [ ] Your app has physical activity permission
- [ ] Your app is listed in Health Connect "Apps and devices"
- [ ] Steps permission is enabled for your app in Health Connect
- [ ] Samsung Health is connected to Health Connect
- [ ] Step data sharing is enabled in Samsung Health
- [ ] Galaxy Fit 3 is connected to Samsung Health
- [ ] Step data is syncing in Samsung Health

## Still Having Issues?

If you're still experiencing problems after following this guide:

1. **Check the console logs** for specific error messages
2. **Try on a different device** to isolate the issue
3. **Test with a simple step counter app** to verify Health Connect works
4. **Contact support** with the specific error messages and device information

## Additional Resources

- [Health Connect Developer Documentation](https://developer.android.com/health-connect)
- [Health Connect User Guide](https://support.google.com/healthconnect)
- [Samsung Health Integration Guide](https://developer.samsung.com/health/android/) 