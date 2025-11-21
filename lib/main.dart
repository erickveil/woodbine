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
    const double height = 680;

    window_size.setWindowTitle('Dice Roller');
    final info = await window_size.getWindowInfo();
    if (info.screen != null) {
      final screenFrame = info.screen!.visibleFrame;
      final left = screenFrame.left + (screenFrame.width - width) / 2;
      final top = screenFrame.top + (screenFrame.height - height) / 2;
      window_size.setWindowFrame(ui.Rect.fromLTWH(left, top, width, height));
      window_size.setWindowMinSize(ui.Size(width, height));
      window_size.setWindowMaxSize(ui.Size(width, height));
    } else {
      // If screen info isn't available, still set min/max size so window is fixed.
      window_size.setWindowMinSize(ui.Size(width, height));
      window_size.setWindowMaxSize(ui.Size(width, height));
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

  // Breakdown of last roll (each die)
  List<int> _lastRolls = [];

  // Controls for input limits
  final int _minDice = 1;
  final int _maxDice = 100;
  final int _minSides = 2;
  final int _maxSides = 1000; // arbitrary practical limit
  final int _minModifier = -10000;
  final int _maxModifier = 10000;

  // UI state
  bool _showBreakdown = true;

  @override
  void initState() {
    super.initState();
    _displayedNumber = _diceCount + _modifier;
  }

  Future<void> _rollDice() async {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
      _lastRolls = [];
    });

    final int minValue = _diceCount * 1 + _modifier;
    final int maxValue = _diceCount * _sides + _modifier;

    // Simulate actual dice rolls to compute the final result and keep breakdown
    List<int> rolls = List.generate(_diceCount, (_) => _rng.nextInt(_sides) + 1);
    int finalResult = rolls.fold(0, (p, e) => p + e) + _modifier;

    // Animation: cycle through random numbers in [minValue, maxValue],
    // starting fast and slowing down.
    const int frames = 28;
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

    // Finally show the actual result and store breakdown
    setState(() {
      _displayedNumber = finalResult;
      _lastRolls = rolls;
    });

    // brief glow: wait a bit so user sees final number
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

  Widget _breakdownChips() {
    if (_lastRolls.isEmpty) {
      return const Text('No rolls yet', style: TextStyle(color: Colors.black54));
    }

    List<Widget> chips = [];
    for (int i = 0; i < _lastRolls.length; i++) {
      chips.add(
        Chip(
          label: Text('d${i + 1}: ${_lastRolls[i]}'),
          backgroundColor: Colors.grey[100],
        ),
      );
    }

    // modifier chip
    chips.add(
      Chip(
        label: Text('modifier: ${_modifier >= 0 ? "+$_modifier" : _modifier}'),
        backgroundColor: Colors.grey[200],
      ),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _breakdownHistogram() {
    if (_lastRolls.isEmpty) {
      return const SizedBox.shrink();
    }

    // only show histogram for reasonable number of different faces
    final int faces = _sides;
    final counts = List<int>.filled(faces + 1, 0); // index 1..faces
    for (var v in _lastRolls) {
      if (v >= 1 && v <= faces) counts[v]++;
    }
    final int maxCount = counts.skip(1).fold(0, (p, e) => max(p, e));

    // If too many faces, put histogram in scrollable
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

  @override
  Widget build(BuildContext context) {
    // For non-desktop platforms we still constrain the UI to look pager-like.
    final double pageWidth = 420;
    final double pageHeight = 680;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: pageWidth, height: pageHeight),
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

                    // Controls and breakdown
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
                                const Text('Last roll', style: TextStyle(fontWeight: FontWeight.w600)),
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
                                    )
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_showBreakdown)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // chips for each die and modifier
                                  _breakdownChips(),
                                  const SizedBox(height: 12),
                                  // histogram
                                  _breakdownHistogram(),
                                  const SizedBox(height: 10),
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
                                  _lastRolls.isNotEmpty
                                      ? 'Result: ${_displayedNumber ?? 0}  —  Rolls: ${_lastRolls.join(", ")} ${_modifier != 0 ? " (modifier ${_modifier >= 0 ? "+$_modifier" : _modifier})" : ""}'
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