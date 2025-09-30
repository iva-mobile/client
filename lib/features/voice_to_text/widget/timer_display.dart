import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key, required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style =
        textTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ) ??
        const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color(0xFF757575),
          letterSpacing: 1.2,
          fontFeatures: [FontFeature.tabularFigures()],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(_format(duration), style: style),
    );
  }

  String _format(Duration duration) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
