import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';

/// Reads and writes the `events` collection, plus the `savedEvents` bookmarks.
///
/// Queries deliberately avoid combining an equality filter with an `orderBy`
/// on a different field, so the app runs against a fresh Firestore database
/// without needing any composite indexes. Small result sets are sorted in Dart
/// instead.
class EventService {
  final FirebaseFirestore _db;

  EventService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection(AppConstants.eventsCollection);

  CollectionReference<Map<String, dynamic>> get _saved =>
      _db.collection(AppConstants.savedEventsCollection);

  CollectionReference<Map<String, dynamic>> get _registrations =>
      _db.collection(AppConstants.registrationsCollection);

  /// Deterministic id so a user can bookmark an event at most once.
  String _savedId(String userId, String eventId) => '${userId}_$eventId';

  // ---------------------------------------------------------------- reads

  /// Every event, earliest first.
  ///
  /// The app streams this single query and derives "upcoming" in Dart via
  /// [EventModel.isUpcoming]. One subscription serves the home, Saved and My
  /// Events screens, and a bookmarked or registered event does not vanish from
  /// Saved / My Events once its date passes.
  Stream<List<EventModel>> streamAllEvents() {
    return _events.orderBy('date').snapshots().map(_toEvents);
  }

  List<EventModel> _toEvents(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map(EventModel.fromDoc).toList();
  }

  // --------------------------------------------------------------- writes

  /// Creates an event and returns its new document id.
  Future<String> createEvent(EventModel event) async {
    final doc = await _events.add(<String, dynamic>{
      ...event.toMap(),
      'registeredCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Updates an event. Rejects the write unless [organizerId] owns it.
  ///
  /// `toMap()` omits `registeredCount`, so the live count is preserved.
  Future<void> updateEvent(EventModel event, String organizerId) async {
    await _assertOwner(event.id, organizerId);
    await _events.doc(event.id).update(event.toMap());
  }

  /// Deletes an event along with its registrations and bookmarks, so no
  /// orphaned rows are left behind for the Saved and My Events screens.
  Future<void> deleteEvent(String eventId, String organizerId) async {
    await _assertOwner(eventId, organizerId);

    final registrations =
        await _registrations.where('eventId', isEqualTo: eventId).get();
    final bookmarks = await _saved.where('eventId', isEqualTo: eventId).get();

    final batch = _db.batch();
    for (final doc in registrations.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in bookmarks.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_events.doc(eventId));
    await batch.commit();
  }

  /// Throws unless the event exists and was created by [organizerId].
  Future<void> _assertOwner(String eventId, String organizerId) async {
    final doc = await _events.doc(eventId).get();
    if (!doc.exists) {
      throw const AppException('This event no longer exists.');
    }
    if (doc.data()?['organizerId'] != organizerId) {
      throw const AppException('You can only manage events you created.');
    }
  }

  // -------------------------------------------------------- saved events

  /// The set of event ids the user has bookmarked, kept live.
  Stream<Set<String>> streamSavedEventIds(String userId) {
    return _saved.where('userId', isEqualTo: userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => (doc.data()['eventId'] ?? '') as String)
              .where((id) => id.isNotEmpty)
              .toSet(),
        );
  }

  /// Bookmarks or un-bookmarks an event. Saving does not register the student.
  Future<void> setSaved({
    required String userId,
    required String eventId,
    required bool saved,
  }) async {
    final ref = _saved.doc(_savedId(userId, eventId));
    if (saved) {
      await ref.set(<String, dynamic>{
        'eventId': eventId,
        'userId': userId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }
}
