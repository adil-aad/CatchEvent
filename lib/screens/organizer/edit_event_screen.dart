import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/event_form.dart';

/// Edit an event the organizer created.
///
/// Ownership is re-checked in [EventProvider.updateEvent] and again by the
/// Firestore security rules, so only the creator can save changes.
class EditEventScreen extends StatelessWidget {
  final EventModel event;

  const EditEventScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: EventForm(
        initialEvent: event,
        submitLabel: 'Save Changes',
        onSubmit: (updated) => _update(context, updated),
      ),
    );
  }

  Future<String?> _update(BuildContext context, EventModel updated) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final organizerId = context.read<AuthProvider>().user?.uid;
    if (organizerId == null) return 'You are no longer signed in.';

    final error =
        await context.read<EventProvider>().updateEvent(updated, organizerId);
    if (error != null) return error;

    messenger.showSnackBar(const SnackBar(content: Text('Changes saved.')));
    navigator.pop();
    return null;
  }
}
