class RollRecord {
  final DateTime time;
  final List<int> rolls;
  final int modifier;
  final int total;
  final int sides;
  final int? target;
  final bool targetEnabled;

  RollRecord({
    required this.time,
    required this.rolls,
    required this.modifier,
    required this.total,
    required this.sides,
    this.target,
    this.targetEnabled = false,
  });
}
