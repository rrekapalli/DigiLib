# Digital Library App

A cross-platform Flutter application for managing and reading digital documents (PDF, EPUB, DOCX) with cloud synchronization and offline capabilities.

## Features

- **Multi-platform support**: Windows, macOS, Linux, Android, iOS
- **Document management**: Browse, organize, and read PDF, EPUB, and DOCX files
- **Cloud integration**: Sync with Google Drive, OneDrive, and local storage
- **Offline reading**: Cache documents for offline access
- **Annotations**: Bookmarks, comments, and highlights
- **Search**: Full-text search across document collections
- **Secure authentication**: OAuth2 integration with secure token storage

## Architecture

The app follows a layered architecture with:

- **Presentation Layer**: Flutter widgets and screens
- **Business Logic Layer**: Services and state management (Riverpod)
- **Data Layer**: Repository pattern with SQLite and API integration
- **Native Integration**: FFI bindings for document rendering

## Project Structure

```
lib/
├── main.dart                 # App entry point
└── src/
    ├── screens/             # UI screens
    ├── widgets/             # Reusable UI components
    ├── services/            # Business logic services
    ├── models/              # Data models
    ├── database/            # Local database and repositories
    ├── providers/           # Riverpod state management
    └── utils/               # Utilities and constants
```

## Dependencies

### Core Dependencies
- `flutter_riverpod` - State management
- `sqflite` - Local database
- `flutter_secure_storage` - Secure token storage
- `dio` - HTTP client
- `ffi` - Native integration

### Development Dependencies
- `build_runner` - Code generation
- `json_serializable` - JSON serialization
- `riverpod_generator` - Provider code generation
- `mockito` - Testing

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Platform-specific development tools:
  - **Android**: Android Studio, Android SDK
  - **iOS**: Xcode (macOS only)
  - **Desktop**: Platform-specific build tools

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run code generation:
   ```bash
   flutter packages pub run build_runner build
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Minimum SDK: 21
- Target SDK: Latest
- Permissions: Internet, Storage, Biometric

#### iOS
- Minimum iOS: 12.0
- Permissions: Documents, Face ID, Background refresh

#### Desktop
- Windows: Windows 10+
- macOS: macOS 10.14+
- Linux: Ubuntu 18.04+ or equivalent

## Development

### Code Generation
Run code generation for models and providers:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Testing
Run all tests:
```bash
flutter test
```

### Analysis
Check code quality:
```bash
flutter analyze
```

## Configuration

The app uses several configuration files:
- `pubspec.yaml` - Dependencies and app metadata
- `build.yaml` - Code generation configuration
- Platform-specific configuration files in respective directories

## Contributing

1. Follow the established project structure
2. Use Riverpod for state management
3. Implement proper error handling
4. Write tests for new features
5. Follow Flutter and Dart style guidelines

## License

This project is licensed under the MIT License - see the LICENSE file for details.