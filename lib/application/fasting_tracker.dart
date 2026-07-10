import 'dart:math';

import 'package:fasting_app/application/personal_fasting_activity_repository.dart';
import 'package:fasting_app/domain/fasting_plan.dart';
import 'package:fasting_app/domain/fasting_session.dart';
import 'package:fasting_app/domain/fasting_session_id.dart';

enum FastingStatus { fasting, notFasting }

class DailyFastingTotal {
  const DailyFastingTotal({required this.date, required this.duration});

  final DateTime date;
  final Duration duration;

  @override
  bool operator ==(Object other) {
    return other is DailyFastingTotal &&
        other.date == date &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(date, duration);
}

class FastingTracker {
  FastingTracker({
    DateTime Function()? nowUtc,
    FastingSessionId Function()? newSessionId,
  }) : _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
       _newSessionId = newSessionId ?? _randomFastingSessionId,
       _recentEndedSessions = [];

  FastingTracker.fromSnapshot({
    required PersonalFastingActivitySnapshot snapshot,
    DateTime Function()? nowUtc,
    FastingSessionId Function()? newSessionId,
  }) : _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
       _newSessionId = newSessionId ?? _randomFastingSessionId,
       _activeSession = snapshot.activeSession,
       _recentEndedSessions = List.of(snapshot.endedSessions);

  final DateTime Function() _nowUtc;
  final FastingSessionId Function() _newSessionId;
  FastingSession? _activeSession;
  final List<FastingSession> _recentEndedSessions;

  FastingSession? get latestSession => _activeSession ?? _latestEndedSession;

  List<FastingSession> get recentEndedSessions =>
      List.unmodifiable(_recentEndedSessions);

  FastingSession? get activeSession => _activeSession;

  List<DailyFastingTotal> dailyFastingTotals({
    DateTime Function(DateTime time)? localTimeFor,
  }) {
    final toLocalTime = localTimeFor ?? (DateTime time) => time.toLocal();
    final durationsByDate = <DateTime, Duration>{};

    for (final session in _recentEndedSessions) {
      final duration = session.actualDuration;
      final actualEndTime = session.actualEndTime;
      if (duration == null || actualEndTime == null) {
        continue;
      }

      final localEndTime = toLocalTime(actualEndTime);
      final localDate = DateTime(
        localEndTime.year,
        localEndTime.month,
        localEndTime.day,
      );
      durationsByDate[localDate] =
          (durationsByDate[localDate] ?? Duration.zero) + duration;
    }

    return [
      for (final entry in durationsByDate.entries)
        DailyFastingTotal(date: entry.key, duration: entry.value),
    ];
  }

  FastingStatus get status {
    if (activeSession != null) {
      return FastingStatus.fasting;
    }

    return FastingStatus.notFasting;
  }

  void start({required DateTime startTime, required FastingPlan plan}) {
    if (status == FastingStatus.fasting) {
      throw StateError('Cannot start while already Fasting');
    }

    _requireNotFuture(startTime, 'startTime', _nowUtc());
    final id = _newSessionId();
    if (_recentEndedSessions.any((session) => session.id == id)) {
      throw StateError('Cannot start with a reused Fasting Session ID');
    }
    _activeSession = FastingSession.start(
      id: id,
      startTime: startTime,
      plan: plan,
    );
  }

  void end({required DateTime actualEndTime}) {
    final session = _activeSession;
    if (session == null || !session.isActive) {
      throw StateError('Cannot end while Not Fasting');
    }

    _requireNotFuture(actualEndTime, 'actualEndTime', _nowUtc());
    _activeSession = null;
    _recentEndedSessions.add(session.end(actualEndTime: actualEndTime));
    _orderEndedSessions();
  }

  void correctActualEndTime({required DateTime actualEndTime}) {
    final session = _latestEndedSession;
    if (session == null) {
      throw StateError(
        'Cannot correct actualEndTime without a Fasting Session',
      );
    }

    _requireNotFuture(actualEndTime, 'actualEndTime', _nowUtc());
    _recentEndedSessions[0] = session.correctActualEndTime(
      actualEndTime: actualEndTime,
    );
    _orderEndedSessions();
  }

  void deleteLatestEndedSession() {
    if (_latestEndedSession == null) {
      throw StateError('Cannot delete without an ended Fasting Session');
    }

    _recentEndedSessions.removeAt(0);
  }

  void deleteEndedSession(FastingSessionId id) {
    if (_activeSession?.id == id) {
      throw StateError('Cannot delete an active Fasting Session');
    }

    final sessionIndex = _recentEndedSessions.indexWhere(
      (session) => session.id == id,
    );
    if (sessionIndex == -1) {
      throw StateError('Cannot delete a Fasting Session outside history');
    }

    _recentEndedSessions.removeAt(sessionIndex);
  }

  FastingSession? get _latestEndedSession =>
      _recentEndedSessions.isEmpty ? null : _recentEndedSessions.first;

  void _orderEndedSessions() {
    final orderedSessions = PersonalFastingActivitySnapshot(
      endedSessions: _recentEndedSessions,
    ).endedSessions;
    _recentEndedSessions
      ..clear()
      ..addAll(orderedSessions);
  }
}

void _requireNotFuture(DateTime time, String name, DateTime nowUtc) {
  if (!nowUtc.isUtc) {
    throw StateError('Application clock must return a UTC DateTime');
  }

  if (time.isAfter(nowUtc)) {
    throw ArgumentError.value(time, name, 'must not be in the future');
  }
}

FastingSessionId _randomFastingSessionId() {
  final random = Random.secure();
  final value = List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return FastingSessionId(value);
}
