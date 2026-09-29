import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Network request works', () async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('https://example.com'));
    final response = await request.close();
    expect(response.statusCode, 200);
  });
}
