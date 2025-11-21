import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
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

  // Controls for input limits
  final int _minDice = 1;
  final int _maxDice = 100;
  final int _minSides = 2;
  final int _maxSides = 1000; // arbitrary practical limit
  final int _minModifier = -10000;
  final int _maxModifier = 10000;

  @override
  void initState() {
    super.initState();
    _displayedNumber = _diceCount + _modifier;
  }

  Future<void> _rollDice() async {
    if (_isRolling) return;

    setState(() => _isRolling = true);

    final int minValue = _diceCount * 1 + _modifier;
    final int maxValue = _diceCount * _sides + _modifier;

    // Simulate actual dice rolls to compute the final result
    int finalResult = 0;
    for (int i = 0; i < _diceCount; i++) {
      finalResult += _rng.nextInt(_sides) + 1;
    }
    finalResult += _modifier;

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

    // Finally show the actual result with a small highlight animation
    setState(() => _displayedNumber = finalResult);

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

  @override
  Widget build(BuildContext context) {
    // Page-sized layout, centered column
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dice Roller'),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final bool narrow = constraints.maxWidth < 520;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Large number display
                  SizedBox(
                    height: narrow ? 190 : 240,
                    child: Center(
                      child: _bigNumberWidget(),
                    ),
                  ),

                  // Controls
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Range: ${_diceCount * 1 + _modifier} — ${_diceCount * _sides + _modifier}'),
                              Text('Preview: ${_diceCount}d$_sides ${_modifier >= 0 ? "+$_modifier" : _modifier}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer / spacing
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}