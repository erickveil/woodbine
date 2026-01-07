class RollRecord {
  final DateTime time;
  final List<int> rolls;
  final int modifier;
  final int total;
  final int sides;
  final int? target;
  final bool targetEnabled;
  final int? explodeValue;
  final bool explodeEnabled;
  final int originalDiceCount; // Number of dice originally rolled (before explosions)

  RollRecord({
    required this.time,
    required this.rolls,
    required this.modifier,
    required this.total,
    required this.sides,
    this.target,
    this.targetEnabled = false,
    this.explodeValue,
    this.explodeEnabled = false,
    int? originalDiceCount,
  }) : originalDiceCount = originalDiceCount ?? rolls.length;
}
