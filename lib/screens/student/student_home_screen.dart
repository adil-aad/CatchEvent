import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/event_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/event_list_view.dart';
import '../profile_screen.dart';
import 'my_events_screen.dart';
import 'saved_events_screen.dart';

/// Student shell: the bottom navigation bar plus the Home tab itself.
///
/// Tabs are kept in an [IndexedStack] so scroll position and search text
/// survive switching between them.
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _tabIndex = 0;

  static const _tabs = <Widget>[
    _HomeTab(),
    SavedEventsScreen(),
    MyEventsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'My Events',
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

/// Upcoming events with a search field and category filter chips.
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.appName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Builder(
          builder: (context) {
            if (eventProvider.isLoading) {
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

            final events = eventProvider.homeEvents;
            return EventListView(
              events: events,
              header: _buildHeader(eventProvider),
              emptyIcon: eventProvider.hasFilters
                  ? Icons.search_off_outlined
                  : Icons.event_busy_outlined,
              emptyTitle: eventProvider.hasFilters
                  ? 'No matching events'
                  : 'No upcoming events',
              emptyMessage: eventProvider.hasFilters
                  ? 'Try a different search or category.'
                  : 'New events will appear here once organizers add them.',
            );
          },
        ),
      ),
    );
  }

  /// Search field + horizontal category chip row, scrolled with the list.
  Widget _buildHeader(EventProvider eventProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: eventProvider.setSearchQuery,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search events',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: eventProvider.searchQuery.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      eventProvider.setSearchQuery('');
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AppConstants.categoryFilters.length,
            itemBuilder: (context, index) {
              final category = AppConstants.categoryFilters[index];
              return CategoryChip(
                label: category,
                isSelected: eventProvider.selectedCategory == category,
                onSelected: () => eventProvider.setCategory(category),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
