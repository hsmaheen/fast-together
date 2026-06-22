import 'package:flutter/material.dart';

class FastingProgressRing extends StatelessWidget {
  const FastingProgressRing({
    required this.progress,
    this.isOverTarget = false,
    this.size = 96,
    this.child,
    super.key,
  });

  final double progress;
  final bool isOverTarget;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: progress.clamp(0, 1),
              strokeWidth: 8,
              color: isOverTarget
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              semanticsLabel: isOverTarget
                  ? 'Fasting progress over target'
                  : 'Fasting progress',
              semanticsValue: '${(progress.clamp(0, 1) * 100).round()}%',
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}
