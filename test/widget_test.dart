import 'package:fasting_app/main.dart';
import 'package:fasting_app/ui/components/local_fasting_status_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows local Fasting Status on app launch', (tester) async {
    await tester.pumpWidget(const FastingApp());

    expect(find.text('Fasting App'), findsOneWidget);
    expect(find.byType(LocalFastingStatusSection), findsOneWidget);
    expect(find.text('Not Fasting'), findsOneWidget);
    expect(find.text('Start 16h Fasting Session'), findsOneWidget);

    expect(find.text('Flutter Demo Home Page'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
