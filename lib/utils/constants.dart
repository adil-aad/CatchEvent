/// App-wide constant values: collection names, roles and event categories.
class AppConstants {
  AppConstants._();

  static const String appName = 'CatchEvent';

  /// Placeholder API key shipped in `firebase_options.dart` before
  /// `flutterfire configure` has been run. `main.dart` compares against this
  /// to show the setup screen instead of failing with an opaque Firebase
  /// error. Kept here because the generated options file gets overwritten.
  static const String unconfiguredFirebaseApiKey =
      'REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE';

  // ---- Firestore collections ----
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String registrationsCollection = 'registrations';
  static const String savedEventsCollection = 'savedEvents';

  // ---- User roles ----
  static const String roleStudent = 'student';
  static const String roleOrganizer = 'organizer';

  // ---- Event categories ----
  static const String allCategories = 'All';

  static const List<String> categories = <String>[
    'Technology',
    'Academic',
    'Sports',
    'Career',
    'Workshop',
    'Social',
    'Club',
    'Other',
  ];

  /// Categories prefixed with "All", used by the filter chip row.
  static const List<String> categoryFilters = <String>[
    allCategories,
    ...categories,
  ];
}
