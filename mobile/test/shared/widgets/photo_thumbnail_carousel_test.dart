import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:munserv_mobile/shared/widgets/photo_thumbnail_carousel.dart';

void main() {
  group('PhotoThumbnailCarousel', () {
    testWidgets('renders nothing when photoUrls is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhotoThumbnailCarousel(photoUrls: []),
          ),
        ),
      );

      // Should render SizedBox.shrink()
      expect(find.byType(SizedBox), findsOneWidget);
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(0.0));
      expect(sizedBox.height, equals(0.0));
    });

    testWidgets('renders horizontal ListView for photos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoThumbnailCarousel(
              photoUrls: [
                'https://example.com/1.jpg',
                'https://example.com/2.jpg',
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, equals(Axis.horizontal));
    });

    testWidgets('renders correct number of thumbnails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoThumbnailCarousel(
              photoUrls: [
                'https://example.com/1.jpg',
                'https://example.com/2.jpg',
                'https://example.com/3.jpg',
              ],
            ),
          ),
        ),
      );

      // Should have 3 GestureDetector widgets (one per thumbnail)
      expect(find.byType(GestureDetector), findsNWidgets(3));
    });

    testWidgets('calls onPhotoTap with correct index when tapped',
        (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoThumbnailCarousel(
              photoUrls: [
                'https://example.com/1.jpg',
                'https://example.com/2.jpg',
              ],
              onPhotoTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      // Tap the first photo
      await tester.tap(find.byType(GestureDetector).first);
      expect(tappedIndex, equals(0));

      // Tap the second photo
      await tester.tap(find.byType(GestureDetector).at(1));
      expect(tappedIndex, equals(1));
    });

    testWidgets('uses default thumbnail height of ThumbnailSizes.xl',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoThumbnailCarousel(
              photoUrls: ['https://example.com/1.jpg'],
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, equals(120.0)); // ThumbnailSizes.xl
    });

    testWidgets('uses custom thumbnail height when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoThumbnailCarousel(
              photoUrls: ['https://example.com/1.jpg'],
              thumbnailHeight: 100.0,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, equals(100.0));
    });

    testWidgets('renders square thumbnails with 1:1 aspect ratio',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoThumbnailCarousel(
              photoUrls: ['https://example.com/1.jpg'],
            ),
          ),
        ),
      );

      expect(find.byType(AspectRatio), findsOneWidget);
      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, equals(1.0));
    });

    testWidgets('applies ClipRRect for rounded corners', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoThumbnailCarousel(
              photoUrls: ['https://example.com/1.jpg'],
            ),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });
}
