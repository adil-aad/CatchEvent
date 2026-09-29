import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../widgets/event_form.dart';

/// Create a new event. Opened from the organizer's "Create Event" tab.
///
/// The form itself lives in [EventForm], shared with the edit screen.
class CreateEventScreen extends StatelessWidget {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: EventForm(
        submitLabel: 'Create Event',
        onSubmit: (event) => _create(context, event),
      ),
    );
  }

  /// Returns null on success (closing the screen), or an error message which
  /// the form shows in a SnackBar.
  Future<String?> _create(BuildContext context, EventModel event) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final error = await context.read<EventProvider>().createEvent(event);
    if (error != null) return error;

    messenger.showSnackBar(const SnackBar(content: Text('Event created.')));
    navigator.pop();
    return null;
  }
}
