import 'package:fasting_app/ui/components/privacy_onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('explains private history and future opt-in Circle sharing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PrivacyOnboarding(onAcknowledged: () {})),
      ),
    );

    expect(find.text('Your fasting stays private'), findsOneWidget);
    expect(
      find.textContaining(
        'Personal Fasting Activity, including your history, is private to your App Account.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'only see your current Shared Fasting Activity, not your personal history',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('when that feature is available'),
      findsOneWidget,
    );
  });

  testWidgets('calls onAcknowledged from the privacy acknowledgement action', (
    tester,
  ) async {
    var acknowledgementCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrivacyOnboarding(
            onAcknowledged: () {
              acknowledgementCount += 1;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('I understand'));

    expect(acknowledgementCount, 1);
  });

  testWidgets('groups the privacy overview for assistive technologies', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PrivacyOnboarding(onAcknowledged: () {})),
        ),
      );

      expect(find.bySemanticsLabel('Privacy overview'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('fits without overflow at a compact mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PrivacyOnboarding(onAcknowledged: () {}),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('privacyOnboardingAcknowledgeButton')),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
    } finally {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}
