import 'package:fasting_app/domain/fasting_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FastingSession', () {
    test('is active until an actual end time is set', () {
      final session = FastingSession(
        startTime: DateTime.utc(2026, 6, 20, 8),
        targetEndTime: DateTime.utc(2026, 6, 21),
      );

      expect(session.isActive, isTrue);
    });
  });
}
