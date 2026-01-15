import 'package:flutter_test/flutter_test.dart';
import 'package:munserv_mobile/shared/utils/url_transformer.dart';

void main() {
  group('UrlTransformer', () {
    late UrlTransformer transformer;

    setUp(() {
      transformer = UrlTransformer(apiHost: '192.168.1.100', apiPort: '8080');
    });

    group('transform', () {
      test('transforms localhost URL to API host', () {
        const input = 'http://localhost:8080/uploads/photo.jpg';
        const expected = 'http://192.168.1.100:8080/uploads/photo.jpg';

        expect(transformer.transform(input), equals(expected));
      });

      test('transforms localhost URL with different port', () {
        const input = 'http://localhost:3000/uploads/photo.jpg';
        const expected = 'http://192.168.1.100:8080/uploads/photo.jpg';

        expect(transformer.transform(input), equals(expected));
      });

      test('transforms 127.0.0.1 URL to API host', () {
        const input = 'http://127.0.0.1:8080/uploads/photo.jpg';
        const expected = 'http://192.168.1.100:8080/uploads/photo.jpg';

        expect(transformer.transform(input), equals(expected));
      });

      test('transforms https localhost URL', () {
        const input = 'https://localhost:8080/uploads/photo.jpg';
        const expected = 'http://192.168.1.100:8080/uploads/photo.jpg';

        expect(transformer.transform(input), equals(expected));
      });

      test('leaves non-localhost URL unchanged', () {
        const input = 'http://example.com:8080/uploads/photo.jpg';

        expect(transformer.transform(input), equals(input));
      });

      test('leaves already correct URL unchanged', () {
        const input = 'http://192.168.1.100:8080/uploads/photo.jpg';

        expect(transformer.transform(input), equals(input));
      });

      test('handles empty string', () {
        expect(transformer.transform(''), equals(''));
      });

      test('preserves path and query parameters', () {
        const input = 'http://localhost:8080/uploads/photo.jpg?size=large';
        const expected =
            'http://192.168.1.100:8080/uploads/photo.jpg?size=large';

        expect(transformer.transform(input), equals(expected));
      });
    });

    group('transformList', () {
      test('transforms all URLs in list', () {
        final input = [
          'http://localhost:8080/uploads/1.jpg',
          'http://localhost:8080/uploads/2.jpg',
          'http://example.com/uploads/3.jpg',
        ];

        final expected = [
          'http://192.168.1.100:8080/uploads/1.jpg',
          'http://192.168.1.100:8080/uploads/2.jpg',
          'http://example.com/uploads/3.jpg',
        ];

        expect(transformer.transformList(input), equals(expected));
      });

      test('handles empty list', () {
        expect(transformer.transformList([]), equals([]));
      });
    });
  });
}
