class FastingSession {
  const FastingSession({
    required this.startTime,
    required this.targetEndTime,
    this.actualEndTime,
  });

  final DateTime startTime;
  final DateTime targetEndTime;
  final DateTime? actualEndTime;

  bool get isActive => actualEndTime == null;
}
