# Hostel Management App - Full State Persistence

Production-ready Flutter app with automatic state persistence and restoration.

## Features
- Auto-save all user data on change
- Restore exact app state on reopen
- Secure storage for sensitive data
- Encrypted local database
- Offline-first architecture

## Setup

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## Architecture

### State Management: Provider
- Simple, official, well-tested
- Perfect for this use-case with clear data flow
- Easy to debug and maintain

### Persistence Strategy
- **Hive**: Fast, type-safe NoSQL database with encryption
- **flutter_secure_storage**: Secure keychain/keystore for tokens
- **Debounced writes**: Avoid excessive disk I/O

### Data Flow
1. User action → Provider updates state
2. Provider triggers debounced save (500ms)
3. Data written to encrypted Hive box
4. On app restart: Splash screen restores state before UI render

## Security
- Hive boxes encrypted with AES-256
- Encryption key stored in secure keychain
- Auth tokens in flutter_secure_storage
- No sensitive data in logs

## Testing
```bash
flutter test
```

## Key Trade-offs
- **Provider over Riverpod**: Simpler, more stable
- **Hive over SQLite**: Faster, easier encryption, no SQL needed
- **Debounced saves**: Balance between data safety and performance
