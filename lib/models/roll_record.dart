class RollRecord {
  final DateTime time;
  final List<int> rolls;
  final int modifier;
  final int total;
  final int sides;

  RollRecord({
    required this.time,
    required this.rolls,
    required this.modifier,
    required this.total,
    required this.sides,
  });
}
