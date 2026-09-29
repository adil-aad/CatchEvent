import 'package:flutter/material.dart';

import '../models/event_model.dart';
import 'event_image.dart';

/// Reusable event card used by the home, Saved and My Events screens.
///
/// Layout follows Project.md §6:
/// image, then title with the save toggle, category, date and location.
class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  /// Whether the current user has saved this event. Drives ♡ vs ♥.
  final bool isSaved;

  /// When null the save button is hidden (e.g. organizer-facing lists).
  final VoidCallback? onToggleSave;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isSaved = false,
    this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventImage(imageUrl: event.imageUrl, height: 150),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (onToggleSave != null)
                        IconButton(
                          onPressed: onToggleSave,
                          visualDensity: VisualDensity.compact,
                          tooltip: isSaved ? 'Remove from saved' : 'Save event',
                          icon: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? colors.primary : null,
                          ),
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _CategoryBadge(category: event.category),
                  const SizedBox(height: 10),
                  _IconLine(
                    icon: Icons.calendar_today_outlined,
                    text: '${event.shortDate} · ${event.timeRange}',
                  ),
                  const SizedBox(height: 4),
                  _IconLine(
                    icon: Icons.location_on_outlined,
                    text: event.location,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill showing the event category.
class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// An icon followed by a single line of muted text.
class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
