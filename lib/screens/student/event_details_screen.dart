import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/registration_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/event_image.dart';

/// Full details for one event, with the save and register actions.
///
/// Takes an id rather than an [EventModel] and reads the event back out of
/// [EventProvider], whose Firestore subscription is live — so the
/// "Registered: 24 / 50" counter updates while this screen is open, and the
/// screen reacts if the organizer deletes the event.
class EventDetailsScreen extends StatelessWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final event = eventProvider.eventById(eventId);

    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This event is no longer available.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isSaved = eventProvider.isSaved(event.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            tooltip: isSaved ? 'Remove from saved' : 'Save event',
            onPressed: () => _toggleSave(context, event.id),
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
      body: _DetailsBody(event: event),
      bottomNavigationBar: _RegisterBar(event: event),
    );
  }

  Future<void> _toggleSave(BuildContext context, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<EventProvider>().toggleSaved(id);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _DetailsBody extends StatelessWidget {
  final EventModel event;

  const _DetailsBody({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        EventImage(imageUrl: event.imageUrl, height: 200),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event.category,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: event.longDate,
              ),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: 'Time',
                value: event.timeRange,
              ),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: event.location,
              ),
              _DetailRow(
                icon: Icons.person_outline,
                label: 'Organizer',
                value: event.organizerName.isEmpty
                    ? 'Unknown organizer'
                    : event.organizerName,
              ),
              _DetailRow(
                icon: Icons.groups_outlined,
                label: 'Registered',
                value: '${event.registeredCount} / ${event.capacity}',
              ),
              const SizedBox(height: 20),
              Text(
                'About this event',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                event.description.isEmpty
                    ? 'No description provided.'
                    : event.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One labelled detail line with a leading icon.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Persistent bottom bar holding the Register / Registered / Event Full button.
class _RegisterBar extends StatelessWidget {
  final EventModel event;

  const _RegisterBar({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final registrations = context.watch<RegistrationProvider>();

    // Organizers browsing their own event do not register for it.
    if (!auth.isStudent) return const SizedBox.shrink();

    final isRegistered = registrations.isRegistered(event.id);
    final isPending = registrations.isPending(event.id);
    final isFull = event.isFull;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRegistered && !isFull)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${event.spotsLeft} ${event.spotsLeft == 1 ? 'spot' : 'spots'} left',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (isRegistered)
              CustomButton(
                label: 'Registered',
                icon: Icons.check_circle_outline,
                outlined: true,
                isLoading: isPending,
                onPressed: () => _unregister(context, auth),
              )
            else if (isFull)
              const CustomButton(
                label: 'Event Full',
                onPressed: null,
              )
            else
              CustomButton(
                label: 'Register',
                isLoading: isPending,
                onPressed: () => _register(context, auth),
              ),
            if (isRegistered)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tap to unregister',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _register(BuildContext context, AuthProvider auth) async {
    final student = auth.user;
    if (student == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<RegistrationProvider>().register(
          eventId: event.id,
          student: student,
        );
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'You are registered for this event.')),
    );
  }

  Future<void> _unregister(BuildContext context, AuthProvider auth) async {
    final student = auth.user;
    if (student == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<RegistrationProvider>().unregister(
          eventId: event.id,
          studentId: student.uid,
        );
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Registration cancelled.')),
    );
  }
}
