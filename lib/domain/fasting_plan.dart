class FastingPlan {
  const FastingPlan._(this.duration);

  static const tenHours = FastingPlan._(Duration(hours: 10));
  static const twelveHours = FastingPlan._(Duration(hours: 12));
  static const fourteenHours = FastingPlan._(Duration(hours: 14));
  static const sixteenHours = FastingPlan._(Duration(hours: 16));
  static const eighteenHours = FastingPlan._(Duration(hours: 18));
  static const twentyFourHours = FastingPlan._(Duration(hours: 24));
  static const fortyEightHours = FastingPlan._(Duration(hours: 48));

  factory FastingPlan.customHours(int hours) {
    if (hours < 1) {
      throw ArgumentError.value(hours, 'hours', 'must be at least 1');
    }

    if (hours > 168) {
      throw ArgumentError.value(hours, 'hours', 'must be at most 168');
    }

    return FastingPlan._(Duration(hours: hours));
  }

  final Duration duration;

  DateTime targetEndTimeFrom(DateTime startTime) => startTime.add(duration);
}
