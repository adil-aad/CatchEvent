import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/registration_provider.dart';
import '../utils/constants.dart';

/// Profile tab: account details and sign out.
///
/// Shared by the student and organizer bottom navigation bars — the content is
/// the same for both roles, with the counters swapped for role-appropriate
/// ones. (Project.md lists only `student_profile_screen.dart`; one screen
/// serving both navs avoids duplicating it.)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          _initials(user.name),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Chip(
                        avatar: Icon(
                          user.isOrganizer
                              ? Icons.campaign_outlined
                              : Icons.school_outlined,
                          size: 18,
                        ),
                        label: Text(
                          user.isOrganizer ? 'Organizer' : 'Student',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _StatsRow(isOrganizer: user.isOrganizer, userId: user.uid),
                const SizedBox(height: 28),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: theme.colorScheme.errorContainer,
                  leading: Icon(
                    Icons.logout,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  title: Text(
                    'Log Out',
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _confirmLogout(context),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    AppConstants.appName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Up to two initials from the user's name, for the avatar.
  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('You will need to log in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout ?? false) {
      // The auth gate in main.dart returns to the login screen on its own.
      await auth.signOut();
    }
  }
}

/// Two summary tiles, worded for the user's role.
class _StatsRow extends StatelessWidget {
  final bool isOrganizer;
  final String userId;

  const _StatsRow({required this.isOrganizer, required this.userId});

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>();

    if (isOrganizer) {
      final mine = events.organizerEvents(userId);
      return Row(
        children: [
          _StatTile(
            icon: Icons.event_note_outlined,
            value: '${mine.length}',
            label: 'Events created',
          ),
          const SizedBox(width: 12),
          _StatTile(
            icon: Icons.groups_outlined,
            value: '${mine.fold<int>(0, (sum, e) => sum + e.registeredCount)}',
            label: 'Total registrations',
          ),
        ],
      );
    }

    final registrations = context.watch<RegistrationProvider>();
    return Row(
      children: [
        _StatTile(
          icon: Icons.favorite_border,
          value: '${events.savedEvents.length}',
          label: 'Saved events',
        ),
        const SizedBox(width: 12),
        _StatTile(
          icon: Icons.confirmation_number_outlined,
          value: '${registrations.registeredEventIds.length}',
          label: 'Registered',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
