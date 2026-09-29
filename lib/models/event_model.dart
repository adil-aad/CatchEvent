import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// An event document from the `events` collection.
///
/// `date` is stored as an ISO `yyyy-MM-dd` string and the times as `HH:mm`
/// strings, matching the schema in Project.md. ISO date strings sort
/// chronologically as plain strings, so Firestore `orderBy`/range queries on
/// `date` still behave correctly.
class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String organizerId;
  final String organizerName;
  final String date; // yyyy-MM-dd
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String location;
  final int capacity;

  /// Number of students currently registered.
  ///
  /// Maintained transactionally by [RegistrationService] alongside the
  /// registration documents, so capacity can be enforced atomically and the
  /// "24 / 50" counter is a single field read. Deliberately excluded from
  /// [toMap] so an organizer edit never overwrites it.
  final int registeredCount;

  final DateTime? createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.organizerId,
    required this.organizerName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.capacity,
    this.registeredCount = 0,
    this.createdAt,
  });

  /// True when no seats are left.
  bool get isFull => registeredCount >= capacity;

  /// Seats still available, never negative.
  int get spotsLeft {
    final left = capacity - registeredCount;
    return left < 0 ? 0 : left;
  }

  // ---- Parsing / formatting helpers used by the UI ----

  /// The event date as a [DateTime] (midnight local time).
  DateTime? get dateTime => DateTime.tryParse(date);

  /// `Oct 15` — used on event cards.
  String get shortDate {
    final parsed = dateTime;
    if (parsed == null) return date;
    return DateFormat('MMM d').format(parsed);
  }

  /// `October 15, 2026` — used on the details screen.
  String get longDate {
    final parsed = dateTime;
    if (parsed == null) return date;
    return DateFormat('MMMM d, y').format(parsed);
  }

  /// `2:00 PM - 5:00 PM`
  String get timeRange => '${_formatTime(startTime)} - ${_formatTime(endTime)}';

  /// True when the event date is today or later.
  bool get isUpcoming {
    final parsed = dateTime;
    if (parsed == null) return true;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return !parsed.isBefore(startOfToday);
  }

  /// Converts `14:00` to `2:00 PM`, falling back to the raw value.
  static String _formatTime(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return raw;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return raw;
    return DateFormat.jm().format(DateTime(2000, 1, 1, hour, minute));
  }

  // ---- Firestore serialisation ----

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    return EventModel(
      id: id,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      category: (map['category'] ?? 'Other') as String,
      imageUrl: (map['imageUrl'] ?? '') as String,
      organizerId: (map['organizerId'] ?? '') as String,
      organizerName: (map['organizerName'] ?? '') as String,
      date: (map['date'] ?? '') as String,
      startTime: (map['startTime'] ?? '') as String,
      endTime: (map['endTime'] ?? '') as String,
      location: (map['location'] ?? '') as String,
      capacity: (map['capacity'] as num?)?.toInt() ?? 0,
      registeredCount: (map['registeredCount'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory EventModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return EventModel.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  /// Shape written to Firestore. `createdAt` is added by the service using a
  /// server timestamp on create.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'capacity': capacity,
    };
  }

  EventModel copyWith({
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    String? date,
    String? startTime,
    String? endTime,
    String? location,
    int? capacity,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      organizerId: organizerId,
      organizerName: organizerName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      registeredCount: registeredCount,
      createdAt: createdAt,
    );
  }
}
