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
  final int
      originalDiceCount; // Number of dice originally rolled (before explosions)
  final String? title; // Optional user-defined title for this roll

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
    this.title,
  }) : originalDiceCount = originalDiceCount ?? rolls.length;

  // Create a copy with updated title
  RollRecord copyWith({String? title}) {
    return RollRecord(
      time: time,
      rolls: rolls,
      modifier: modifier,
      total: total,
      sides: sides,
      target: target,
      targetEnabled: targetEnabled,
      explodeValue: explodeValue,
      explodeEnabled: explodeEnabled,
      originalDiceCount: originalDiceCount,
      title: title,
    );
  }
}
