import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../shared/theme/typography.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_spinner.dart';
import '../../providers/issue_providers.dart';

/// Fullscreen photo gallery with swipe navigation and pinch-to-zoom.
class PhotoGalleryPage extends ConsumerStatefulWidget {
  final String issueId;
  final int initialIndex;

  const PhotoGalleryPage({
    super.key,
    required this.issueId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends ConsumerState<PhotoGalleryPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issueAsync = ref.watch(issueDetailProvider(widget.issueId));
    final colors = Theme.of(context).colorScheme;

    return BrandedScaffold(
      showMapBackground: false,
      appBar: AppBar(
        title:
            issueAsync
                .whenData(
                  (issue) =>
                      Text('${_currentIndex + 1} of ${issue.photoUrls.length}'),
                )
                .value ??
            const Text('Photos'),
      ),
      body: issueAsync.when(
        data: (issue) {
          if (issue.photoUrls.isEmpty) {
            return Center(
              child: Text(
                'No photos available',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: issue.photoUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(issue.photoUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: IconSizes.display,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        'Failed to load image',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event?.expectedTotalBytes != null
                    ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                    : null,
              ),
            ),
            backgroundDecoration: BoxDecoration(color: colors.surface),
          );
        },
        loading: () => const LoadingSpinner(),
        error: (error, _) => ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(issueDetailProvider(widget.issueId)),
        ),
      ),
    );
  }
}
