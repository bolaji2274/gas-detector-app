import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart'; // ← Add this import

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // ← Add this line

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Initialize service
  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Auth state change handler
  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;

    if (user != null) {
      // Update FCM token
      await _updateFCMToken();

      // Update last login
      await _updateLastLogin();
    }

    notifyListeners();
  }

  // Check if user is authenticated
  bool get isAuthenticated => _user != null;

  // ==================== EMAIL/PASSWORD AUTH ====================

  /// Sign up with email and password
  Future<bool> signUpWithEmail(
      String email, String password, String name) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create user
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Create user profile in database
      await _createUserProfile(credential.user!, name);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Remove FCM token from database
      if (_user != null) {
        await _database.ref('users/${_user!.uid}/fcmToken').remove();
      }

      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // ==================== GOOGLE SIGN IN (Optional) ====================

  /// Sign in with Google
  /// Requires google_sign_in package
  /*
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase
      UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      // Create user profile if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(
          userCredential.user!,
          userCredential.user!.displayName ?? 'User',
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google sign in failed';
      notifyListeners();
      return false;
    }
  }
  */

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Create user profile if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(
          userCredential.user!,
          userCredential.user!.displayName ?? 'User',
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google sign in failed: ${e.toString()}';
      notifyListeners();
      print('Google sign in error: $e');
      return false;
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  // ==================== USER PROFILE ====================

  /// Create user profile in database
  Future<void> _createUserProfile(User user, String displayName) async {
    try {
      // Get FCM token
      String? fcmToken = await _messaging.getToken();

      await _database.ref('users/${user.uid}').set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'photoURL': user.photoURL ?? '',
        'createdAt': ServerValue.timestamp,
        'lastLogin': ServerValue.timestamp,
        'fcmToken': fcmToken ?? '',
        'devices': [],
        'settings': {
          'notifications': {
            'push': true,
            'email': true,
            'sms': false,
          },
          'language': 'en',
          'theme': 'light',
          'units': 'metric',
        },
      });
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  /// Update FCM token
  Future<void> _updateFCMToken() async {
    try {
      if (_user == null) return;

      // Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _messaging.getToken();

        if (token != null) {
          await _database.ref('users/${_user!.uid}/fcmToken').set(token);
          print('FCM Token updated: $token');
        }
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin() async {
    try {
      if (_user == null) return;

      await _database.ref('users/${_user!.uid}/lastLogin').set(
            ServerValue.timestamp,
          );
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  /// Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (_user == null) return null;

      final snapshot = await _database.ref('users/${_user!.uid}').get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(
          snapshot.value as Map<dynamic, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user display name
  Future<bool> updateDisplayName(String newName) async {
    try {
      if (_user == null) return false;

      await _user!.updateDisplayName(newName);
      await _database.ref('users/${_user!.uid}/displayName').set(newName);

      // Reload user to get updated info
      await _user!.reload();
      _user = _auth.currentUser;

      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating display name: $e');
      return false;
    }
  }

  /// Update user email
  Future<bool> updateEmail(String newEmail, String password) async {
    try {
      if (_user == null) return false;

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );

      await _user!.reauthenticateWithCredential(credential);

      // Update email
      // await _user!.updateEmail(newEmail);
      await _user!.verifyBeforeUpdateEmail(newEmail);
      await _database.ref('users/${_user!.uid}/email').set(newEmail);

      // Reload user
      await _user!.reload();
      _user = _auth.currentUser;

      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating email: $e');
      _errorMessage = 'Failed to update email. Please check your password.';
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      if (_user == null) return false;

      // Re-authenticate
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );

      await _user!.reauthenticateWithCredential(credential);

      // Update password
      await _user!.updatePassword(newPassword);

      return true;
    } catch (e) {
      print('Error changing password: $e');
      _errorMessage =
          'Failed to change password. Please check your current password.';
      notifyListeners();
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount(String password) async {
    try {
      if (_user == null) return false;

      // Re-authenticate
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );

      await _user!.reauthenticateWithCredential(credential);

      // Delete user data from database
      await _database.ref('users/${_user!.uid}').remove();

      // Delete user account
      await _user!.delete();

      return true;
    } catch (e) {
      print('Error deleting account: $e');
      _errorMessage = 'Failed to delete account';
      notifyListeners();
      return false;
    }
  }

  // ==================== USER SETTINGS ====================

  /// Update user settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      if (_user == null) return;

      await _database.ref('users/${_user!.uid}/settings').update(settings);
    } catch (e) {
      print('Error updating settings: $e');
    }
  }

  /// Get user settings
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      if (_user == null) return null;

      final snapshot =
          await _database.ref('users/${_user!.uid}/settings').get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(
          snapshot.value as Map<dynamic, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error getting settings: $e');
      return null;
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Get user-friendly error message
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      default:
        return 'An error occurred. Please try again';
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
