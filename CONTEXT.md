# Mezilon App Context

## Overview
Mezilon is a Flutter-based mobile application designed to provide mental health support and personal planning tools.

## Tech Stack
- **Framework**: Flutter
- **Backend/Auth**: Firebase (Authentication, Database, etc.)
- **State Management**: Provider
- **Local Storage**: SharedPreferences

## Core Features & File Structure
1. **Personal Plan** (`schedule2.dart`, `myPlan2.dart`): Displays and manages the user's personal plan.
2. **Positive Traits** (`positive.dart`, `traitListWidget.dart`): Tracker for positive traits.
3. **Gratitude Journal** (`journal.dart`, `thankYou.dart`): Implements journaling with a focus on gratitude.
4. **Emergency Contacts** (`phone.dart`, `EmergencyPhones.dart`): Manages emergency/SOS phone numbers.
5. **Wellness Tools** (`wellnessTools.dart`, `player.dart`): Provides access to wellness resources and videos.
6. **Authentication** (`login.dart`, `signup.dart`, `UserSettings.dart`): User authentication and settings.
7. **Data Sync & Security** (`syncDevicesRealtime.dart`, `dataEncryption.dart`): Cross-device synchronization and data encryption.

## Rules for AI Agents
- Always adhere to the established architecture using Provider for state management.
- Preserve the existing UI styling (purple color schemes, glassmorphism, responsive layouts).
- When modifying features, always ensure they are appropriately synced if they relate to user data.
