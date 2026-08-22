# DermaAI - Skin Care Assistant 🏥

A complete Flutter application for skin disease diagnosis using AI with Firebase backend.

## Features

✅ **User Authentication**

- Email/Password registration and login
- Firebase Authentication integration
- Secure user data storage in Firestore

✅ **Chat Interface (DeepSeek Style)**

- Dark theme with teal/blue accents
- Real-time chat history
- Side drawer with chat navigation
- Typing indicators

✅ **AI Model Integration**

- TFLite model for skin disease prediction
- Image preprocessing (224x224 resize & normalization)
- Confidence scores and recommendations
- Support for 15 common skin diseases

✅ **Image Processing**

- Gallery image picker
- Camera capture
- Image preview in chat
- Multiple image analysis

✅ **Disease List**

- Modal dialog showing all 15 diseases
- Quick reference for users
- Professional UI design

✅ **Admin Panel**

- Admin login (admin@dermai.com / Admin@123)
- View total registered users
- List all users with details
- Access user chat history
- Admin-only statistics

✅ **Firestore Backend**

- Chat history storage per user
- Message persistence
- Prediction records
- User management

## Project Structure

```
lib/
├── main.dart                      # App entry point & Firebase init
├── firebase_options.dart          # Firebase configuration (placeholder)
├── screens/
│   ├── login_screen.dart         # User login
│   ├── register_screen.dart       # User registration
│   ├── chat_screen.dart          # Main chat interface
│   └── admin_screen.dart         # Admin dashboard
├── widgets/
│   ├── chat_bubble.dart          # Chat message bubbles
│   ├── side_menu.dart            # Navigation drawer
│   └── disease_list.dart         # Disease modal dialog
├── services/
│   ├── auth_service.dart         # Firebase Auth logic
│   ├── firestore_service.dart    # Firestore operations
│   └── model_service.dart        # TFLite model inference
├── models/
│   └── chat_model.dart           # Data models (User, Chat, Message)
└── utils/
    └── constants.dart            # Colors, styles, constants
```

## Installation & Setup

### 1. **Prerequisites**

- Flutter SDK 3.11.0 or higher
- Firebase project created
- Android/iOS development environment

### 2. **Clone & Install**

```bash
cd c:\Users\Anique\OneDrive\Desktop\skin_care_app
flutter pub get
```

### 3. **Firebase Configuration** ⚠️ IMPORTANT

#### Step A: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Add Android & iOS apps

#### Step B: Update firebase_options.dart

Open `lib/firebase_options.dart` and replace:

```dart
// Replace these with your Firebase credentials
apiKey: 'YOUR_ANDROID_API_KEY',
appId: 'YOUR_ANDROID_APP_ID',
messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
projectId: 'YOUR_PROJECT_ID',
storageBucket: 'YOUR_STORAGE_BUCKET',
```

**Get these from:**

- Android: `android/app/google-services.json` → Firebase Console
- iOS: `ios/Runner/GoogleService-Info.plist` from Firebase Console

#### Step C: Enable Firebase Services

In Firebase Console:

1. **Authentication** → Enable Email/Password
2. **Firestore Database** → Create in test mode (or production)
   - Set rules to allow authenticated users
3. **Storage** (optional) → Enable for future image storage

#### Step D: Set Up Firestore Security Rules

Replace default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
      match /chats/{document=**} {
        allow read, write: if request.auth.uid == uid;
      }
    }
  }
}
```

### 4. **Create Admin User**

1. Register with `admin@dermai.com` / `Admin@123`
2. In Firestore, update user document:
   ```
   users → [uid] → isAdmin: true
   ```

### 5. **Run the App**

```bash
flutter run
```

## Usage

### User Flow

1. **Launch App**
   - Shows Login/Register if not authenticated
   - Redirects to Chat Screen if user is logged in
   - Redirects to Admin Panel if admin is logged in

2. **Register New Account**
   - Email & password validation
   - Saves to Firebase Auth & Firestore
   - Auto-login after registration

3. **Chat Interface**
   - Send text messages
   - Upload images from gallery
   - Capture images with camera
   - View disease list
   - See AI predictions

4. **AI Prediction**
   - User uploads/captures skin image
   - Image processed to 224×224
   - Model runs inference
   - Returns disease name & confidence
   - Displays recommendation from JSON

5. **History & Sidebar**
   - All chats saved to Firestore
   - View past conversations
   - Create new chats
   - Logout

6. **Admin Panel** (Login: admin@dermai.com)
   - View total users
   - List all registered users
   - Access user details
   - See user chat history

## Admin Credentials

```
Email: admin@dermai.com
Password: Admin@123
```

⚠️ **SECURITY NOTE**: Update credentials in `lib/utils/constants.dart` before deployment!

## Available Diseases

1. Acne
2. Contact Dermatitis
3. Eczema
4. Fungal Infection
5. Herpes
6. Insect Bite Dermatitis
7. Lichen Planus
8. Miliaria
9. Palmoplantar Keratoderma
10. Papular Urticaria
11. Psoriasis
12. Purpura
13. Rosacea
14. Seborrheic Dermatitis
15. Urticaria

## Model Information

- **Model**: DenseNet121 (TFLite)
- **Input Size**: 224×224 pixels
- **Output**: Probabilities for 15 disease classes
- **Normalization**: -1 to 1 (ImageNet style)

## Technology Stack

| Feature           | Library         |
| ----------------- | --------------- |
| Flutter Framework | flutter         |
| Authentication    | firebase_auth   |
| Database          | cloud_firestore |
| AI Model          | tflite_flutter  |
| Image Picker      | image_picker    |
| Camera            | camera          |
| UI Fonts          | google_fonts    |
| State Management  | Provider        |
| Localization      | intl            |

## Dependencies

See `pubspec.yaml` for complete list:

- firebase_core ^2.24.2
- firebase_auth ^4.16.0
- cloud_firestore ^4.14.0
- tflite_flutter ^0.11.0
- image_picker ^0.8.8
- camera ^0.10.5
- google_fonts ^6.1.0
- provider ^6.0.0

## Firebase Firestore Structure

```
firestore/
├── users/
│   ├── {uid}/
│   │   ├── email: string
│   │   ├── displayName: string
│   │   ├── createdAt: timestamp
│   │   ├── isAdmin: boolean
│   │   └── chats/
│   │       ├── {chatId}/
│   │       │   ├── title: string
│   │       │   ├── createdAt: timestamp
│   │       │   ├── updatedAt: timestamp
│   │       │   └── messages: array
│   │       │       └── {message}/
│   │       │           ├── id: string
│   │       │           ├── content: string
│   │       │           ├── sender: string (user/ai)
│   │       │           ├── timestamp: timestamp
│   │       │           ├── imagePath: string (optional)
│   │       │           └── prediction: object (optional)
```

## Error Handling

- ✅ Firebase connection errors
- ✅ Model loading errors
- ✅ Image processing errors
- ✅ Invalid image format errors
- ✅ Authentication errors
- ✅ Firestore operations errors

All errors show user-friendly SnackBar messages.

## Future Enhancements

- [ ] Profile editing
- [ ] Multiple language support
- [ ] Cloud storage for images
- [ ] Email notifications
- [ ] Advanced statistics
- [ ] Dark/Light theme toggle
- [ ] Push notifications
- [ ] Backup & restore chats

## Troubleshooting

### Firebase not connecting?

- Verify firebase_options.dart has correct credentials
- Check Firebase Console project settings
- Ensure authentication is enabled

### TFLite model not loading?

- Check assets exist in `assets/` folder
- Verify file paths in constants.dart
- Ensure `pubspec.yaml` has asset references

### Image picker not working?

- Check app permissions (Camera, Gallery)
- Test on actual device (not emulator recommended)
- Verify image_picker plugin properly initialized

### Firestore errors?

- Check security rules allow authenticated access
- Verify user is properly authenticated
- Check Firestore quota limits

## Performance Tips

- Images are resized to 224×224 for faster processing
- Chat history loads incrementally
- Firestore uses indexes for faster queries
- Model inference runs on device (no network call)

## Security Considerations

⚠️ **Before Production:**

1. Update admin credentials in constants.dart
2. Add environment variables for Firebase keys
3. Implement proper Firestore security rules
4. Enable API key restrictions in Firebase Console
5. Use Firebase Analytics for monitoring
6. Implement rate limiting
7. Add user data encryption

## License

This project is for educational purposes. Modify and use as needed.

## Support

For issues or questions:

1. Check troubleshooting section
2. Review Firebase documentation
3. Check Flutter/Dart documentation
4. Review TFLite Flutter documentation

---

**Built with ❤️ using Flutter & Firebase**

Happy coding! 🚀
