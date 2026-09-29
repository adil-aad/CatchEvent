import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../providers/registration_provider.dart';

/// Students registered for one of the organizer's events.
///
/// Streams the `registrations` rows for this event, so the list updates as
/// students register or cancel while the screen is open.
class RegistrationsScreen extends StatelessWidget {
  final EventModel event;

  const RegistrationsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrations')),
      body: StreamBuilder<List<RegistrationModel>>(
        stream: context
            .read<RegistrationProvider>()
            .streamEventRegistrations(event.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load registrations. Check your connection.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final registrations = snapshot.data ?? <RegistrationModel>[];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                event.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${registrations.length} / ${event.capacity} Registered',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${event.shortDate} · ${event.location}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 32),
              Text(
                'Registered Students',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (registrations.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No students have registered yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final registration in registrations)
                  _StudentTile(registration: registration),
            ],
          );
        },
      ),
    );
  }
}

/// One registered student: name, email and initial avatar.
class _StudentTile extends StatelessWidget {
  final RegistrationModel registration;

  const _StudentTile({required this.registration});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = registration.studentName.isEmpty
        ? 'Unnamed student'
        : registration.studentName;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(name),
      subtitle: Text(registration.studentEmail),
    );
  }
}
