import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  bool get isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth get _auth {
    if (!isFirebaseInitialized) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'no-app',
        message: 'Firebase has not been initialized',
      );
    }
    return FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    if (!isFirebaseInitialized) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'no-app',
        message: 'Firebase has not been initialized',
      );
    }
    return FirebaseFirestore.instance;
  }

  // Get current user
  User? get currentUser => isFirebaseInitialized ? _auth.currentUser : null;

  // Stream of auth state changes
  Stream<User?> get authStateChanges {
    if (!isFirebaseInitialized) {
      return const Stream<User?>.empty();
    }
    return _auth.authStateChanges();
  }

  // Sign up with email and password
  Future<UserCredential> signUp(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        // Delete user account
        await user.delete();
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Handle Firebase Auth errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'Password is too weak';
        case 'email-already-in-use':
          return 'Email is already registered';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'user-disabled':
          return 'User account has been disabled';
        case 'too-many-requests':
          return 'Too many failed attempts. Try again later';
        case 'operation-not-allowed':
          return 'Operation not allowed';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return 'An unexpected error occurred';
  }
}