# Firebase Admin SDK Setup Guide

This guide explains how to set up Firebase Admin SDK using Cloud Functions for secure server-side operations.

## 🚀 Why Cloud Functions?

Firebase Admin SDK cannot run in Flutter apps because it requires server-side privileges. Cloud Functions provide a secure, scalable way to use Admin SDK features.

## 📋 Prerequisites

1. **Firebase CLI**: Install Firebase CLI globally
   ```bash
   npm install -g firebase-tools
   ```

2. **Node.js**: Version 18 or higher
3. **Firebase Project**: Already set up with Authentication and Firestore

## 🔧 Setup Steps

### Step 1: Initialize Firebase Functions

1. **Navigate to your project root**:
   ```bash
   cd your-flutter-project
   ```

2. **Initialize Firebase Functions**:
   ```bash
   firebase init functions
   ```
   
   - Select your Firebase project
   - Choose JavaScript
   - Install dependencies with npm
   - Use ESLint (recommended)

### Step 2: Deploy Cloud Functions

1. **Navigate to functions directory**:
   ```bash
   cd backend/functions
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Deploy functions**:
   ```bash
   firebase deploy --only functions
   ```

### Step 3: Update Flutter App

1. **Add cloud_functions dependency** (already done):
   ```yaml
   dependencies:
     cloud_functions: ^4.6.0
   ```

2. **Run flutter pub get**:
   ```bash
   flutter pub get
   ```

## 🔐 Security Features

### Admin Authentication
- Only users with email `thatsfitAdmin@gmail.com` can call admin functions
- Functions verify admin status before executing
- Secure token-based authentication

### Available Functions

1. **getTotalUserCount**: Gets accurate user count from Firebase Auth
2. **getUserAnalytics**: Provides comprehensive user analytics
3. **deleteUser**: Securely deletes users with Admin SDK
4. **incrementUserCount**: Auto-increments when new users register

## 📊 How It Works

### User Registration Flow
1. User registers in Flutter app
2. Firebase Auth creates user account
3. Cloud Function `incrementUserCount` triggers automatically
4. Admin document updates with new count
5. Admin dashboard shows updated count

### Admin Dashboard Flow
1. Admin logs in with admin credentials
2. Flutter app calls Cloud Functions
3. Functions use Admin SDK to get accurate data
4. Results returned to Flutter app
5. Dashboard displays real-time analytics

## 🧪 Testing

### Test Cloud Functions Locally
```bash
cd backend/functions
npm run serve
```

### Test Admin Dashboard
1. Login as admin: `thatsfitAdmin@gmail.com` / `thatsfitAdmin`
2. Check Total Users card
3. Use debug buttons for testing

## 🔍 Debugging

### Check Function Logs
```bash
firebase functions:log
```

### Test Individual Functions
```bash
firebase functions:shell
```

### Monitor Real-time
```bash
firebase functions:log --only getTotalUserCount
```

## 🚨 Important Notes

1. **Cost**: Cloud Functions have usage costs after free tier
2. **Cold Starts**: First function call may be slower
3. **Permissions**: Ensure proper Firestore security rules
4. **Region**: Functions deploy to us-central1 by default

## 📈 Benefits

✅ **Accurate User Count**: Uses Admin SDK for precise counting
✅ **Secure**: Server-side execution prevents client-side manipulation
✅ **Scalable**: Handles large user bases efficiently
✅ **Real-time**: Automatic updates when users register
✅ **Admin Features**: Full user management capabilities

## 🔧 Troubleshooting

### Common Issues

1. **Function not found**: Ensure functions are deployed
2. **Permission denied**: Check admin email authentication
3. **Cold start delays**: Normal for first function calls
4. **Network errors**: Check internet connectivity

### Debug Commands

```bash
# Check function status
firebase functions:list

# View function details
firebase functions:describe getTotalUserCount

# Test function locally
firebase emulators:start --only functions
```

## 📞 Support

If you encounter issues:
1. Check Firebase Console for function logs
2. Verify admin authentication
3. Ensure proper Firebase project configuration
4. Test with Firebase emulators first

---

**Next Steps**: Deploy the functions and test the admin dashboard! 