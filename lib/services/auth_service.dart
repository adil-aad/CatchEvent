import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';

/// Wraps Firebase Authentication and the `users` collection.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);

  /// Emits the signed-in Firebase user, or `null` after sign-out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Creates the auth account and its matching `users/{uid}` document.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      final trimmedName = name.trim();

      await credential.user!.updateDisplayName(trimmedName);

      final profile = UserModel(
        uid: uid,
        name: trimmedName,
        email: email.trim(),
        role: role,
      );

      await _users.doc(uid).set(<String, dynamic>{
        ...profile.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return profile;
    } on FirebaseAuthException catch (e) {
      throw AppException(_authErrorMessage(e));
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final profile = await fetchUser(credential.user!.uid);
      if (profile == null) {
        throw const AppException(
          'Your account has no profile data. Please sign up again.',
        );
      }
      return profile;
    } on FirebaseAuthException catch (e) {
      throw AppException(_authErrorMessage(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Reads the `users/{uid}` profile document, or `null` when it is missing.
  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  /// Maps Firebase error codes to messages suitable for the UI.
  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email is already registered. Try logging in.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
