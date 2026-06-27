import 'package:fasting_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('local fasting flow', () {
    testWidgets(
      'records multiple recent Personal Fasting Activity entries and deletes specific ended sessions',
      (tester) async {
        var now = DateTime.utc(2026, 6, 21, 8);

        await tester.pumpWidget(FastingApp(nowUtc: () => now));
        await tester.pumpAndSettle();

        expect(find.text('Not Fasting'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('personalFastingActivityEmptyState')),
          findsOneWidget,
        );

        await _tapByKey(tester, const ValueKey('startFastingSessionButton'));
        expect(
          find.byKey(const ValueKey('activeFastingStatus')),
          findsOneWidget,
        );
        expect(find.text('Fasting'), findsOneWidget);

        now = DateTime.utc(2026, 6, 22, 1);
        await _tapByKey(tester, const ValueKey('endFastingSessionButton'));

        expect(find.text('Not Fasting'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_0')),
          findsOneWidget,
        );
        expect(find.text('Completed'), findsOneWidget);

        await _tapByKey(tester, const ValueKey('startFastingSessionButton'));
        expect(
          find.byKey(const ValueKey('activeFastingStatus')),
          findsOneWidget,
        );

        now = DateTime.utc(2026, 6, 22, 11);
        await _tapByKey(tester, const ValueKey('endFastingSessionButton'));

        expect(find.text('Not Fasting'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('personalFastingActivityList')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_1')),
          findsOneWidget,
        );
        expect(find.text('Ended Early'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);

        await _tapByKey(
          tester,
          ValueKey('delete-${DateTime.utc(2026, 6, 22, 1)}'),
        );

        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_1')),
          findsNothing,
        );
        expect(find.text('Ended Early'), findsOneWidget);
        expect(find.text('Completed'), findsNothing);

        await _tapByKey(tester, const ValueKey('latestDeleteButton'));

        expect(
          find.byKey(const ValueKey('personalFastingActivityEmptyState')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('recentFastingSessionItem_0')),
          findsNothing,
        );
        expect(find.text('Ended Early'), findsNothing);
      },
    );

    testWidgets('validates and starts a custom Fasting Plan', (tester) async {
      final now = DateTime.utc(2026, 6, 21, 8);

      await tester.pumpWidget(FastingApp(nowUtc: () => now));
      await tester.pumpAndSettle();

      await _tapByKey(tester, const ValueKey('fastingPlanCustomChip'));

      await tester.enterText(
        find.byKey(const ValueKey('customPlanHoursField')),
        '169',
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter 1-168 hours'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('customPlanHoursField')),
        '36',
      );
      await tester.pumpAndSettle();

      expect(find.text('Start 36h Fasting Session'), findsOneWidget);

      await _tapByKey(tester, const ValueKey('startFastingSessionButton'));

      expect(find.byKey(const ValueKey('activeFastingStatus')), findsOneWidget);
      expect(find.text('36h 0m'), findsOneWidget);
    });

    testWidgets('starts a Fasting Session from a corrected start time', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 6, 21, 8);
      final correctedStartTime = DateTime.utc(2026, 6, 21, 4);

      await tester.pumpWidget(
        FastingApp(
          nowUtc: () => now,
          selectStartTime: (_, _) async => correctedStartTime,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await _tapByKey(tester, const ValueKey('startFastingSessionButton'));

      expect(find.byKey(const ValueKey('activeFastingStatus')), findsOneWidget);
      expect(find.text('Fasting'), findsOneWidget);
      expect(find.text('Elapsed'), findsOneWidget);
      expect(find.text('4h 0m'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('12h 0m'), findsOneWidget);
    });
  });
}

Future<void> _tapByKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
