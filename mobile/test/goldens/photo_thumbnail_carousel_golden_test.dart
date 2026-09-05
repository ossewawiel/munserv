import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/widgets/photo_thumbnail_carousel.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'fixtures.dart';
import 'golden_test_helper.dart';

void main() {
  setUpAll(goldenTestSetUp);

  group('PhotoThumbnailCarousel', () {
    testWidgets('light', (tester) async {
      await mockNetworkImagesFor(() async {
        await pumpGolden(
          tester,
          PhotoThumbnailCarousel(
            photoUrls: Fixtures.photoUrls,
            onPhotoTap: (_) {},
          ),
          size: const Size(390, 140),
        );

        await expectLater(
          find.byType(PhotoThumbnailCarousel),
          matchesGoldenFile(
            'goldens/photo_thumbnail_carousel_default_light.png',
          ),
        );
      });
    });

    testWidgets('dark', (tester) async {
      await mockNetworkImagesFor(() async {
        await pumpGolden(
          tester,
          PhotoThumbnailCarousel(
            photoUrls: Fixtures.photoUrls,
            onPhotoTap: (_) {},
          ),
          dark: true,
          size: const Size(390, 140),
        );

        await expectLater(
          find.byType(PhotoThumbnailCarousel),
          matchesGoldenFile(
            'goldens/photo_thumbnail_carousel_default_dark.png',
          ),
        );
      });
    });
  });
}
