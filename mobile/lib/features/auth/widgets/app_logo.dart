import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Transform.rotate(
          angle: -0.08,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(size * 0.3),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              '🥕🍅\n🥬🧀',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: size * 0.28, height: 1.2),
            ),
          ),
        ),
        if (showName) ...[
          const SizedBox(height: 20),
          Text(
            'Evdekiler',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
