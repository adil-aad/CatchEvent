import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../screens/student/event_details_screen.dart';
import 'event_card.dart';

/// A single [EventCard] wired to [EventProvider] and the details route.
///
/// This is the one place that connects a card to app state: the heart's
/// selected state, the save toggle and the tap-through to details. The list
/// and column widgets below both build from it, so every event list behaves
/// identically.
class EventCardTile extends StatelessWidget {
  final EventModel event;

  const EventCardTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return EventCard(
      event: event,
      isSaved: eventProvider.isSaved(event.id),
      onToggleSave: () => _toggleSave(context),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventDetailsScreen(eventId: event.id),
        ),
      ),
    );
  }

  Future<void> _toggleSave(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<EventProvider>().toggleSaved(event.id);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

/// Scrollable list of events, with an empty state. Used by the student Home
/// and Saved screens.
class EventListView extends StatelessWidget {
  final List<EventModel> events;

  /// Shown instead of the cards when [events] is empty.
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;

  /// Optional content above the list that scrolls with it — the home screen
  /// passes its search field and category chips here.
  final Widget? header;

  const EventListView({
    super.key,
    required this.events,
    required this.emptyTitle,
    required this.emptyMessage,
    this.emptyIcon = Icons.event_busy_outlined,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (header != null) header!,
          const SizedBox(height: 48),
          EventEmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ],
      );
    }

    final hasHeader = header != null;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length + (hasHeader ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasHeader && index == 0) return header!;
        final event = events[hasHeader ? index - 1 : index];
        return EventCardTile(event: event);
      },
    );
  }
}

/// Non-scrolling column of event cards, for embedding inside another scroll
/// view — used by the My Events screen's Upcoming / Past sections.
class EventColumn extends StatelessWidget {
  final List<EventModel> events;

  const EventColumn({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final event in events) EventCardTile(event: event),
        ],
      ),
    );
  }
}

/// Centred icon + message shown when an event list has nothing in it.
class EventEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EventEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
