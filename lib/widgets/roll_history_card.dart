import 'package:flutter/material.dart';

import '../models/roll_record.dart';
import 'roll_breakdown.dart';

class RollHistoryCard extends StatelessWidget {
  final RollRecord record;
  final bool isRolling;
  final VoidCallback onReroll;
  final String Function(DateTime) formatDateTime;

  const RollHistoryCard({
    super.key,
    required this.record,
    required this.isRolling,
    required this.onReroll,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
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
                    record.total.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${record.rolls.length}d${record.sides} ${record.modifier >= 0 ? "+${record.modifier}" : record.modifier}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  formatDateTime(record.time),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Re-roll this entry',
                  onPressed: isRolling ? null : onReroll,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRollsPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildRollsPreview() {
    const int maxShown = 12;
    if (record.rolls.length <= maxShown) {
      return RollBreakdown(
        rolls: record.rolls,
        modifier: record.modifier,
        sides: record.sides,
        showHistogram: false,
      );
    } else {
      final shown = record.rolls.sublist(0, maxShown);
      final remaining = record.rolls.length - maxShown;
      final chips = <Widget>[];
      for (int i = 0; i < shown.length; i++) {
        final int roll = shown[i];
        Color? backgroundColor;
        Color? textColor;
        
        // Color based on critical rolls
        if (roll == record.sides) {
          backgroundColor = Colors.green.shade100;
          textColor = Colors.green.shade900;
        } else if (roll == 1) {
          backgroundColor = Colors.red.shade100;
          textColor = Colors.red.shade900;
        } else {
          backgroundColor = Colors.grey[100];
          textColor = null;
        }
        
        chips.add(Chip(
          label: Text(
            '$roll',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: backgroundColor,
        ));
      }
      chips.add(Chip(label: Text('… +$remaining more'), backgroundColor: Colors.grey[200]));
      chips.add(Chip(
        label: Text('mod ${record.modifier >= 0 ? "+${record.modifier}" : record.modifier}'),
        backgroundColor: Colors.grey[200],
      ));
      return Wrap(spacing: 8, runSpacing: 6, children: chips);
    }
  }
}
