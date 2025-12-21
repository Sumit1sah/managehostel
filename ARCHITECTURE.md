# Architecture & Design Decisions

## State Management: Provider

**Why Provider?**
- Official Flutter recommendation
- Simple, predictable data flow
- Excellent for this use-case (single-user, offline-first)
- Easy testing and debugging
- Mature ecosystem

**Alternatives considered:**
- Riverpod: More complex, overkill for this app
- BLoC: Too verbose for simple CRUD operations
- GetX: Less type-safe, magic behavior

## Persistence Strategy

### Hive (Primary Database)
**Why Hive?**
- Fast: Pure Dart, no native bridge
- Type-safe with code generation
- Built-in AES-256 encryption
- No SQL needed for simple data
- Excellent for offline-first apps

**Storage:**
- Cleanings, queue, machines, floors
- App state (navigation, scroll, drafts)

### flutter_secure_storage (Sensitive Data)
**Why?**
- Uses platform keychain/keystore
- Encrypted at OS level
- Perfect for tokens, passwords
- Survives app uninstall (optional)

**Storage:**
- Auth tokens
- User credentials
- Hive encryption key

## Data Flow

### Save Flow
1. User action (e.g., check bathroom clean)
2. Provider updates in-memory state
3. Provider triggers debounced save (500ms)
4. Data serialized to JSON
5. Written to encrypted Hive box
6. On app pause: Force immediate save

### Restore Flow
1. App starts → Splash screen
2. Initialize Hive with encryption key from keychain
3. Run migrations if needed
4. Load all data into providers
5. Restore navigation stack
6. Show UI with restored state

## Security

### Encryption
- Hive boxes: AES-256 cipher
- Encryption key: 256-bit, stored in secure keychain
- Secure storage: Platform keychain (iOS) / EncryptedSharedPreferences (Android)

### Best Practices
- No sensitive data in logs
- Exclude from device backups (configure in AndroidManifest/Info.plist)
- Clear data on logout
- Validate all inputs

## Performance

### Optimizations
- Debounced writes (500ms) to reduce disk I/O
- Lazy loading of large lists
- Background writes (Hive is async)
- Efficient JSON serialization

### Memory Management
- Hive keeps data in memory (fast reads)
- Boxes closed on app terminate
- Clear unused data periodically

## Migration Strategy

### Version Management
```dart
// Current version stored in Hive
final currentVersion = HiveStorage.load('db_version');

// Migration logic
if (currentVersion < 2) {
  // Add new fields, transform data
  await migrateV1toV2();
  await HiveStorage.save('db_version', 2);
}
```

### Breaking Changes
1. Increment version number
2. Write migration function
3. Test with old data
4. Deploy with fallback

## Testing Strategy

### Unit Tests
- Storage save/load operations
- Provider state changes
- Serialization/deserialization

### Integration Tests
- Full restore flow
- Navigation persistence
- Form draft recovery

### Widget Tests
- UI with restored state
- Scroll position restoration

## Trade-offs

| Decision | Pro | Con |
|----------|-----|-----|
| Provider | Simple, stable | Less features than Riverpod |
| Hive | Fast, encrypted | NoSQL (no complex queries) |
| Debounced saves | Better performance | Potential data loss on crash |
| Encrypted storage | Secure | Slight performance overhead |
| Offline-first | Works without network | Sync complexity |

## Future Enhancements

### Cloud Sync (Optional)
- Firebase Firestore for real-time sync
- Conflict resolution: Last-write-wins or CRDT
- Offline queue for pending writes

### Advanced Features
- Incremental backups
- Data compression
- Multi-user support
- End-to-end encryption
