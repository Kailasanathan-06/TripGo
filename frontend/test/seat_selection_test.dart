import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripgo/shared/widgets/seats.dart';

void main() {
  group('BerthLabelInfo parsing', () {
    test('parses Lower berth with suffix L', () {
      final info = BerthLabelInfo.parse('1L');
      expect(info.number, '1');
      expect(info.typeCode, 'LB');
      expect(info.typeName, 'Lower');
    });

    test('parses Upper berth with suffix U', () {
      final info = BerthLabelInfo.parse('2U');
      expect(info.number, '2');
      expect(info.typeCode, 'UB');
      expect(info.typeName, 'Upper');
    });

    test('parses Lower Berth with LB', () {
      final info = BerthLabelInfo.parse('3LB');
      expect(info.number, '3');
      expect(info.typeCode, 'LB');
      expect(info.typeName, 'Lower');
    });

    test('parses Middle Berth with MB', () {
      final info = BerthLabelInfo.parse('4MB');
      expect(info.number, '4');
      expect(info.typeCode, 'MB');
      expect(info.typeName, 'Middle');
    });

    test('parses Side Upper with SU', () {
      final info = BerthLabelInfo.parse('6SU');
      expect(info.number, '6');
      expect(info.typeCode, 'SU');
      expect(info.typeName, 'Side Upper');
    });

    test('parses Side Lower with SL', () {
      final info = BerthLabelInfo.parse('7SL');
      expect(info.number, '7');
      expect(info.typeCode, 'SL');
      expect(info.typeName, 'Side Lower');
    });

    test('parses numeric only berth label', () {
      final info = BerthLabelInfo.parse('24');
      expect(info.number, '24');
      expect(info.typeCode, '');
      expect(info.typeName, 'Berth');
    });
  });

  group('seatStateFromStatus', () {
    test('identifies available and booked seats', () {
      expect(seatStateFromStatus('AVAILABLE'), SeatState.available);
      expect(seatStateFromStatus('BOOKED'), SeatState.booked);
      expect(seatStateFromStatus('HELD'), SeatState.held);
      expect(seatStateFromStatus('UNAVAILABLE'), SeatState.unavailable);
    });

    test('identifies ladies booked seats', () {
      expect(seatStateFromStatus('BOOKED', gender: 'F'), SeatState.ladies);
      expect(seatStateFromStatus('BOOKED', gender: 'Female'), SeatState.ladies);
      expect(seatStateFromStatus('AVAILABLE', gender: 'F'), SeatState.ladies);
    });
  });

  group('TripGoSeat widget', () {
    testWidgets('renders bus seat with label and handles tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripGoSeat(
              label: '12',
              state: SeatState.available,
              selected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget);
      await tester.tap(find.text('12'));
      expect(tapped, isTrue);
    });

    testWidgets('renders sleeper bus berth with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripGoSeat(
              label: 'U4',
              state: SeatState.available,
              selected: true,
              isSleeper: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('U4'), findsOneWidget);
      expect(find.text('SLEEP'), findsOneWidget);
    });
  });

  group('TripGoBerth widget', () {
    testWidgets('renders train berth with both number and type badge', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripGoBerth(
              label: '15MB',
              state: SeatState.available,
              selected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Must display both number '15' and type badge 'MB'
      expect(find.text('15'), findsOneWidget);
      expect(find.text('MB'), findsOneWidget);

      await tester.tap(find.text('15'));
      expect(tapped, isTrue);
    });
  });
}
