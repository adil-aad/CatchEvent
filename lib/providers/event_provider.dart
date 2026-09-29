import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';

/// Owns the event list, the search/category filters and saved-event state.
///
/// A single Firestore subscription backs every event screen; the home, Saved,
/// My Events and organizer lists are all derived from it in Dart. That keeps
/// reads low and means every list updates live when Firestore changes.
class EventProvider extends ChangeNotifier {
  final EventService _eventService;

  StreamSubscription<List<EventModel>>? _eventsSubscription;
  StreamSubscription<Set<String>>? _savedSubscription;

  /// The uid the current subscriptions belong to, so [bind] is idempotent.
  String? _boundUserId;

  List<EventModel> _events = <EventModel>[];
  Set<String> _savedEventIds = <String>{};
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedCategory = AppConstants.allCategories;

  EventProvider({EventService? eventService})
      : _eventService = eventService ?? EventService();

  // --------------------------------------------------------------- getters

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<EventModel> get allEvents => List.unmodifiable(_events);

  /// Upcoming events matching the current search text and category chip.
  /// Powers the student home screen.
  List<EventModel> get homeEvents {
    final query = _searchQuery.trim().toLowerCase();
    return _events.where((event) {
      if (!event.isUpcoming) return false;
      if (_selectedCategory != AppConstants.allCategories &&
          event.category != _selectedCategory) {
        return false;
      }
      // Case-insensitive title search.
      if (query.isNotEmpty && !event.title.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Events the student has bookmarked, in date order.
  List<EventModel> get savedEvents =>
      _events.where((event) => _savedEventIds.contains(event.id)).toList();

  bool get hasFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedCategory != AppConstants.allCategories;

  bool isSaved(String eventId) => _savedEventIds.contains(eventId);

  /// Events created by one organizer, newest dates last.
  List<EventModel> organizerEvents(String organizerId) =>
      _events.where((event) => event.organizerId == organizerId).toList();

  /// Looks up an event already in memory; `null` once it has been deleted.
  EventModel? eventById(String eventId) {
    for (final event in _events) {
      if (event.id == eventId) return event;
    }
    return null;
  }

  /// Events from [ids], preserving the provider's date ordering.
  List<EventModel> eventsByIds(Set<String> ids) =>
      _events.where((event) => ids.contains(event.id)).toList();

  // ----------------------------------------------------------- lifecycle

  /// Points the provider at the signed-in user.
  ///
  /// Called from a `ChangeNotifierProxyProvider`, so it must not notify
  /// listeners synchronously — the stream callbacks do that once data arrives.
  void bind(String? userId) {
    if (_boundUserId == userId) return;
    _boundUserId = userId;

    _eventsSubscription?.cancel();
    _savedSubscription?.cancel();

    if (userId == null) {
      _eventsSubscription = null;
      _savedSubscription = null;
      _events = <EventModel>[];
      _savedEventIds = <String>{};
      _isLoading = true;
      return;
    }

    _isLoading = true;
    _errorMessage = null;

    _eventsSubscription = _eventService.streamAllEvents().listen(
      (events) {
        _events = events;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = 'Could not load events. Check your connection.';
        notifyListeners();
      },
    );

    _savedSubscription = _eventService.streamSavedEventIds(userId).listen(
      (ids) {
        _savedEventIds = ids;
        notifyListeners();
      },
      onError: (Object _) {},
    );
  }

  // ------------------------------------------------------------- filters

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    if (!hasFilters) return;
    _searchQuery = '';
    _selectedCategory = AppConstants.allCategories;
    notifyListeners();
  }

  // --------------------------------------------------------------- writes

  /// Bookmarks or un-bookmarks an event. Saving never registers the student.
  ///
  /// Updates local state optimistically so the heart icon responds instantly,
  /// then reverts if the write fails.
  Future<String?> toggleSaved(String eventId) async {
    final userId = _boundUserId;
    if (userId == null) return 'You must be signed in to save events.';

    final wasSaved = _savedEventIds.contains(eventId);
    _savedEventIds = <String>{..._savedEventIds};
    wasSaved ? _savedEventIds.remove(eventId) : _savedEventIds.add(eventId);
    notifyListeners();

    try {
      await _eventService.setSaved(
        userId: userId,
        eventId: eventId,
        saved: !wasSaved,
      );
      return null;
    } on Exception {
      _savedEventIds = <String>{..._savedEventIds};
      wasSaved ? _savedEventIds.add(eventId) : _savedEventIds.remove(eventId);
      notifyListeners();
      return 'Could not update your saved events.';
    }
  }

  /// Creates an event. Returns `null` on success, or an error message.
  Future<String?> createEvent(EventModel event) async {
    try {
      await _eventService.createEvent(event);
      return null;
    } on AppException catch (e) {
      return e.message;
    } on Exception {
      return 'Could not create the event. Please try again.';
    }
  }

  /// Updates an event the organizer owns. Returns `null` on success.
  Future<String?> updateEvent(EventModel event, String organizerId) async {
    try {
      await _eventService.updateEvent(event, organizerId);
      return null;
    } on AppException catch (e) {
      return e.message;
    } on Exception {
      return 'Could not save your changes. Please try again.';
    }
  }

  /// Deletes an event the organizer owns. Returns `null` on success.
  Future<String?> deleteEvent(String eventId, String organizerId) async {
    try {
      await _eventService.deleteEvent(eventId, organizerId);
      return null;
    } on AppException catch (e) {
      return e.message;
    } on Exception {
      return 'Could not delete the event. Please try again.';
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _savedSubscription?.cancel();
    super.dispose();
  }
}
