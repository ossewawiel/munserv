import 'package:flutter/material.dart';
import 'package:munserv_mobile/shared/widgets/photo_thumbnail_carousel.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../fixtures.dart';

@widgetbook.UseCase(name: 'Default', type: PhotoThumbnailCarousel)
Widget photoThumbnailCarousel(BuildContext context) {
  final thumbnailHeight = context.knobs.double.slider(
    label: 'Thumbnail height',
    initialValue: 120,
    min: 48,
    max: 160,
  );

  return PhotoThumbnailCarousel(
    photoUrls: Fixtures.photoUrls,
    thumbnailHeight: thumbnailHeight,
    onPhotoTap: (_) {},
  );
}
