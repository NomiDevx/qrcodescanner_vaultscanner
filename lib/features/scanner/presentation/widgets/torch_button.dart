import 'package:flutter/material.dart';

/// FAB-style torch toggle button.
class TorchButton extends StatelessWidget {
  const TorchButton({
    super.key,
    required this.isOn,
    required this.onToggle,
  });

  final bool isOn;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOn
            ? cs.primary.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.55),
        boxShadow: isOn
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: IconButton(
        onPressed: onToggle,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
            key: ValueKey(isOn),
            color: Colors.white,
            size: 26,
          ),
        ),
        tooltip: isOn ? 'Turn off torch' : 'Turn on torch',
        padding: const EdgeInsets.all(14),
      ),
    );
  }
}
