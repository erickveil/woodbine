import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/roll_record.dart';
import '../widgets/big_number_display.dart';
import '../widgets/dice_controls.dart';
import '../widgets/roll_history_list.dart';

class DiceRollerPage extends StatefulWidget {
  const DiceRollerPage({super.key});

  @override
  State<DiceRollerPage> createState() => _DiceRollerPageState();
}

class _DiceRollerPageState extends State<DiceRollerPage> {
  final Random _rng = Random();

  int _diceCount = 1;
  int _sides = 6;
  int _modifier = 0;

  int? _displayedNumber;
  bool _isRolling = false;

  // History of rolls
  final List<RollRecord> _history = [];

  // Controls for input limits
  final int _minDice = 1;
  final int _maxDice = 100;
  final int _minSides = 2;
  final int _maxSides = 1000; // arbitrary practical limit
  final int _minModifier = -10000;
  final int _maxModifier = 10000;

  // UI state
  bool _showBreakdown = true;

  // maximum history entries to keep
  final int _maxHistory = 200;

  @override
  void initState() {
    super.initState();
    _displayedNumber = _diceCount + _modifier;
  }

  Future<void> _rollDice() async {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
    });

    final int minValue = _diceCount * 1 + _modifier;
    final int maxValue = _diceCount * _sides + _modifier;

    // Simulate actual dice rolls to compute the final result and keep breakdown
    List<int> rolls = List.generate(_diceCount, (_) => _rng.nextInt(_sides) + 1);
    int finalResult = rolls.fold(0, (p, e) => p + e) + _modifier;

    // Animation: cycle through random numbers in [minValue, maxValue],
    // starting fast and slowing down.
    const int frames = 20;
    const int firstDelayMs = 25;
    const int lastDelayMs = 180;

    for (int i = 0; i < frames; i++) {
      // interpolate delay
      final double t = i / (frames - 1);
      final int delayMs = (firstDelayMs * (1 - t) + lastDelayMs * t).round();

      // pick a pseudo-random intermediate number
      final int intermediate = _rng.nextInt(maxValue - minValue + 1) + minValue;
      setState(() => _displayedNumber = intermediate);

      await Future.delayed(Duration(milliseconds: delayMs));
    }

    // Finally show the actual result and store breakdown in history
    final record = RollRecord(
      time: DateTime.now().toUtc(),
      rolls: rolls,
      modifier: _modifier,
      total: finalResult,
      sides: _sides,
    );

    setState(() {
      _displayedNumber = finalResult;
      _history.insert(0, record); // newest first
      if (_history.length > _maxHistory) {
        _history.removeRange(_maxHistory, _history.length);
      }
    });

    // brief glow: wait a bit so user sees final number
    await Future.delayed(const Duration(milliseconds: 450));

    setState(() => _isRolling = false);
  }

  // Re-roll based on a history record's configuration (does not alter current inputs).
  Future<void> _rerollFromRecord(RollRecord record) async {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
    });

    final int count = record.rolls.length;
    final int sides = record.sides;
    final int modifier = record.modifier;

    final int minValue = count * 1 + modifier;
    final int maxValue = count * sides + modifier;

    // perform new rolls (but do not change UI inputs)
    List<int> rolls = List.generate(count, (_) => _rng.nextInt(sides) + 1);
    int finalResult = rolls.fold(0, (p, e) => p + e) + modifier;

    // Animation similar to _rollDice but using the record's configuration
    const int frames = 20;
    const int firstDelayMs = 25;
    const int lastDelayMs = 180;

    for (int i = 0; i < frames; i++) {
      final double t = i / (frames - 1);
      final int delayMs = (firstDelayMs * (1 - t) + lastDelayMs * t).round();
      final int intermediate = _rng.nextInt(maxValue - minValue + 1) + minValue;
      setState(() => _displayedNumber = intermediate);
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    final newRecord = RollRecord(
      time: DateTime.now().toUtc(),
      rolls: rolls,
      modifier: modifier,
      total: finalResult,
      sides: sides,
    );

    setState(() {
      _displayedNumber = finalResult;
      _history.insert(0, newRecord);
      if (_history.length > _maxHistory) {
        _history.removeRange(_maxHistory, _history.length);
      }
    });

    await Future.delayed(const Duration(milliseconds: 450));

    setState(() => _isRolling = false);
  }

  Widget _numberStepper({
    required String label,
    required int value,
    required void Function() onDecrement,
    required void Function() onIncrement,
    required String semantics,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        Row(
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Text(
                value.toString(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline),
            ),
            const SizedBox(width: 12),
            Text(semantics, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  Widget _buildRollButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isRolling ? null : _rollDice,
            icon: const Icon(Icons.casino_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Text(
                _isRolling ? 'Rolling...' : 'Roll',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatUtcLocal(DateTime dt) {
    final local = dt.toLocal();
    // Simple formatting: YYYY-MM-DD HH:MM
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    // For non-desktop platforms we still constrain the UI to look pager-like.
    final double pageWidth = 420;
    final double minPageHeight = 680;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: pageWidth,
            maxWidth: pageWidth,
            minHeight: minPageHeight,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(builder: (context, constraints) {
                final bool narrow = constraints.maxWidth < 520;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Large number display
                    SizedBox(
                      height: narrow ? 160 : 200,
                      child: Center(
                        child: BigNumberDisplay(
                          displayedNumber: _displayedNumber,
                          isRolling: _isRolling,
                        ),
                      ),
                    ),

                    // Controls and breakdown + history
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            DiceControls(
                              diceCount: _diceCount,
                              sides: _sides,
                              modifier: _modifier,
                              narrow: narrow,
                              onDiceDecrement: () {
                                setState(() {
                                  _diceCount = max(_minDice, _diceCount - 1);
                                  _displayedNumber = _diceCount + _modifier;
                                });
                              },
                              onDiceIncrement: () {
                                setState(() {
                                  _diceCount = min(_maxDice, _diceCount + 1);
                                  _displayedNumber = _diceCount + _modifier;
                                });
                              },
                              onSidesDecrement: () {
                                setState(() {
                                  _sides = max(_minSides, _sides - 1);
                                  _displayedNumber = _diceCount + _modifier;
                                });
                              },
                              onSidesIncrement: () {
                                setState(() {
                                  _sides = min(_maxSides, _sides + 1);
                                  _displayedNumber = _diceCount + _modifier;
                                });
                              },
                              onModifierDecrement: () {
                                setState(() {
                                  _modifier = max(_minModifier, _modifier - 1);
                                  _displayedNumber = _diceCount + _modifier;
                                });
                              },
                              onModifierIncrement: () {
                                setState(() {
                                  _modifier = min(_maxModifier, _modifier + 1);
                                  _displayedNumber = _diceCount + _modifier;
                                });
                              },
                              onPresetSelected: (preset) {
                                setState(() {
                                  _sides = preset;
                                  _displayedNumber = _diceCount + _modifier;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildRollButton(),
                            const SizedBox(height: 8),
                            RollHistoryList(
                              history: _history,
                              isRolling: _isRolling,
                              showBreakdown: _showBreakdown,
                              diceCount: _diceCount,
                              sides: _sides,
                              modifier: _modifier,
                              onToggleBreakdown: () {
                                setState(() {
                                  _showBreakdown = !_showBreakdown;
                                });
                              },
                              onClearHistory: _clearHistory,
                              onReroll: _rerollFromRecord,
                              formatDateTime: _formatUtcLocal,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer / spacing
                    const SizedBox(height: 8),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
