import 'package:flutter/material.dart';

import '../theme/typography.dart';

/// Horizontal scrolling carousel of photo thumbnails.
/// Each thumbnail is tappable to open fullscreen gallery.
///
/// Usage:
/// ```dart
/// PhotoThumbnailCarousel(
///   photoUrls: issue.photoUrls,
///   onPhotoTap: (index) => context.push(
///     '/issues/${issue.id}/photos?index=$index',
///   ),
/// )
/// ```
class PhotoThumbnailCarousel extends StatelessWidget {
  /// List of photo URLs to display.
  final List<String> photoUrls;

  /// Called when a photo is tapped. Receives the index of the tapped photo.
  final void Function(int index)? onPhotoTap;

  /// Height of the thumbnails. Defaults to ThumbnailSizes.xl (120).
  final double thumbnailHeight;

  const PhotoThumbnailCarousel({
    super.key,
    required this.photoUrls,
    this.onPhotoTap,
    this.thumbnailHeight = ThumbnailSizes.xl,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: thumbnailHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        itemCount: photoUrls.length,
        itemBuilder: (context, index) {
          final isLast = index == photoUrls.length - 1;

          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : Spacing.sm),
            child: GestureDetector(
              onTap: () => onPhotoTap?.call(index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: AspectRatio(
                  aspectRatio: 1, // Square thumbnails
                  child: Image.network(
                    photoUrls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: colors.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colors.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        color: colors.onSurfaceVariant,
                        size: IconSizes.lg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
