import 'package:flutter/material.dart';

/// Renders an event image from a URL, with a graceful placeholder.
///
/// Event images are plain URLs rather than uploaded files, so this widget is
/// the single place that knows how an image is loaded. Swapping to Firebase
/// Storage later only needs to change this file.
class EventImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final BorderRadius? borderRadius;

  const EventImage({
    super.key,
    required this.imageUrl,
    this.height = 160,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      height: height,
      width: double.infinity,
      child: imageUrl.trim().isEmpty
          ? _placeholder(context)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, _, _) => _placeholder(context),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _placeholder(context, showSpinner: true);
              },
            ),
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  /// Shown when there is no URL, while loading, or if the URL fails to load.
  Widget _placeholder(BuildContext context, {bool showSpinner = false}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: showSpinner
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.event_outlined,
              size: 40,
              color: colors.onSurfaceVariant,
            ),
    );
  }
}
