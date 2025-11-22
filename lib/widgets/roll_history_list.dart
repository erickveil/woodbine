import 'package:flutter/material.dart';

import '../models/roll_record.dart';
import 'roll_breakdown.dart';
import 'roll_history_card.dart';

class RollHistoryList extends StatelessWidget {
  final List<RollRecord> history;
  final bool isRolling;
  final bool showBreakdown;
  final int diceCount;
  final int sides;
  final int modifier;
  final VoidCallback onToggleBreakdown;
  final VoidCallback onClearHistory;
  final void Function(RollRecord) onReroll;
  final String Function(DateTime) formatDateTime;

  const RollHistoryList({
    super.key,
    required this.history,
    required this.isRolling,
    required this.showBreakdown,
    required this.diceCount,
    required this.sides,
    required this.modifier,
    required this.onToggleBreakdown,
    required this.onClearHistory,
    required this.onReroll,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        _buildContent(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Last roll & history', style: TextStyle(fontWeight: FontWeight.w600)),
        Row(
          children: [
            IconButton(
              tooltip: showBreakdown ? 'Hide breakdown' : 'Show breakdown',
              onPressed: onToggleBreakdown,
              icon: Icon(showBreakdown ? Icons.expand_less : Icons.expand_more),
            ),
            IconButton(
              tooltip: 'Clear history',
              onPressed: history.isEmpty ? null : onClearHistory,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (showBreakdown) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMostRecentRoll(),
          _buildHistorySection(),
        ],
      );
    } else {
      return _buildCollapsedSummary();
    }
  }

  Widget _buildMostRecentRoll() {
    if (history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No rolls yet', style: TextStyle(color: Colors.black54)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Most recent'),
        const SizedBox(height: 8),
        RollBreakdown(
          rolls: history.first.rolls,
          modifier: history.first.modifier,
          sides: history.first.sides,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('History', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('${history.length} entries', style: const TextStyle(color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 8),
        _buildHistoryList(),
        const SizedBox(height: 8),
        _buildPreviewFooter(),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Text('No history yet', style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final r = history[idx];
        return RollHistoryCard(
          record: r,
          isRolling: isRolling,
          onReroll: () => onReroll(r),
          formatDateTime: formatDateTime,
        );
      },
    );
  }

  Widget _buildPreviewFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Preview: ${diceCount}d$sides ${modifier >= 0 ? "+$modifier" : modifier}'),
        Text('Range: ${diceCount * 1 + modifier} — ${diceCount * sides + modifier}'),
      ],
    );
  }

  Widget _buildCollapsedSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        history.isNotEmpty
            ? 'Latest: ${history.first.total}  —  Rolls: ${history.first.rolls.join(", ")} ${history.first.modifier != 0 ? " (modifier ${history.first.modifier >= 0 ? "+${history.first.modifier}" : history.first.modifier})" : ""}'
            : 'No rolls yet',
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }
}
