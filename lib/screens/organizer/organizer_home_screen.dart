import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/event_image.dart';
import '../../widgets/event_list_view.dart';
import '../profile_screen.dart';
import 'create_event_screen.dart';
import 'edit_event_screen.dart';
import 'registrations_screen.dart';

/// Organizer shell: My Events / Create Event / Profile.
///
/// "Create Event" pushes a route rather than being a stacked tab, so the form
/// starts empty each time instead of holding stale input.
class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({super.key});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  /// Index into [_tabs] — the navigation bar's middle item is an action, not
  /// a tab, so bar index 2 (Profile) maps to tab index 1.
  int _tabIndex = 0;

  static const _tabs = <Widget>[
    _OrganizerEventsTab(),
    ProfileScreen(),
  ];

  static const int _createDestination = 1;

  void _onDestinationSelected(int index) {
    if (index == _createDestination) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateEventScreen()),
      );
      return;
    }
    setState(() => _tabIndex = index == 0 ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex == 0 ? 0 : 2,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'My Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create Event',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// The organizer's own events, each with Edit / Registrations / Delete.
class _OrganizerEventsTab extends StatelessWidget {
  const _OrganizerEventsTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();
    final organizerId = auth.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Events',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateEventScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
      body: SafeArea(
        top: false,
        child: Builder(
          builder: (context) {
            if (organizerId == null || eventProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (eventProvider.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    eventProvider.errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final events = eventProvider.organizerEvents(organizerId);
            if (events.isEmpty) {
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  SizedBox(height: 56),
                  EventEmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'No events yet',
                    message: 'Tap "New Event" to create your first event.',
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: events.length,
              itemBuilder: (context, index) => _OrganizerEventCard(
                event: events[index],
                organizerId: organizerId,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One of the organizer's events with its management actions.
class _OrganizerEventCard extends StatelessWidget {
  final EventModel event;
  final String organizerId;

  const _OrganizerEventCard({required this.event, required this.organizerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: EventImage(
                    imageUrl: event.imageUrl,
                    height: 72,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.shortDate} · ${event.timeRange}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.registeredCount} / ${event.capacity} registered',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditEventScreen(event: event),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RegistrationsScreen(event: event),
                    ),
                  ),
                  icon: const Icon(Icons.groups_outlined, size: 18),
                  label: const Text('Students'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Confirmation dialog from Project.md §14, then delete.
  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final eventProvider = context.read<EventProvider>();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text(
          'Are you sure you want to delete this event? '
          'Its registrations will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!(shouldDelete ?? false)) return;

    final error = await eventProvider.deleteEvent(event.id, organizerId);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Event deleted.')),
    );
  }
}
