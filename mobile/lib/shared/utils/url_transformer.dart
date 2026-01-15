/// Transforms URLs from backend format to mobile-accessible format.
///
/// The backend may return URLs with `localhost` or `127.0.0.1` which
/// won't work on mobile devices. This utility rewrites those URLs
/// to use the configured API host.
class UrlTransformer {
  final String _apiHost;
  final String _apiPort;

  UrlTransformer({
    required String apiHost,
    required String apiPort,
  })  : _apiHost = apiHost,
        _apiPort = apiPort;

  /// Transform a single URL from localhost to the API host.
  ///
  /// Examples:
  /// - `http://localhost:8080/uploads/photo.jpg` → `http://192.168.1.100:8080/uploads/photo.jpg`
  /// - `http://127.0.0.1:8080/uploads/photo.jpg` → `http://192.168.1.100:8080/uploads/photo.jpg`
  /// - Already correct URL → unchanged
  String transform(String url) {
    if (url.isEmpty) return url;

    // Patterns to replace
    final localhostPatterns = [
      RegExp(r'http://localhost:\d+'),
      RegExp(r'http://127\.0\.0\.1:\d+'),
      RegExp(r'https://localhost:\d+'),
      RegExp(r'https://127\.0\.0\.1:\d+'),
    ];

    final targetHost = 'http://$_apiHost:$_apiPort';

    for (final pattern in localhostPatterns) {
      if (pattern.hasMatch(url)) {
        return url.replaceFirst(pattern, targetHost);
      }
    }

    return url;
  }

  /// Transform a list of URLs.
  List<String> transformList(List<String> urls) {
    return urls.map(transform).toList();
  }
}
