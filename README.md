# whatsappmsgpilot

A new Flutter project.

## Getting Started

# WhatsApp Message Pilot

A Flutter app that allows you to schedule WhatsApp messages to be sent automatically at specific times.

## Features

### ✅ Core Features Implemented
- 📱 **Schedule Messages**: Create scheduled WhatsApp messages with contact selection and date/time picker
- 👥 **Contact Integration**: Select contacts from your phone's contact list or enter phone numbers manually
- 📅 **Smart Scheduling**: Choose any future date and time for message delivery
- 📋 **Message Management**: View, edit, and delete scheduled messages
- 🔄 **Status Tracking**: Monitor message status (pending, sent, failed, cancelled)
- ⚙️ **Settings**: Configure auto-send options and accessibility permissions
- 📁 **Local Storage**: Messages stored securely in app's private storage as JSON

### 🔧 Technical Implementation
- **Flutter Frontend**: Modern, Material 3 UI with WhatsApp-green theming
- **WorkManager Background**: Reliable background task scheduling even when app is closed
- **Accessibility Service**: Android accessibility service for automatic message sending
- **Contact Permissions**: Seamless contact access with permission handling
- **JSON Storage**: Lightweight, secure local storage without external database dependencies

## Installation & Setup

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Android device or emulator (API level 21+)

### Building the App
```bash
# Clone the repository
git clone <repository-url>
cd WhatsappMsgPilot

# Get dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Or run directly on device
flutter run
```

### Required Permissions
The app requires the following permissions:
- **Contacts**: To select contacts for messaging
- **Notifications**: To notify when messages are sent
- **Accessibility Service**: To automatically click send in WhatsApp

## How It Works

### 1. Message Scheduling Flow
```
User creates schedule → Stored in JSON → WorkManager schedules task → 
At scheduled time → Launches WhatsApp → Accessibility Service clicks send
```

### 2. Data Storage
Messages are stored in `<app_private_directory>/schedules.json`:
```json
[
  {
    "id": "uuid-string",
    "phone": "+911234567890",
    "contactName": "John Doe",
    "message": "Happy Birthday!",
    "scheduled_time": 1723180200000,
    "status": "pending",
    "work_id": "workmanager-task-id"
  }
]
```

### 3. Background Processing
- **WorkManager**: Handles reliable background task execution
- **Native Worker**: Kotlin worker that launches WhatsApp with pre-filled message
- **Accessibility Service**: Automatically clicks the send button in WhatsApp

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── scheduled_message.dart         # Data model for scheduled messages
├── services/
│   ├── storage_service.dart           # JSON file storage operations
│   ├── scheduling_service.dart        # WorkManager integration
│   └── contact_service.dart           # Contact access and management
├── screens/
│   ├── home_screen.dart              # Main screen with message list
│   ├── add_edit_schedule_screen.dart  # Create/edit scheduled messages
│   └── settings_screen.dart          # App settings and permissions
└── widgets/
    └── contact_picker_dialog.dart     # Contact selection dialog

android/app/src/main/kotlin/com/example/whatsappmsgpilot/
├── MainActivity.kt                    # Main Android activity
├── WhatsAppMessageWorker.kt          # Background worker for message sending
└── WhatsAppAccessibilityService.kt   # Accessibility service for auto-clicking
```

## Key Features Explained

### Contact Selection
- Integrates with device contacts using `flutter_contacts`
- Allows manual phone number entry
- Automatic phone number formatting and validation
- Search functionality for easy contact finding

### Reliable Scheduling
- Uses WorkManager for guaranteed task execution
- Survives app closures and device reboots
- Handles time zone changes and date/time updates
- Constraints ensure optimal task execution

### Accessibility Integration
- Android accessibility service monitors WhatsApp
- Automatically detects when WhatsApp opens with a message
- Safely clicks the send button without user interaction
- Configurable auto-send toggle in settings

### Modern UI/UX
- Material 3 design with WhatsApp branding
- Intuitive message management with swipe actions
- Real-time status updates and progress indicators
- Responsive design with proper error handling

## Important Notes

### ⚠️ Disclaimers
- **Personal Use Only**: This app is designed for personal use and should not be used for spam or commercial messaging
- **WhatsApp ToS**: Ensure compliance with WhatsApp's Terms of Service
- **Accessibility Permission**: Users must manually enable the accessibility service in Android settings
- **WhatsApp Dependency**: Requires WhatsApp to be installed on the device

### 🔒 Privacy & Security
- All data stored locally on device
- No external servers or data transmission
- Contacts accessed only with explicit user permission
- Messages stored in app's private sandbox

### 🐛 Known Limitations
- Requires manual accessibility service setup
- WhatsApp UI changes may affect auto-sending
- Limited to text messages only
- Android-only implementation (iOS requires different approach)

## Future Enhancements

Potential improvements for future versions:
- [ ] iOS support using iOS shortcuts
- [ ] Rich media message support (images, documents)
- [ ] Recurring message scheduling
- [ ] Message templates and quick actions
- [ ] Group message scheduling
- [ ] Statistics and delivery reports
- [ ] Export/import scheduled messages
- [ ] Dark mode theme

## Contributing

This is a personal project, but suggestions and improvements are welcome. Please ensure any contributions maintain the focus on personal use and privacy.

## License

This project is for personal use only. Please respect WhatsApp's Terms of Service and local regulations regarding automated messaging.
