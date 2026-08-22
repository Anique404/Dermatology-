import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

// ============================================
// AUTHENTICATION SERVICE
// ============================================
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register new user
  Future<bool> register(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user to Firestore
      await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'email': email,
            'password': password,
            'displayName': '',
            'createdAt': DateTime.now(),
            'isAdmin': false,
          });

      return true;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getErrorMessage(e.code),
      );
    }
  }

  // Login user
  Future<User?> login(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user != null) {
        await ensureUserDocument(user, password: password);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> ensureUserDocument(User user, {String? password}) async {
    try {
      final ref = _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(user.uid);
      final existing = await ref.get();
      final alreadyAdmin = existing.data()?['isAdmin'] == true;
      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'isAdmin': alreadyAdmin || AdminCredentials.isAdminEmail(user.email),
      };
      if (password != null && password.isNotEmpty) {
        data['password'] = password;
      }
      if (!existing.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      await ref.set(data, SetOptions(merge: true));
    } catch (e) {
      print('❌ Failed to save user document: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin(String uid) async {
    final current = _auth.currentUser;
    if (AdminCredentials.isAdminEmail(current?.email)) {
      return true;
    }
    try {
      final doc = await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(uid)
          .get();
      final data = doc.data();
      if (data?['isAdmin'] == true) return true;
      if (AdminCredentials.isAdminEmail(data?['email']?.toString())) {
        return true;
      }
      return false;
    } catch (e) {
      return AdminCredentials.isAdminEmail(current?.email);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getErrorMessage(e.code),
      );
    }
  }

  // Get error message
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'An error occurred';
    }
  }
}
