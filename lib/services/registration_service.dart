import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/registration_model.dart';
import '../models/user_model.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';

/// Handles the `registrations` collection.
///
/// Registration documents use a deterministic id (`eventId_studentId`) and the
/// running total lives on the event document as `registeredCount`. Both are
/// written inside a single transaction, which is what makes "no duplicate
/// registration" and "no registering when full" hold even if the student taps
/// twice or two students register at the same moment.
class RegistrationService {
  final FirebaseFirestore _db;

  RegistrationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _registrations =>
      _db.collection(AppConstants.registrationsCollection);

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection(AppConstants.eventsCollection);

  String _registrationId(String eventId, String studentId) =>
      '${eventId}_$studentId';

  // ---------------------------------------------------------------- reads

  /// Event ids the student is registered for, kept live. Drives the My Events
  /// screen and the Register/Registered button state.
  Stream<Set<String>> streamRegisteredEventIds(String studentId) {
    return _registrations
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => (doc.data()['eventId'] ?? '') as String)
              .where((id) => id.isNotEmpty)
              .toSet(),
        );
  }

  /// Students registered for one event, newest first. Used by the organizer's
  /// registrations screen. Sorted in Dart to avoid a composite index.
  Stream<List<RegistrationModel>> streamEventRegistrations(String eventId) {
    return _registrations
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
      final registrations =
          snapshot.docs.map(RegistrationModel.fromDoc).toList();
      registrations.sort((a, b) {
        final aTime = a.registeredAt;
        final bTime = b.registeredAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      return registrations;
    });
  }

  // --------------------------------------------------------------- writes

  /// Registers [student] for [eventId].
  ///
  /// Throws an [AppException] if the event is gone, the student already
  /// registered, or the event is full.
  Future<void> register({
    required String eventId,
    required UserModel student,
  }) async {
    final eventRef = _events.doc(eventId);
    final registrationRef =
        _registrations.doc(_registrationId(eventId, student.uid));

    await _db.runTransaction((transaction) async {
      // All reads must happen before any write inside a transaction.
      final eventSnapshot = await transaction.get(eventRef);
      final existing = await transaction.get(registrationRef);

      if (!eventSnapshot.exists) {
        throw const AppException('This event no longer exists.');
      }
      if (existing.exists) {
        throw const AppException('You are already registered for this event.');
      }

      final data = eventSnapshot.data()!;
      final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
      final registered = (data['registeredCount'] as num?)?.toInt() ?? 0;

      if (registered >= capacity) {
        throw const AppException('Event Full');
      }

      transaction.set(registrationRef, <String, dynamic>{
        'eventId': eventId,
        'studentId': student.uid,
        'studentName': student.name,
        'studentEmail': student.email,
        'registeredAt': FieldValue.serverTimestamp(),
      });
      transaction.update(eventRef, <String, dynamic>{
        'registeredCount': FieldValue.increment(1),
      });
    });
  }

  /// Cancels a registration and decrements the event's counter.
  ///
  /// The counter is only decremented when a registration document actually
  /// existed, so a double tap cannot push the count below zero.
  Future<void> unregister({
    required String eventId,
    required String studentId,
  }) async {
    final eventRef = _events.doc(eventId);
    final registrationRef =
        _registrations.doc(_registrationId(eventId, studentId));

    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(registrationRef);
      if (!existing.exists) {
        return; // already unregistered — nothing to do
      }
      final eventSnapshot = await transaction.get(eventRef);

      transaction.delete(registrationRef);

      if (eventSnapshot.exists) {
        final current =
            (eventSnapshot.data()?['registeredCount'] as num?)?.toInt() ?? 0;
        transaction.update(eventRef, <String, dynamic>{
          'registeredCount': current > 0 ? FieldValue.increment(-1) : 0,
        });
      }
    });
  }
}
