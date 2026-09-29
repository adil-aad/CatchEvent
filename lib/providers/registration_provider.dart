import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/registration_model.dart';
import '../models/user_model.dart';
import '../services/registration_service.dart';
import '../utils/app_exception.dart';

/// Tracks which events the signed-in student is registered for, and performs
/// register / unregister.
class RegistrationProvider extends ChangeNotifier {
  final RegistrationService _registrationService;

  StreamSubscription<Set<String>>? _registrationsSubscription;
  String? _boundUserId;

  Set<String> _registeredEventIds = <String>{};
  bool _isLoading = true;

  /// Event id currently being registered/unregistered, so only that button
  /// shows a spinner.
  String? _pendingEventId;

  RegistrationProvider({RegistrationService? registrationService})
      : _registrationService = registrationService ?? RegistrationService();

  bool get isLoading => _isLoading;
  Set<String> get registeredEventIds => Set.unmodifiable(_registeredEventIds);

  bool isRegistered(String eventId) => _registeredEventIds.contains(eventId);
  bool isPending(String eventId) => _pendingEventId == eventId;

  /// Live list of students registered for one event (organizer view).
  Stream<List<RegistrationModel>> streamEventRegistrations(String eventId) =>
      _registrationService.streamEventRegistrations(eventId);

  /// Points the provider at the signed-in user. Must not notify listeners
  /// synchronously — it is called from a `ChangeNotifierProxyProvider`.
  void bind(String? userId) {
    if (_boundUserId == userId) return;
    _boundUserId = userId;

    _registrationsSubscription?.cancel();

    if (userId == null) {
      _registrationsSubscription = null;
      _registeredEventIds = <String>{};
      _isLoading = true;
      return;
    }

    _isLoading = true;
    _registrationsSubscription =
        _registrationService.streamRegisteredEventIds(userId).listen(
      (ids) {
        _registeredEventIds = ids;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object _) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Registers [student] for the event. Returns `null` on success, or a
  /// message such as `Event Full` / `You are already registered…`.
  Future<String?> register({
    required String eventId,
    required UserModel student,
  }) async {
    return _run(eventId, () async {
      await _registrationService.register(eventId: eventId, student: student);
    });
  }

  /// Cancels the student's registration. Returns `null` on success.
  Future<String?> unregister({
    required String eventId,
    required String studentId,
  }) async {
    return _run(eventId, () async {
      await _registrationService.unregister(
        eventId: eventId,
        studentId: studentId,
      );
    });
  }

  /// Shared pending/error wrapper. The registered-id set refreshes itself via
  /// the Firestore subscription, so nothing is updated locally here.
  Future<String?> _run(String eventId, Future<void> Function() action) async {
    if (_pendingEventId != null) return null; // ignore double taps
    _pendingEventId = eventId;
    notifyListeners();
    try {
      await action();
      return null;
    } on AppException catch (e) {
      return e.message;
    } on Exception {
      return 'Something went wrong. Please try again.';
    } finally {
      _pendingEventId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _registrationsSubscription?.cancel();
    super.dispose();
  }
}
