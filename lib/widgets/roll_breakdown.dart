import 'dart:math';

import 'package:flutter/material.dart';

class RollBreakdown extends StatelessWidget {
  final List<int> rolls;
  final int modifier;
  final int sides;
  final bool showHistogram;

  const RollBreakdown({
    super.key,
    required this.rolls,
    required this.modifier,
    required this.sides,
    this.showHistogram = true,
  });

  @override
  Widget build(BuildContext context) {
    if (rolls.isEmpty) {
      return const Text('No rolls yet', style: TextStyle(color: Colors.black54));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChips(),
        if (showHistogram) ...[
          const SizedBox(height: 12),
          _buildHistogram(),
        ],
      ],
    );
  }

  Widget _buildChips() {
    List<Widget> chips = [];
    
    for (int i = 0; i < rolls.length; i++) {
      final int roll = rolls[i];
      Color? backgroundColor;
      Color? textColor;
      
      // Color based on critical rolls
      if (roll == sides) {
        // Maximum roll
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
      } else if (roll == 1) {
        // Minimum roll
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
      } else {
        backgroundColor = Colors.grey[100];
        textColor = null;
      }
      
      chips.add(
        Chip(
          label: Text(
            '$roll',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
          backgroundColor: backgroundColor,
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

  Widget _buildHistogram() {
    if (rolls.isEmpty) {
      return const SizedBox.shrink();
    }

    final counts = List<int>.filled(sides + 1, 0); // index 1..sides
    for (var v in rolls) {
      if (v >= 1 && v <= sides) counts[v]++;
    }
    final int maxCount = counts.skip(1).fold(0, (p, e) => max(p, e));

    final bars = List.generate(sides, (i) {
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
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
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
}
