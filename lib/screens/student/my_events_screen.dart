import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/registration_provider.dart';
import '../../widgets/event_list_view.dart';

/// Events the student has registered for, split into Upcoming and Past.
///
/// Opening an event from here leads to the details screen, where the
/// "Registered" button cancels the registration.
class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final registrations = context.watch<RegistrationProvider>();

    final isLoading = eventProvider.isLoading || registrations.isLoading;
    final registered =
        eventProvider.eventsByIds(registrations.registeredEventIds);
    final upcoming = registered.where((event) => event.isUpcoming).toList();
    final past = registered.where((event) => !event.isUpcoming).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Events')),
      body: SafeArea(
        top: false,
        child: _buildBody(isLoading, registered, upcoming, past),
      ),
    );
  }

  Widget _buildBody(
    bool isLoading,
    List<EventModel> registered,
    List<EventModel> upcoming,
    List<EventModel> past,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (registered.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: const [
          SizedBox(height: 56),
          EventEmptyState(
            icon: Icons.confirmation_number_outlined,
            title: 'No registrations yet',
            message: 'Register for an event and it will show up here.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      children: [
        if (upcoming.isNotEmpty) _Section(title: 'Upcoming', events: upcoming),
        if (past.isNotEmpty) _Section(title: 'Past', events: past),
      ],
    );
  }
}

/// A titled group of event cards inside the scrolling list.
class _Section extends StatelessWidget {
  final String title;
  final List<EventModel> events;

  const _Section({required this.title, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        EventColumn(events: events),
      ],
    );
  }
}
