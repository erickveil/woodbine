import 'package:flutter/material.dart';

class DiceControls extends StatelessWidget {
  static const double _labelWidth = 100;

  final int diceCount;
  final int sides;
  final int modifier;
  final int target;
  final bool targetEnabled;
  final VoidCallback onDiceDecrement;
  final VoidCallback onDiceIncrement;
  final VoidCallback onSidesDecrement;
  final VoidCallback onSidesIncrement;
  final VoidCallback onModifierDecrement;
  final VoidCallback onModifierIncrement;
  final VoidCallback onTargetDecrement;
  final VoidCallback onTargetIncrement;
  final ValueChanged<bool> onTargetEnabledChanged;
  final ValueChanged<int> onPresetSelected;
  final ValueChanged<int> onDiceChanged;
  final ValueChanged<int> onSidesChanged;
  final ValueChanged<int> onModifierChanged;
  final ValueChanged<int> onTargetChanged;
  final bool narrow;

  const DiceControls({
    super.key,
    required this.diceCount,
    required this.sides,
    required this.modifier,
    required this.target,
    required this.targetEnabled,
    required this.onDiceDecrement,
    required this.onDiceIncrement,
    required this.onSidesDecrement,
    required this.onSidesIncrement,
    required this.onModifierDecrement,
    required this.onModifierIncrement,
    required this.onTargetDecrement,
    required this.onTargetIncrement,
    required this.onTargetEnabledChanged,
    required this.onPresetSelected,
    required this.onDiceChanged,
    required this.onSidesChanged,
    required this.onModifierChanged,
    required this.onTargetChanged,
    this.narrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSteppers(context),
        const SizedBox(height: 14),
        _buildPresetChips(),
      ],
    );
  }

  Widget _buildSteppers(BuildContext context) {
    return narrow
        ? Column(
            children: [
              const SizedBox(height: 10),
              _numberStepper(
                context: context,
                label: 'Dice',
                value: diceCount,
                onDecrement: onDiceDecrement,
                onIncrement: onDiceIncrement,
                onDirectInput: onDiceChanged,
                semantics: 'Number of dice',
              ),
              const SizedBox(height: 12),
              _numberStepper(
                context: context,
                label: 'Sides',
                value: sides,
                onDecrement: onSidesDecrement,
                onIncrement: onSidesIncrement,
                onDirectInput: onSidesChanged,
                semantics: 'Number of sides per die',
              ),
              const SizedBox(height: 12),
              _buildModifierControlNarrow(context),
              const SizedBox(height: 12),
              _buildTargetControlNarrow(context),
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
                      context: context,
                      label: 'Dice',
                      value: diceCount,
                      onDecrement: onDiceDecrement,
                      onIncrement: onDiceIncrement,
                      onDirectInput: onDiceChanged,
                      semantics: 'Number of dice',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberStepper(
                      context: context,
                      label: 'Sides',
                      value: sides,
                      onDecrement: onSidesDecrement,
                      onIncrement: onSidesIncrement,
                      onDirectInput: onSidesChanged,
                      semantics: 'Number of sides per die',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModifierControlWide(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTargetControlWide(context),
            ],
          );
  }

  Widget _numberStepper({
    required BuildContext context,
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required ValueChanged<int> onDirectInput,
    required String semantics,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
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
            GestureDetector(
              onTap: () =>
                  _showInputDialog(context, label, value, onDirectInput),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModifierControlNarrow(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const SizedBox(
              width: _labelWidth,
              child: Text(
                'Modifier',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: onModifierDecrement,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            GestureDetector(
              onTap: () => _showInputDialog(
                  context, 'Modifier', modifier, onModifierChanged,
                  allowNegative: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Text(
                  modifier.toString(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            IconButton(
              onPressed: onModifierIncrement,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModifierControlWide(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const SizedBox(
              width: _labelWidth,
              child: Text(
                'Modifier',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: onModifierDecrement,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            GestureDetector(
              onTap: () => _showInputDialog(
                  context, 'Modifier', modifier, onModifierChanged,
                  allowNegative: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Text(
                  modifier.toString(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            IconButton(
              onPressed: onModifierIncrement,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetControlNarrow(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const SizedBox(
              width: _labelWidth,
              child: Text(
                'Target',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (targetEnabled) ...[
              IconButton(
                onPressed: onTargetDecrement,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              GestureDetector(
                onTap: () => _showInputDialog(
                    context, 'Target', target, onTargetChanged),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Text(
                    target.toString(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                onPressed: onTargetIncrement,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ] else
              const Expanded(child: SizedBox()),
            Switch(
              value: targetEnabled,
              onChanged: onTargetEnabledChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetControlWide(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const SizedBox(
              width: _labelWidth,
              child: Text(
                'Target',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (targetEnabled) ...[
              IconButton(
                onPressed: onTargetDecrement,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              GestureDetector(
                onTap: () => _showInputDialog(
                    context, 'Target', target, onTargetChanged),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Text(
                    target.toString(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                onPressed: onTargetIncrement,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ] else
              const Expanded(child: SizedBox()),
            Switch(
              value: targetEnabled,
              onChanged: onTargetEnabledChanged,
            ),
          ],
        ),
      ),
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

  void _showInputDialog(
    BuildContext context,
    String label,
    int currentValue,
    ValueChanged<int> onSubmit, {
    bool allowNegative = false,
  }) {
    final controller = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter $label'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: currentValue.toString(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              final isValid = value != null && (allowNegative || value > 0);
              if (isValid) {
                onSubmit(value);
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
