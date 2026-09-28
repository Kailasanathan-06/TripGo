import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripgo/app.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('app boots and shows splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TripGoApp()));
    await tester.pump();
    expect(find.text('TRIPGO'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('TRIPGO'), findsOneWidget);
  });

  testWidgets('splash keeps working while the embedded server boots', (tester) async {
    // The embedded server is the only backend, so a slow or failing boot has to
    // leave the screen usable rather than take it down.
    await tester.pumpWidget(const ProviderScope(child: TripGoApp()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('TRIPGO'), findsOneWidget);
    expect(find.textContaining('Starting up'), findsOneWidget);
  });
}
