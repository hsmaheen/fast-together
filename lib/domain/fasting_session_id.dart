final class FastingSessionId {
  FastingSessionId(String value) : value = _requireValue(value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is FastingSessionId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

String _requireValue(String value) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, 'value', 'must not be empty');
  }

  if (value.contains('/')) {
    throw ArgumentError.value(
      value,
      'value',
      'must not contain a Firestore path separator',
    );
  }

  return value;
}
