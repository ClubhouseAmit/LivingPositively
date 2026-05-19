![Build](https://github.com/Tovli/Mazilon/actions/workflows/main.yml/badge.svg)


# Mezilon App Documentation

## Overview
Mezilon is a Flutter-based mobile application designed to provide mental health support and personal planning tools. The app includes features such as a personal plan, positive traits tracker, journal, emergency contacts, and wellness tools.

## Key Components

### Main Structure
- `main.dart`: Entry point of the application, sets up providers and initializes the app.
- `menu.dart`: Implements the main navigation menu and structure of the app.

### User Information and App Data
- `userInformation.dart`: Manages user-specific data and preferences.
- `appInformation.dart`: Handles app-wide information and configurations.

### Core Features
1. Personal Plan
   - `schedule2.dart`: Displays the user's personal plan.
   - `myPlan2.dart`: Allows users to view and edit their personal plan details.

2. Positive Traits
   - `positive.dart`: Manages the positive traits feature.
   - `traitListWidget.dart`: Displays a list of positive traits.

3. Journal
   - `journal.dart`: Implements the journaling feature.
   - `thankYou.dart`: Handles the "Thank You" entries in the journal.

4. Emergency Contacts
   - `phone.dart`: Manages emergency contact information.
   - `EmergencyPhones.dart`: Displays emergency phone numbers.

5. Wellness Tools
   - `wellnessTools.dart`: Provides access to wellness resources and videos.
   - `player.dart`: Implements video playback functionality.

### Authentication and User Management
- `login.dart` and `signup.dart`: Handle user authentication.
- `UserSettings.dart`: Allows users to manage their account settings.

### Data Synchronization
- `syncDevicesRealtime.dart`: Manages data synchronization between devices.
- `dataEncryption.dart`: Handles encryption for secure data transfer.

### Utilities and Helpers
- `styles.dart`: Defines common styles used throughout the app.
- `firebase_functions.dart`: Manages interactions with Firebase services.
- `PDF/shareAndDownload.dart`: Handles PDF generation and sharing.

## Key Features
- Personal plan creation and management
- Positive trait tracking
- Journaling with gratitude focus
- Emergency contact management
- Wellness resources and video content
- Data synchronization across devices
- PDF export of personal plan

## Technical Details
- Built with Flutter
- Uses Firebase for backend services and authentication
- Implements state management with Provider
- Utilizes shared preferences for local data storage
- Incorporates various Flutter packages for enhanced functionality

## Setup and Configuration
- Requires Flutter SDK and Dart
- Firebase configuration needed for backend services
- Specific environment setup required for iOS and Android development

This project is tested with BrowserStack

## Acknowledgements
We appreciate [Baz](https://baz.co) for supporting the Living Positively app through their automatic code review system. Their review automation helps keep the project maintainable, reliable, and ready for thoughtful iteration.

This documentation provides an overview of the Mezilon app's structure and key components. For detailed implementation specifics, refer to the individual files and comments within the codebase.
