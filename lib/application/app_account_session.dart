import 'package:fasting_app/application/personal_fasting_activity_repository.dart';

/// The authenticated App Account identity available to application code.
final class AppAccountSession {
  const AppAccountSession(this.accountId);

  final AppAccountId accountId;
}

abstract interface class AppAccountSessionProvider {
  Future<AppAccountSession?> currentSession();

  Future<AppAccountSession> signInOrCreateForLocalEmulator();
}
