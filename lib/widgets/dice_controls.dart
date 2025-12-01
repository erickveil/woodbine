import 'package:flutter/material.dart';

class DiceControls extends StatelessWidget {
  static const double _labelWidth = 100;
  
  final int diceCount;
  final int sides;
  final int modifier;
  final VoidCallback onDiceDecrement;
  final VoidCallback onDiceIncrement;
  final VoidCallback onSidesDecrement;
  final VoidCallback onSidesIncrement;
  final VoidCallback onModifierDecrement;
  final VoidCallback onModifierIncrement;
  final ValueChanged<int> onPresetSelected;
  final bool narrow;

  const DiceControls({
    super.key,
    required this.diceCount,
    required this.sides,
    required this.modifier,
    required this.onDiceDecrement,
    required this.onDiceIncrement,
    required this.onSidesDecrement,
    required this.onSidesIncrement,
    required this.onModifierDecrement,
    required this.onModifierIncrement,
    required this.onPresetSelected,
    this.narrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSteppers(),
        const SizedBox(height: 14),
        _buildPresetChips(),
      ],
    );
  }

  Widget _buildSteppers() {
    return narrow
        ? Column(
            children: [
              const SizedBox(height: 10),
              _numberStepper(
                label: 'Dice',
                value: diceCount,
                onDecrement: onDiceDecrement,
                onIncrement: onDiceIncrement,
                semantics: 'Number of dice',
              ),
              const SizedBox(height: 12),
              _numberStepper(
                label: 'Sides',
                value: sides,
                onDecrement: onSidesDecrement,
                onIncrement: onSidesIncrement,
                semantics: 'Number of sides per die',
              ),
              const SizedBox(height: 12),
              _buildModifierControlNarrow(),
            ],
          )
        : Column(
            children: [
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _numberStepper(
                      label: 'Dice',
                      value: diceCount,
                      onDecrement: onDiceDecrement,
                      onIncrement: onDiceIncrement,
                      semantics: 'Number of dice',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberStepper(
                      label: 'Sides',
                      value: sides,
                      onDecrement: onSidesDecrement,
                      onIncrement: onSidesIncrement,
                      semantics: 'Number of sides per die',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModifierControlWide(),
                  ),
                ],
              ),
            ],
          );
  }

  Widget _numberStepper({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required String semantics,
  }) {
    return Row(
      children: [
        SizedBox(
          width: _labelWidth,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
      ],
    );
  }

  Widget _buildModifierControlNarrow() {
    return Row(
      children: [
        SizedBox(
          width: _labelWidth,
          child: Text(
            'Modifier',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: onModifierDecrement,
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
            modifier.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: onModifierIncrement,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _buildModifierControlWide() {
    return Row(
      children: [
        SizedBox(
          width: _labelWidth,
          child: Text(
            'Modifier',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: onModifierDecrement,
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
            modifier.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: onModifierIncrement,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _buildPresetChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [4, 6, 8, 10, 12, 20, 100].map((preset) {
        return ChoiceChip(
          label: Text('d$preset'),
          selected: sides == preset,
          onSelected: (sel) => onPresetSelected(preset),
        );
      }).toList(),
    );
  }
}
