# Seed admin (one-time)

1. Enable **Email/Password** in Firebase Console → Authentication.
2. Create a user OR let the seed create one.
3. Deploy rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
4. Temporarily call from a debug button / Dart DevTools, or from login after first run:

```dart
await seedAdminAndBranch(
  email: 'admin@center.com',
  password: 'Admin123!',
  displayName: 'المدير العام',
);
```

Or manually in Firestore create `users/{uid}` with:

```json
{
  "email": "admin@center.com",
  "displayName": "المدير العام",
  "role": "admin",
  "branchId": "default_branch"
}
```

Then run:

```bash
flutter run -d chrome
```
