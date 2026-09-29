import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/event_provider.dart';
import '../../widgets/event_list_view.dart';

/// Events the student bookmarked. Saving an event does not register them for
/// it, so this list is independent of My Events.
///
/// The heart button on each card removes the event from this list.
class SavedEventsScreen extends StatelessWidget {
  const SavedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: SafeArea(
        top: false,
        child: eventProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EventListView(
                events: eventProvider.savedEvents,
                emptyIcon: Icons.favorite_border,
                emptyTitle: 'No saved events',
                emptyMessage:
                    'Tap the heart on an event to save it for later.',
                header: const SizedBox(height: 8),
              ),
      ),
    );
  }
}
