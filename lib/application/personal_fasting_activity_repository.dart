import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';

final class AppAccountId {
  AppAccountId(String value) : value = _requireNonEmpty(value, 'value');

  final String value;

  @override
  bool operator ==(Object other) =>
      other is AppAccountId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

abstract interface class PersonalFastingActivityRepository {
  /// Loads the App Account's current Personal Fasting Activity snapshot.
  Future<PersonalFastingActivitySnapshot> loadSnapshot(AppAccountId accountId);

  /// Atomically applies [PersonalFastingActivitySnapshot.upsert] for the App
  /// Account and returns the resulting snapshot. Repeating the same write has
  /// the same effect as writing it once. It throws [StateError] when an active
  /// Fasting Session has a different ID from the existing active session.
  Future<PersonalFastingActivitySnapshot> upsert(
    AppAccountId accountId,
    FastingSession session,
  );

  /// Atomically applies [PersonalFastingActivitySnapshot.deleteEndedSession]
  /// and returns the resulting snapshot. It throws [StateError] when [id]
  /// identifies the active session or no ended Fasting Session.
  Future<PersonalFastingActivitySnapshot> deleteEndedSession(
    AppAccountId accountId,
    FastingSessionId id,
  );
}

/// A Personal Fasting Activity view with at most one active Fasting Session.
/// Ended Fasting Sessions are ordered by actual end time descending, then ID.
class PersonalFastingActivitySnapshot {
  PersonalFastingActivitySnapshot({
    this.activeSession,
    List<FastingSession> endedSessions = const [],
  }) {
    if (activeSession case final session? when !session.isActive) {
      throw ArgumentError.value(
        activeSession,
        'activeSession',
        'must be active',
      );
    }

    if (endedSessions.any((session) => session.isActive)) {
      throw ArgumentError.value(
        endedSessions,
        'endedSessions',
        'must contain only ended Fasting Sessions',
      );
    }

    final ids = <Object>{
      if (activeSession != null) activeSession!.id,
      ...endedSessions.map((session) => session.id),
    };
    if (ids.length != endedSessions.length + (activeSession == null ? 0 : 1)) {
      throw ArgumentError.value(
        endedSessions,
        'endedSessions',
        'must not duplicate a Fasting Session ID',
      );
    }

    this.endedSessions = List.unmodifiable(
      _orderedEndedSessions(endedSessions),
    );
  }

  final FastingSession? activeSession;
  late final List<FastingSession> endedSessions;

  PersonalFastingActivitySnapshot upsert(FastingSession session) {
    final currentActiveSession = activeSession;
    if (session.isActive) {
      if (currentActiveSession != null &&
          currentActiveSession.id != session.id) {
        throw StateError('Cannot upsert a second active Fasting Session');
      }

      return PersonalFastingActivitySnapshot(
        activeSession: session,
        endedSessions: endedSessions,
      );
    }

    return PersonalFastingActivitySnapshot(
      activeSession: currentActiveSession?.id == session.id
          ? null
          : currentActiveSession,
      endedSessions: [
        session,
        ...endedSessions.where((existing) => existing.id != session.id),
      ],
    );
  }

  PersonalFastingActivitySnapshot deleteEndedSession(FastingSessionId id) {
    if (activeSession?.id == id) {
      throw StateError('Cannot delete an active Fasting Session');
    }

    if (!endedSessions.any((session) => session.id == id)) {
      throw StateError('Cannot delete a missing ended Fasting Session');
    }

    return PersonalFastingActivitySnapshot(
      activeSession: activeSession,
      endedSessions: endedSessions
          .where((session) => session.id != id)
          .toList(),
    );
  }
}

List<FastingSession> _orderedEndedSessions(List<FastingSession> endedSessions) {
  final orderedSessions = List<FastingSession>.of(endedSessions);
  orderedSessions.sort((left, right) {
    final actualEndOrder = right.actualEndTime!.compareTo(left.actualEndTime!);
    if (actualEndOrder != 0) {
      return actualEndOrder;
    }

    return left.id.value.compareTo(right.id.value);
  });
  return orderedSessions;
}

String _requireNonEmpty(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }

  return value;
}
