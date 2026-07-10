import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fasting_app/data/firebase_emulator/firebase_emulator_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'an Auth Emulator App Account can read its owner-scoped Firestore document',
    (tester) async {
      final appAccountSessions = await initializeFirebaseEmulatorApp();
      final session = await appAccountSessions.signInOrCreateForLocalEmulator();

      expect(session.accountId.value, isNotEmpty);

      final appAccountDocument = await FirebaseFirestore.instance
          .collection('appAccounts')
          .doc(session.accountId.value)
          .get(const GetOptions(source: Source.server));

      expect(appAccountDocument.id, session.accountId.value);
    },
  );
}
