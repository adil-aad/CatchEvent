// Tests for the parts of CatchEvent that need no Firebase connection: the
// form validators, the event model's display helpers, and a widget that takes
// no provider.
//
// The screens themselves are not tested here — they read from Firestore
// through the providers, which would need a live backend or a fake.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catchevent/models/event_model.dart';
import 'package:catchevent/utils/validators.dart';
import 'package:catchevent/widgets/event_list_view.dart';

/// A sample event: 30 of 50 seats taken, so it is neither empty nor full.
EventModel buildEvent({int capacity = 50, int registeredCount = 30}) {
  return EventModel(
    id: 'e1',
    title: 'Tech Talk',
    description: 'A talk about Flutter.',
    category: 'Technology',
    imageUrl: '',
    organizerId: 'org1',
    organizerName: 'CS Society',
    date: '2026-10-15',
    startTime: '14:00',
    endTime: '17:00',
    location: 'Main Hall',
    capacity: capacity,
    registeredCount: registeredCount,
  );
}

void main() {
  group('Validators', () {
    test('email accepts a normal address and rejects a malformed one', () {
      expect(Validators.email('student@campus.edu'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('password requires at least six characters', () {
      expect(Validators.password('secret'), isNull);
      expect(Validators.password('12345'), isNotNull);
    });

    test('capacity must be a whole number of at least one', () {
      expect(Validators.capacity('50'), isNull);
      expect(Validators.capacity('0'), isNotNull);
      expect(Validators.capacity('ten'), isNotNull);
    });

    test('imageUrl is optional but must be http(s) when given', () {
      // Empty is allowed — the card falls back to a placeholder.
      expect(Validators.imageUrl(''), isNull);
      expect(Validators.imageUrl(null), isNull);

      // A bare host has no path, which an earlier version wrongly rejected.
      expect(Validators.imageUrl('https://example.com'), isNull);
      expect(Validators.imageUrl('https://example.com/photo.jpg'), isNull);

      expect(Validators.imageUrl('example.com/photo.jpg'), isNotNull);
      expect(Validators.imageUrl('ftp://example.com/photo.jpg'), isNotNull);
    });
  });

  group('EventModel', () {
    test('tracks remaining seats', () {
      final event = buildEvent();
      expect(event.spotsLeft, 20);
      expect(event.isFull, isFalse);
    });

    test('is full once registrations reach capacity', () {
      final event = buildEvent(capacity: 30, registeredCount: 30);
      expect(event.isFull, isTrue);
      expect(event.spotsLeft, 0);
    });

    test('never reports negative seats', () {
      final event = buildEvent(capacity: 10, registeredCount: 12);
      expect(event.spotsLeft, 0);
    });

    test('formats the stored date and times for display', () {
      final event = buildEvent();
      expect(event.shortDate, 'Oct 15');
      expect(event.longDate, 'October 15, 2026');
      // Asserted loosely: the separator intl puts before AM/PM varies.
      expect(event.timeRange, contains('2:00'));
      expect(event.timeRange, contains('5:00'));
    });

    test('toMap omits registeredCount so an edit cannot overwrite it', () {
      expect(buildEvent().toMap().containsKey('registeredCount'), isFalse);
    });

    test('round-trips through fromMap', () {
      final event = buildEvent();
      final restored = EventModel.fromMap(event.id, {
        ...event.toMap(),
        'registeredCount': event.registeredCount,
      });
      expect(restored.title, event.title);
      expect(restored.capacity, event.capacity);
      expect(restored.registeredCount, event.registeredCount);
    });
  });

  group('EventEmptyState', () {
    testWidgets('shows the title and message it is given', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No events yet',
              message: 'Check back soon.',
            ),
          ),
        ),
      );

      expect(find.text('No events yet'), findsOneWidget);
      expect(find.text('Check back soon.'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
    });
  });
}
