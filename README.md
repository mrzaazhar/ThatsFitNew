# ThatsFit - Fitness Tracking Application

A comprehensive Flutter-based fitness application that helps users track their workouts, monitor daily steps, set weekly goals, and maintain their fitness journey with intelligent notifications and health data integration.

## 🏃‍♂️ Features

### Core Functionality
- **User Authentication**: Secure login/signup with Firebase Authentication
- **Profile Management**: Complete user profile setup and editing
- **Workout Tracking**: Create, save, and track custom workouts
- **Step Counting**: Daily step tracking with Health Connect integration
- **Weekly Goals**: Set and manage weekly fitness goals
- **Progress Monitoring**: Track fitness progress over time

### Advanced Features
- **Health Connect Integration**: Sync with Samsung Health and Galaxy Fit 3
- **Smart Notifications**: Intelligent workout reminders and scheduling
- **Admin Dashboard**: Comprehensive admin system for user management
- **Firebase Backend**: Real-time data synchronization
- **Cross-Platform**: Support for Android, iOS, Web, Windows, macOS, and Linux

### Admin System
- **User Management**: Add, edit, delete, and view user accounts
- **Analytics Dashboard**: Real-time user statistics and activity monitoring
- **System Monitoring**: Track user engagement and fitness metrics

## 📱 Screenshots

*[login.jpg]*
*[image.png]*
*[image.png]*
*[image.png]*
*[image.png]*

## 🛠️ Technology Stack

- **Frontend**: Flutter 3.2.3+
- **Backend**: Firebase (Authentication, Firestore, Functions)
- **Health Integration**: Health Connect API
- **Notifications**: Flutter Local Notifications
- **State Management**: Flutter StatefulWidget
- **UI Components**: Material Design with Google Nav Bar

## 📋 Prerequisites

- Flutter SDK 3.2.3 or higher
- Dart SDK
- Android Studio / VS Code
- Firebase project setup
- Android device with Health Connect (for step tracking)

## 🚀 Installation

### 1. Clone the Repository
```bash
git clone <repository-url>
cd flutter_application_1
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your Firebase project
3. Download and place the configuration files:
   - `google-services.json` in `android/app/`
   - `GoogleService-Info.plist` in `ios/Runner/`
4. Enable Authentication and Firestore in Firebase Console

### 4. Health Connect Setup (Android)
1. Install Health Connect from Google Play Store
2. Connect Samsung Health with your Galaxy Fit 3
3. Enable step data sharing in Health Connect

### 5. Run the Application
```bash
flutter run
```

## 🔧 Configuration

### Firebase Configuration
The app uses Firebase for:
- User authentication
- Data storage (Firestore)
- Cloud functions
- Real-time updates

### Health Connect Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.WRITE_STEPS"/>
```

### Notification Permissions
The app requests notification permissions for:
- Workout reminders
- Daily step goals
- Weekly progress updates

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point and login
├── homepage.dart             # Main navigation and dashboard
├── profile_page.dart         # User profile management
├── workout.dart              # Workout creation and tracking
├── step_count.dart           # Step counting and health data
├── weekly_goals.dart         # Weekly goal setting
├── saved_workout.dart        # Saved workouts management
├── signup_page.dart          # User registration
├── setup_profile.dart        # Initial profile setup
├── edit_profile1.dart        # Profile editing
├── delete_profile.dart       # Account deletion
├── Admin/                    # Admin system files
│   ├── admin_auth.dart
│   ├── admin_dashboard.dart
│   └── admin_user_management.dart
├── services/                 # Service layer
│   ├── notification_service.dart
│   ├── health_connect_service.dart
│   └── workout_service.dart
└── widgets/                  # Reusable UI components
    └── create_workout_button.dart
```

## 🔐 Admin Access

### Admin Credentials
- **Email**: `thatsfitAdmin@gmail.com`
- **Password**: `thatsfitAdmin`
- **Admin ID**: `71N1ZTeAUol0zHf2ZCiI`

### Admin Features
- User management (add, edit, delete users)
- Analytics dashboard
- System monitoring
- User activity tracking

## 📊 Key Features Explained

### Health Connect Integration
- Syncs with Samsung Health and Galaxy Fit 3
- Real-time step count tracking
- Automatic daily step goal monitoring
- Health data visualization

### Smart Notifications
- Workout reminders (1 hour, 30 minutes, and at workout time)
- Daily step goal notifications
- Weekly progress updates
- Customizable notification settings

### Workout Management
- Create custom workouts with specific exercises
- Save and categorize workouts
- Track workout completion
- Progress monitoring

### Weekly Goals
- Set weekly fitness targets
- Schedule workout times
- Track goal completion
- Progress visualization

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📦 Dependencies

### Core Dependencies
- `flutter`: ^3.2.3
- `firebase_core`: ^2.25.4
- `firebase_auth`: ^4.17.4
- `cloud_firestore`: ^4.15.5
- `cloud_functions`: ^4.6.0

### UI Dependencies
- `google_nav_bar`: ^5.0.7
- `carousel_slider`: ^5.0.0
- `cupertino_icons`: ^1.0.2

### Health & Notifications
- `health`: ^13.1.0
- `flutter_local_notifications`: ^19.3.0
- `timezone`: ^0.10.1
- `flutter_timezone`: ^4.1.1

### Utilities
- `http`: ^1.1.0
- `url_launcher`: ^6.2.4
- `webview_flutter`: ^4.7.0
- `image_picker`: ^1.1.2
- `permission_handler`: ^11.3.0

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 📚 Documentation

Additional documentation files:
- `ADMIN_SYSTEM_GUIDE.md` - Complete admin system documentation
- `HEALTH_CONNECT_INTEGRATION.md` - Health Connect setup guide
- `NOTIFICATION_FEATURE.md` - Notification system documentation
- `VIDEO_INTEGRATION_GUIDE.md` - Video feature documentation
- `WEEKLY_SCHEDULE_INTEGRATION.md` - Weekly scheduling guide

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Check the documentation files in the project
- Review Firebase setup guides
- Ensure Health Connect is properly configured
- Verify notification permissions are granted

## 🔄 Version History

- **v1.0.0**: Initial release with core fitness tracking features
- Health Connect integration
- Admin dashboard
- Smart notifications
- Cross-platform support

---

**ThatsFit** - Your personal fitness companion! 💪
