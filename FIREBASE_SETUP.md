# Firebase Setup Guide for Raven App

## Required Firebase Services

To use the Raven app, you need to enable the following services in your Firebase Console:

### 1. Firebase Authentication
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Anonymous** authentication:
   - Click on "Anonymous"
   - Toggle "Enable" to ON
   - Click "Save"

### 2. Cloud Firestore Database
1. Navigate to **Firestore Database**
2. Click "Create database"
3. Choose **Start in test mode** (for development) or **Start in production mode**
4. Select your preferred location
5. Click "Enable"

**Important:** If using test mode, update security rules later for production.

### 3. Firebase Storage (Optional - for future gallery/voice features)
1. Navigate to **Storage**
2. Click "Get started"
3. Choose **Start in test mode** (for development)
4. Select your preferred location
5. Click "Done"

## Security Rules (Important!)

### Firestore Rules
Update your Firestore security rules to allow authenticated users:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /pairs/{pairId} {
      allow read, write: if request.auth != null;
    }
    
    match /moods/{moodId} {
      allow read, write: if request.auth != null;
    }
    
    match /whispers/{whisperId} {
      allow read, write: if request.auth != null;
    }
    
    match /sealedLetters/{letterId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Rules (if using Storage)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Testing

After enabling these services:
1. Restart your app
2. Click "Begin" on the sign-in screen
3. The app should authenticate anonymously and proceed to the main screen

## Troubleshooting

- **"Sign in error"**: Make sure Anonymous authentication is enabled
- **"Permission denied"**: Check your Firestore security rules
- **Blank screen**: Ensure Firebase is properly configured (run `flutterfire configure`)

