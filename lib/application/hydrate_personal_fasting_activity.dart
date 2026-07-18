import 'package:fasting_app/application/app_account_session.dart';
import 'package:fasting_app/application/fasting_tracker.dart';
import 'package:fasting_app/application/personal_fasting_activity_repository.dart';

/// Loads the signed-in App Account's Personal Fasting Activity into a new
/// FastingTracker. Callers keep their current tracker until hydration succeeds.
final class HydratePersonalFastingActivity {
  const HydratePersonalFastingActivity(
    this._appAccountSessionProvider,
    this._repository,
  );

  final AppAccountSessionProvider _appAccountSessionProvider;
  final PersonalFastingActivityRepository _repository;

  Future<FastingTracker> hydrate() async {
    final session = await _appAccountSessionProvider.currentSession();
    if (session == null) {
      throw StateError(
        'Cannot hydrate Personal Fasting Activity without an App Account session',
      );
    }

    final snapshot = await _repository.loadSnapshot(session.accountId);
    return FastingTracker.fromSnapshot(snapshot: snapshot);
  }
}
