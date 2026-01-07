import 'package:flutter/material.dart';

class BigNumberDisplay extends StatefulWidget {
  final int? displayedNumber;
  final bool isRolling;
  final int? minPossible;
  final int? maxPossible;

  const BigNumberDisplay({
    super.key,
    required this.displayedNumber,
    required this.isRolling,
    this.minPossible,
    this.maxPossible,
  });

  @override
  State<BigNumberDisplay> createState() => _BigNumberDisplayState();
}

class _BigNumberDisplayState extends State<BigNumberDisplay> {
  bool _isFlashing = false;
  bool _isMaxCrit = false;

  @override
  void didUpdateWidget(BigNumberDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Detect when we transition from rolling to not rolling with a crit
    if (oldWidget.isRolling && !widget.isRolling) {
      final displayedNumber = widget.displayedNumber;
      final minPossible = widget.minPossible;
      final maxPossible = widget.maxPossible;
      
      if (displayedNumber != null && minPossible != null && maxPossible != null) {
        if (displayedNumber == maxPossible || displayedNumber == minPossible) {
          setState(() {
            _isFlashing = true;
            _isMaxCrit = displayedNumber == maxPossible;
          });
          
          // Stop flashing after a brief moment
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() {
                _isFlashing = false;
              });
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = (widget.displayedNumber ?? 0).toString();
    
    // Determine color based on critical rolls
    Color numberColor = Colors.black87;
    if (!widget.isRolling && widget.displayedNumber != null && widget.minPossible != null && widget.maxPossible != null) {
      if (widget.displayedNumber == widget.maxPossible) {
        numberColor = Colors.green.shade700;
      } else if (widget.displayedNumber == widget.minPossible) {
        numberColor = Colors.red.shade700;
      }
    }
    
    // Determine shadows based on state
    List<Shadow> shadows;
    if (widget.isRolling) {
      shadows = [
        const Shadow(blurRadius: 24, color: Colors.deepPurpleAccent),
      ];
    } else if (_isFlashing) {
      if (_isMaxCrit) {
        // Bright flash for maximum crit
        shadows = [
          Shadow(blurRadius: 40, color: Colors.green.shade400.withOpacity(0.9)),
          Shadow(blurRadius: 60, color: Colors.green.shade300.withOpacity(0.7)),
          const Shadow(blurRadius: 80, color: Colors.greenAccent),
        ];
      } else {
        // Dark flash for minimum crit failure
        shadows = [
          Shadow(blurRadius: 40, color: Colors.red.shade700.withOpacity(0.9)),
          Shadow(blurRadius: 60, color: Colors.red.shade900.withOpacity(0.7)),
          const Shadow(blurRadius: 80, color: Colors.black54),
        ];
      }
    } else {
      shadows = [
        const Shadow(blurRadius: 8, color: Colors.white),
        const Shadow(blurRadius: 16, color: Colors.white),
      ];
    }

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
            color: widget.isRolling ? Colors.deepPurple : numberColor,
            shadows: shadows,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
