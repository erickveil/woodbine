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
  int _target = 10;
  bool _targetEnabled = false;
  int _explodeValue = 6;
  bool _explodeEnabled = false;

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
  final int _minTarget = 1;
  final int _maxTarget = 10000;
  final int _minExplode = 2;
  final int _maxExplode = 1000;

  // UI state
  bool _showBreakdown = true;

  // maximum history entries to keep
  final int _maxHistory = 200;

  @override
  void initState() {
    super.initState();
    _displayedNumber = _diceCount + _modifier;
  }

  int get _minPossibleValue => _diceCount * 1 + _modifier;
  int get _maxPossibleValue => _diceCount * _sides + _modifier;

  Future<void> _rollDice() async {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
    });

    final int minValue = _diceCount * 1 + _modifier;
    final int maxValue = _diceCount * _sides + _modifier;

    // Simulate actual dice rolls to compute the final result and keep breakdown
    List<int> rolls =
        List.generate(_diceCount, (_) => _rng.nextInt(_sides) + 1);
    
    // Handle exploding dice
    if (_explodeEnabled) {
      int maxIterations = 1000; // Safety limit to prevent infinite loops
      int iterations = 0;
      int i = 0;
      while (i < rolls.length && iterations < maxIterations) {
        if (rolls[i] >= _explodeValue) {
          // This die explodes! Add another die
          int newRoll = _rng.nextInt(_sides) + 1;
          rolls.add(newRoll);
        }
        i++;
        iterations++;
      }
    }
    
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
      target: _targetEnabled ? _target : null,
      targetEnabled: _targetEnabled,
      explodeValue: _explodeEnabled ? _explodeValue : null,
      explodeEnabled: _explodeEnabled,
      originalDiceCount: _diceCount,
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

    final int count = record.originalDiceCount;
    final int sides = record.sides;
    final int modifier = record.modifier;
    final bool explodeEnabled = record.explodeEnabled;
    final int? explodeValue = record.explodeValue;

    final int minValue = count * 1 + modifier;
    final int maxValue = count * sides + modifier;

    // perform new rolls (but do not change UI inputs)
    List<int> rolls = List.generate(count, (_) => _rng.nextInt(sides) + 1);
    
    // Handle exploding dice
    if (explodeEnabled && explodeValue != null) {
      int maxIterations = 1000; // Safety limit to prevent infinite loops
      int iterations = 0;
      int i = 0;
      while (i < rolls.length && iterations < maxIterations) {
        if (rolls[i] >= explodeValue) {
          // This die explodes! Add another die
          int newRoll = _rng.nextInt(sides) + 1;
          rolls.add(newRoll);
        }
        i++;
        iterations++;
      }
    }
    
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
      target: record.target,
      targetEnabled: record.targetEnabled,
      explodeValue: record.explodeValue,
      explodeEnabled: record.explodeEnabled,
      originalDiceCount: record.originalDiceCount,
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

  Widget _buildPageScaffold(Widget content) {
    const double pageWidth = 420;
    const double minPageHeight = 680;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: pageWidth,
            maxWidth: pageWidth,
            minHeight: minPageHeight,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
            color: Colors.transparent,
            //color: Colors.white.withOpacity(0.6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberDisplay(bool narrow) {
    return SizedBox(
      height: narrow ? 160 : 200,
      child: Center(
        child: BigNumberDisplay(
          displayedNumber: _displayedNumber,
          isRolling: _isRolling,
          minPossible: _minPossibleValue,
          maxPossible: _maxPossibleValue,
          target: _target,
          targetEnabled: _targetEnabled,
        ),
      ),
    );
  }

  Widget _buildDiceControls(bool narrow) {
    return DiceControls(
      diceCount: _diceCount,
      sides: _sides,
      modifier: _modifier,
      target: _target,
      targetEnabled: _targetEnabled,
      explodeValue: _explodeValue,
      explodeEnabled: _explodeEnabled,
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
      onTargetDecrement: () {
        setState(() {
          _target = max(_minTarget, _target - 1);
        });
      },
      onTargetIncrement: () {
        setState(() {
          _target = min(_maxTarget, _target + 1);
        });
      },
      onTargetEnabledChanged: (enabled) {
        setState(() {
          _targetEnabled = enabled;
        });
      },
      onExplodeDecrement: () {
        setState(() {
          _explodeValue = max(_minExplode, _explodeValue - 1);
        });
      },
      onExplodeIncrement: () {
        setState(() {
          _explodeValue = min(_maxExplode, _explodeValue + 1);
        });
      },
      onExplodeEnabledChanged: (enabled) {
        setState(() {
          _explodeEnabled = enabled;
        });
      },
      onPresetSelected: (preset) {
        setState(() {
          _diceCount = 1;
          _sides = preset;
          _modifier = 0;
          _displayedNumber = _diceCount + _modifier;
        });
      },
      onDiceChanged: (value) {
        setState(() {
          _diceCount = max(_minDice, min(_maxDice, value));
          _displayedNumber = _diceCount + _modifier;
        });
      },
      onSidesChanged: (value) {
        setState(() {
          _sides = max(_minSides, min(_maxSides, value));
          _displayedNumber = _diceCount + _modifier;
        });
      },
      onModifierChanged: (value) {
        setState(() {
          _modifier = max(_minModifier, min(_maxModifier, value));
          _displayedNumber = _diceCount + _modifier;
        });
      },
      onTargetChanged: (value) {
        setState(() {
          _target = max(_minTarget, min(_maxTarget, value));
        });
      },
      onExplodeChanged: (value) {
        setState(() {
          _explodeValue = max(_minExplode, min(_maxExplode, value));
        });
      },
    );
  }

  Widget _buildHistoryList() {
    return RollHistoryList(
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
    );
  }

  Widget _buildControlsSection(bool narrow) {
    return Expanded(
      child: SingleChildScrollView(
        child: Stack(
          children: [
            /*
            // Background image that extends to full window width
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/controls_background.jpg'),
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            */
            // Content on top
            Column(
              children: [
                _buildDiceControls(narrow),
                const SizedBox(height: 14),
                _buildRollButton(),
                const SizedBox(height: 8),
                _buildHistoryList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool narrow) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildNumberDisplay(narrow),
        _buildControlsSection(narrow),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPageScaffold(
      LayoutBuilder(
        builder: (context, constraints) {
          final bool narrow = constraints.maxWidth < 520;
          return _buildMainContent(narrow);
        },
      ),
    );
  }
}
