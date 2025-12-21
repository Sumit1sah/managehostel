# Hostel Management System - Project Description

## Overview
A comprehensive Flutter mobile application designed for hostel management with features for washing machine queue management, room cleaning tracking, and student services. The app implements production-grade state persistence with encrypted local storage.

## Key Features

### 1. Washing Machine Queue System
- **Real-time Queue Management**: Students can join queues for available washing machines
- **Live Tracking**: Track your position in queue with estimated wait time (45 min per cycle)
- **Multiple Machines**: Support for multiple washing machines across different floors
- **Auto-progression**: Queue automatically advances when washing cycle completes

### 2. Room Cleaning Management
- **Floor-wise Organization**: Manage rooms organized by floors (Ground, First, Second, Third, etc.)
- **Dynamic Floor Addition**: Add unlimited custom floors as needed
- **Cleaning Checklist**: Three-point verification system:
  - Bathroom Clean ✓
  - Room Clean ✓
  - Toilet Clean ✓
- **Submit for Clearance**: Submit only when all items are checked
- **Status Tracking**: Track cleaning status (Pending → In Progress → Completed → Verified)

### 3. User Authentication
- **Secure Login**: Credentials stored in device keychain/keystore
- **Auto-login**: Persistent session across app restarts
- **Logout**: Clear all secure data on logout

### 4. Settings & Profile
- **Account Management**: Profile, notifications, password change
- **Hostel Services**: Room details, fee payment, payment history
- **Additional Services**: Mess menu, complaints, medical assistance
- **Help & Support**: About, help documentation

## Technical Architecture

### State Management
- **Provider Pattern**: Simple, official Flutter state management
- **Reactive Updates**: UI automatically updates on data changes
- **Debounced Saves**: 500ms delay to optimize disk writes

### Data Persistence
- **Hive Database**: Fast, encrypted NoSQL database
  - AES-256 encryption for all sensitive data
  - Encryption key stored in secure keychain
  - Type-safe data storage
- **Secure Storage**: flutter_secure_storage for auth tokens
- **Auto-save**: All changes saved automatically
- **State Restoration**: App restores exact state on reopen

### Security Features
- Encrypted local database (Hive with AES-256)
- Secure keychain storage for credentials
- No sensitive data in logs
- Platform-level encryption (Keychain on iOS, EncryptedSharedPreferences on Android)

### Offline-First Architecture
- All features work without internet
- Data stored locally on device
- No network dependency for core features
- Ready for cloud sync integration

## Data Models

### RoomCleaning
- Room number, floor, student ID
- Cleaning status and timestamps
- Three-point checklist (bathroom, room, toilet)
- Verification details

### WashingMachine
- Machine ID, location, status
- Current user and cycle timing
- Queue management

### QueueEntry
- Student details, position in queue
- Timestamp and estimated wait time
- Machine assignment

### Student
- User ID, name, room number
- Hostel block assignment

## User Flow

### First Time User
1. Open app → Login screen
2. Enter credentials → Stored securely
3. Navigate to home → See all features

### Washing Machine Queue
1. View available machines
2. Join queue for selected machine
3. Track position in real-time
4. Get notified when turn arrives

### Room Cleaning
1. Select floor from dropdown
2. Add rooms to floor
3. Expand room card
4. Check off cleaning items
5. Submit for clearance when complete

### App Restart
1. App opens → Splash screen
2. Restore all data from encrypted storage
3. Navigate to last screen
4. Continue exactly where left off

## Technology Stack

- **Framework**: Flutter 3.0+
- **Language**: Dart
- **State Management**: Provider 6.1+
- **Database**: Hive 2.2+ with encryption
- **Secure Storage**: flutter_secure_storage 9.0+
- **Platform**: Android & iOS

## Performance Optimizations

- Debounced writes (500ms) to reduce I/O
- Lazy loading for large lists
- Efficient JSON serialization
- Background async operations
- Memory-efficient data structures

## Future Enhancements

### Planned Features
- Push notifications for queue updates
- QR code room scanning
- Complaint management system
- Mess menu with ratings
- Fee payment integration
- Visitor management
- Attendance tracking

### Cloud Integration (Optional)
- Firebase Firestore for real-time sync
- Cloud backup and restore
- Multi-device synchronization
- Admin dashboard

## Use Cases

### For Students
- Book washing machines without physical queue
- Track room cleaning requirements
- View hostel services and information
- Manage complaints and requests

### For Hostel Staff
- Monitor room cleaning status
- Verify completed cleanings
- Track machine usage
- Manage student requests

### For Administrators
- View analytics and reports
- Manage hostel resources
- Track maintenance schedules
- Generate usage statistics

## Installation & Setup

### Prerequisites
- Flutter SDK 3.0 or higher
- Android Studio / Xcode
- Physical device or emulator

### Steps
```bash
# Clone repository
git clone <repo-url>

# Install dependencies
flutter pub get

# Run app
flutter run
```

## Project Structure
```
lib/
├── core/
│   ├── storage/
│   │   ├── hive_storage.dart      # Encrypted database
│   │   └── secure_storage.dart    # Keychain wrapper
│   ├── providers/
│   │   └── app_state_provider.dart # Global state
│   └── app_lifecycle_observer.dart # Save on pause
├── models/
│   ├── room_cleaning.dart
│   ├── washing_machine.dart
│   ├── queue_entry.dart
│   └── student.dart
├── services/
│   ├── auth_service.dart
│   ├── cleaning_service.dart
│   ├── washing_service.dart
│   └── storage_service.dart
├── controllers/
│   ├── cleaning_controller.dart
│   └── washing_controller.dart
├── views/
│   ├── splash_view.dart
│   ├── login_view.dart
│   ├── washing_queue_view.dart
│   ├── queue_tracking_view.dart
│   ├── room_cleaning_view.dart
│   └── settings_view.dart
└── main.dart
```

## Key Differentiators

1. **Full State Persistence**: Unlike typical apps, this maintains complete state across restarts
2. **Encrypted Storage**: All data encrypted at rest with AES-256
3. **Offline-First**: Works completely without internet
4. **Production-Ready**: Proper error handling, testing, and documentation
5. **Scalable Architecture**: Easy to add new features and services

## License
MIT License

## Support
For issues and feature requests, contact hostel management team.
