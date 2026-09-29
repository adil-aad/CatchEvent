import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_exception.dart';

/// Where the user is in the sign-in lifecycle.
enum AuthStatus {
  /// Still restoring the session on startup — show the splash screen.
  unknown,
  authenticated,
  unauthenticated,
}

/// Owns the signed-in user and exposes sign up / sign in / sign out.
///
/// Listens to [AuthService.authStateChanges] so a restored session on app
/// launch, and sign-out from anywhere, both route the UI automatically.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _busy = false;
  String? _errorMessage;

  /// True while [signUp] or [signIn] is running.
  ///
  /// Those methods load the profile themselves, so the auth stream must not
  /// race them. It matters most on sign-up: Firebase signs the new account in
  /// the moment it is created, which fires [AuthService.authStateChanges]
  /// before the `users/{uid}` document has been written — and a profile lookup
  /// that lost that race would sign the brand-new account straight back out.
  bool _explicitAuthInProgress = false;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _authSubscription = _authService.authStateChanges.listen(_onAuthChanged);
  }

  AuthStatus get status => _status;
  UserModel? get user => _user;

  /// True while a sign-in / sign-up request is in flight.
  bool get isBusy => _busy;
  String? get errorMessage => _errorMessage;

  bool get isStudent => _user?.isStudent ?? false;
  bool get isOrganizer => _user?.isOrganizer ?? false;

  /// Reacts to Firebase session changes: loads the Firestore profile on sign
  /// in, clears it on sign out.
  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // signUp / signIn are mid-flight and set the profile themselves.
    if (_explicitAuthInProgress) return;

    // Already loaded this user (e.g. the stream firing right after signUp).
    if (_user?.uid == firebaseUser.uid && _status == AuthStatus.authenticated) {
      return;
    }

    try {
      final profile = await _authService.fetchUser(firebaseUser.uid);
      if (profile == null) {
        // Auth account with no profile document — treat as signed out.
        await _authService.signOut();
        return;
      }
      _user = profile;
      _status = AuthStatus.authenticated;
    } on Exception {
      _user = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Returns true on success. On failure [errorMessage] holds the reason.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    return _run(() async {
      _user = await _authService.signUp(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      _status = AuthStatus.authenticated;
    });
  }

  /// Returns true on success. On failure [errorMessage] holds the reason.
  Future<bool> signIn({required String email, required String password}) {
    return _run(() async {
      _user = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
    });
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Shared busy/error wrapper for the auth actions.
  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    _explicitAuthInProgress = true;
    notifyListeners();
    try {
      await action();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      await _discardPartialSession();
      return false;
    } on Exception {
      _errorMessage = 'Something went wrong. Please try again.';
      await _discardPartialSession();
      return false;
    } finally {
      _explicitAuthInProgress = false;
      _busy = false;
      notifyListeners();
    }
  }

  /// Sign-up can fail *after* the Firebase account was created — for example
  /// if the profile write is rejected. Leaving that half-made session signed
  /// in would strand the user in an account with no profile, so it is undone.
  Future<void> _discardPartialSession() async {
    if (_user != null || _authService.currentUser == null) return;
    try {
      await _authService.signOut();
    } on Exception {
      // Nothing more to do — the UI already shows the original error.
    }
    _status = AuthStatus.unauthenticated;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
