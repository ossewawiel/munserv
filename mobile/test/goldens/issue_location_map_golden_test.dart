import 'package:flutter_test/flutter_test.dart';

void main() {
  // IssueLocationMap (`lib/shared/widgets/issue_location_map.dart`) embeds a
  // live FlutterMap that fetches OpenStreetMap tiles over the network
  // (`https://tile.openstreetmap.org/...`) via `flutter_map`'s own network
  // tile provider, not `Image.network` — `network_image_mock` cannot
  // intercept it. Tiles arrive asynchronously and their placement/anti-alias
  // output is not guaranteed pixel-identical across runs or machines even
  // if the request were mocked. Per the story's "do not change a widget to
  // make a golden stable" rule, this row is skipped rather than reworking
  // the widget's tile provider; DS4b tracks a proper fix (an injectable
  // offline tile provider) if a golden is needed later.
  test(
    'IssueLocationMap golden skipped: live network map tiles are not deterministic',
    () {},
    skip: 'See comment above: flutter_map fetches real OSM tiles.',
  );
}
