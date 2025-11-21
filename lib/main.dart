import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart' as window_size;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fixed pager-like window size for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    const double width = 420;
    const double minHeight = 680;

    window_size.setWindowTitle('Dice Roller');
    final info = await window_size.getWindowInfo();
    if (info.screen != null) {
      final screenFrame = info.screen!.visibleFrame;
      final left = screenFrame.left + (screenFrame.width - width) / 2;
      final top = screenFrame.top + (screenFrame.height - minHeight) / 2;
      window_size.setWindowFrame(ui.Rect.fromLTWH(left, top, width, minHeight));
      window_size.setWindowMinSize(ui.Size(width, minHeight));
      window_size.setWindowMaxSize(ui.Size(width, screenFrame.height));
    } else {
      // If screen info isn't available, still set min/max size so window is fixed.
      window_size.setWindowMinSize(ui.Size(width, minHeight));
      window_size.setWindowMaxSize(ui.Size(width, 2000));
    }
  }

  runApp(const DiceRollerApp());
}

class DiceRollerApp extends StatelessWidget {
  const DiceRollerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Roller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DiceRollerPage(),
    );
  }
}

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

class DiceRollerPage extends StatefulWidget {
  const DiceRollerPage({super.key});

  @override
  State<DiceRollerPage> createState() => _DiceRollerPageState();
}

class _DiceRollerPageState extends State<DiceRollerPage> {
  final Random _rng = Random();

  int _diceCount = 2;
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

  Widget _bigNumberWidget() {
    final text = (_displayedNumber ?? 0).toString();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, animation) {
        // combine scale and slide for pop/flip feel
        final scale = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
        final offset = Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offset,
            child: ScaleTransition(scale: scale, child: child),
          ),
        );
      },
      child: Container(
        key: ValueKey<String>(text),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 88,
            fontWeight: FontWeight.w900,
            color: _isRolling ? Colors.deepPurple : Colors.black87,
            shadows: _isRolling
                ? [
                    const Shadow(blurRadius: 24, color: Colors.deepPurpleAccent),
                  ]
                : null,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
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

  Widget _breakdownChipsFromRoll(List<int> rolls, int modifier) {
    if (rolls.isEmpty) {
      return const Text('No rolls yet', style: TextStyle(color: Colors.black54));
    }

    List<Widget> chips = [];
    for (int i = 0; i < rolls.length; i++) {
      chips.add(
        Chip(
          label: Text('${rolls[i]}', style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            )),
          backgroundColor: Colors.grey[100],
        ),
      );
    }

    // modifier chip
    chips.add(
      Chip(
        label: Text('modifier: ${modifier >= 0 ? "+$modifier" : modifier}'),
        backgroundColor: Colors.grey[200],
      ),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _breakdownHistogramFromRoll(List<int> rolls, int faces) {
    if (rolls.isEmpty) {
      return const SizedBox.shrink();
    }

    final counts = List<int>.filled(faces + 1, 0); // index 1..faces
    for (var v in rolls) {
      if (v >= 1 && v <= faces) counts[v]++;
    }
    final int maxCount = counts.skip(1).fold(0, (p, e) => max(p, e));

    final bars = List.generate(faces, (i) {
      final face = i + 1;
      final int c = counts[face];
      final double fraction = maxCount == 0 ? 0 : c / maxCount;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(c.toString(), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            width: 18,
            height: 80,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              color: Colors.white,
            ),
            child: FractionallySizedBox(
              heightFactor: fraction,
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(' $face', style: const TextStyle(fontSize: 12)),
        ],
      );
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars
            .map((w) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: w,
                ))
            .toList(),
      ),
    );
  }

  String _formatUtcLocal(DateTime dt) {
    final local = dt.toLocal();
    // Simple formatting: YYYY-MM-DD HH:MM
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  Widget _historyList() {
    if (_history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Text('No history yet', style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final r = _history[idx];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        r.total.toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${r.rolls.length}d${r.sides} ${r.modifier >= 0 ? "+${r.modifier}" : r.modifier}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _formatUtcLocal(r.time),
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Re-roll this entry',
                      onPressed: _isRolling ? null : () => _rerollFromRecord(r),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // show first N rolls as chips, collapse if too many
                _buildRollsPreview(r.rolls, r.modifier),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRollsPreview(List<int> rolls, int modifier) {
    const int maxShown = 12;
    if (rolls.length <= maxShown) {
      return _breakdownChipsFromRoll(rolls, modifier);
    } else {
      final shown = rolls.sublist(0, maxShown);
      final remaining = rolls.length - maxShown;
      final chips = <Widget>[];
      for (int i = 0; i < shown.length; i++) {
        chips.add(Chip(label: Text('${shown[i]}'), backgroundColor: Colors.grey[100]));
      }
      chips.add(Chip(label: Text('… +$remaining more'), backgroundColor: Colors.grey[200]));
      chips.add(Chip(label: Text('mod ${modifier >= 0 ? "+$modifier" : modifier}'), backgroundColor: Colors.grey[200]));
      return Wrap(spacing: 8, runSpacing: 6, children: chips);
    }
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
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
                        child: _bigNumberWidget(),
                      ),
                    ),

                    // Controls and breakdown + history
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Row of steppers or stacked
                            narrow
                                ? Column(
                                    children: [
                                      _numberStepper(
                                        label: 'Dice',
                                        value: _diceCount,
                                        onDecrement: () {
                                          setState(() {
                                            _diceCount = max(_minDice, _diceCount - 1);
                                            _displayedNumber = _diceCount + _modifier;
                                          });
                                        },
                                        onIncrement: () {
                                          setState(() {
                                            _diceCount = min(_maxDice, _diceCount + 1);
                                            _displayedNumber = _diceCount + _modifier;
                                          });
                                        },
                                        semantics: 'Number of dice',
                                      ),
                                      const SizedBox(height: 12),
                                      _numberStepper(
                                        label: 'Sides',
                                        value: _sides,
                                        onDecrement: () {
                                          setState(() {
                                            _sides = max(_minSides, _sides - 1);
                                            _displayedNumber = _diceCount + _modifier;
                                          });
                                        },
                                        onIncrement: () {
                                          setState(() {
                                            _sides = min(_maxSides, _sides + 1);
                                            _displayedNumber = _diceCount + _modifier;
                                          });
                                        },
                                        semantics: 'Number of sides per die',
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text('Modifier'),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _modifier = max(_minModifier, _modifier - 1);
                                                _displayedNumber = _diceCount + _modifier;
                                              });
                                            },
                                            icon: const Icon(Icons.remove),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.black12),
                                              borderRadius: BorderRadius.circular(8),
                                              color: Colors.white,
                                            ),
                                            child: Text(
                                              _modifier.toString(),
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _modifier = min(_maxModifier, _modifier + 1);
                                                _displayedNumber = _diceCount + _modifier;
                                              });
                                            },
                                            icon: const Icon(Icons.add),
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _numberStepper(
                                          label: 'Dice',
                                          value: _diceCount,
                                          onDecrement: () {
                                            setState(() {
                                              _diceCount = max(_minDice, _diceCount - 1);
                                              _displayedNumber = _diceCount + _modifier;
                                            });
                                          },
                                          onIncrement: () {
                                            setState(() {
                                              _diceCount = min(_maxDice, _diceCount + 1);
                                              _displayedNumber = _diceCount + _modifier;
                                            });
                                          },
                                          semantics: 'Number of dice',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _numberStepper(
                                          label: 'Sides',
                                          value: _sides,
                                          onDecrement: () {
                                            setState(() {
                                              _sides = max(_minSides, _sides - 1);
                                              _displayedNumber = _diceCount + _modifier;
                                            });
                                          },
                                          onIncrement: () {
                                            setState(() {
                                              _sides = min(_maxSides, _sides + 1);
                                              _displayedNumber = _diceCount + _modifier;
                                            });
                                          },
                                          semantics: 'Number of sides per die',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Modifier'),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _modifier = max(_minModifier, _modifier - 1);
                                                      _displayedNumber = _diceCount + _modifier;
                                                    });
                                                  },
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
                                                    _modifier.toString(),
                                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _modifier = min(_maxModifier, _modifier + 1);
                                                      _displayedNumber = _diceCount + _modifier;
                                                    });
                                                  },
                                                  icon: const Icon(Icons.add_circle_outline),
                                                ),
                                                const SizedBox(width: 8),
                                                const Text(
                                                  'Add modifier to total',
                                                  style: TextStyle(color: Colors.black54),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 14),
                            // quick presets for common dice sides
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [4, 6, 8, 10, 12, 20, 100].map((preset) {
                                return ChoiceChip(
                                  label: Text('d$preset'),
                                  selected: _sides == preset,
                                  onSelected: (sel) {
                                    setState(() {
                                      _sides = preset;
                                      _displayedNumber = _diceCount + _modifier;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            Row(
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
                            ),
                            const SizedBox(height: 8),

                            // Breakdown header and toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Last roll & history', style: TextStyle(fontWeight: FontWeight.w600)),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: _showBreakdown ? 'Hide breakdown' : 'Show breakdown',
                                      onPressed: () {
                                        setState(() {
                                          _showBreakdown = !_showBreakdown;
                                        });
                                      },
                                      icon: Icon(_showBreakdown ? Icons.expand_less : Icons.expand_more),
                                    ),
                                    IconButton(
                                      tooltip: 'Clear history',
                                      onPressed: _history.isEmpty ? null : _clearHistory,
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_showBreakdown)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // show most recent roll breakdown (if any)
                                  if (_history.isNotEmpty) ...[
                                    const Text('Most recent'),
                                    const SizedBox(height: 8),
                                    _breakdownChipsFromRoll(_history.first.rolls, _history.first.modifier),
                                    const SizedBox(height: 12),
                                    _breakdownHistogramFromRoll(_history.first.rolls, _history.first.sides),
                                    const SizedBox(height: 12),
                                  ] else
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text('No rolls yet', style: TextStyle(color: Colors.black54)),
                                    ),

                                  // history section
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('History', style: TextStyle(fontWeight: FontWeight.w600)),
                                      Text('${_history.length} entries', style: const TextStyle(color: Colors.black54)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _historyList(),
                                  const SizedBox(height: 8),
                                  // textual details
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Preview: ${_diceCount}d$_sides ${_modifier >= 0 ? "+$_modifier" : _modifier}'),
                                      Text('Range: ${_diceCount * 1 + _modifier} — ${_diceCount * _sides + _modifier}'),
                                    ],
                                  ),
                                ],
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  _history.isNotEmpty
                                      ? 'Latest: ${_history.first.total}  —  Rolls: ${_history.first.rolls.join(", ")} ${_history.first.modifier != 0 ? " (modifier ${_history.first.modifier >= 0 ? "+${_history.first.modifier}" : _history.first.modifier})" : ""}'
                                      : 'No rolls yet',
                                  style: const TextStyle(color: Colors.black54),
                                ),
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