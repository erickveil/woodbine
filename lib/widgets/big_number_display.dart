import 'package:flutter/material.dart';

class BigNumberDisplay extends StatelessWidget {
  final int? displayedNumber;
  final bool isRolling;

  const BigNumberDisplay({
    super.key,
    required this.displayedNumber,
    required this.isRolling,
  });

  @override
  Widget build(BuildContext context) {
    final text = (displayedNumber ?? 0).toString();

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
            color: isRolling ? Colors.deepPurple : Colors.black87,
            shadows: isRolling
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
}
