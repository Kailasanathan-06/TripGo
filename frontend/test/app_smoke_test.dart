import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripgo/app.dart';
import 'package:tripgo/core/network/server_override.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots and shows splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TripGoApp()));
    await tester.pump();
    expect(find.text('TRIPGO'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('TRIPGO'), findsOneWidget);
  });

  testWidgets('splash survives a preference store that cannot be read', (tester) async {
    // Reading preferences is the first thing boot does. If that throws it must not
    // take the screen down, because the embedded server is a working default.
    await tester.pumpWidget(const ProviderScope(child: TripGoApp()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('TRIPGO'), findsOneWidget);
  });

  test('stored address is normalised to host and port', () async {
    await ServerOverride.save('192.168.1.5');
    expect(ServerOverride.hostPort, '192.168.1.5:8000');
    expect(ServerOverride.baseUrl, 'http://192.168.1.5:8000/api/');

    await ServerOverride.save(' 192.168.1.5:9000 ');
    expect(ServerOverride.hostPort, '192.168.1.5:9000');

    await ServerOverride.save('http://10.0.0.7:8000/api/');
    expect(ServerOverride.hostPort, '10.0.0.7:8000');
  });

  test('an unusable address is rejected rather than silently ignored', () async {
    // A mistyped address that was accepted would look like a network fault.
    for (final bad in ['', '   ', 'host:notaport', 'host:0', 'host:70000']) {
      expect(
        () => ServerOverride.normaliseForPreview(bad),
        throwsA(isA<FormatException>()),
        reason: 'expected "$bad" to be rejected',
      );
    }
  });

  test('an empty address clears the override', () async {
    await ServerOverride.save('192.168.1.5:8000');
    expect(ServerOverride.isActive, isTrue);

    await ServerOverride.save(null);
    expect(ServerOverride.isActive, isFalse);
    expect(ServerOverride.baseUrl, isNull);
  });
}
