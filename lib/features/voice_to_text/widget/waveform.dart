import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WaveformWidget extends StatefulWidget {
  const WaveformWidget({
    super.key,
    required this.amplitudes,
    this.height = 220,
    this.barColor = Colors.black,
    this.barWidth = 3,
    this.spacing = 6,
    this.backgroundColor = Colors.transparent,
    this.animationDuration = const Duration(milliseconds: 120),
  });

  final List<double> amplitudes;
  final double height;
  final Color barColor;
  final double barWidth;
  final double spacing;
  final Color backgroundColor;
  final Duration animationDuration;

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<double> _displayed;
  late List<double> _start;
  late List<double> _target;

  @override
  void initState() {
    super.initState();
    final normalized = WaveformPainter.normalize(widget.amplitudes);
    _displayed = List<double>.from(normalized);
    _start = List<double>.from(normalized);
    _target = List<double>.from(normalized);
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..addListener(_handleTick);
  }

  @override
  void didUpdateWidget(covariant WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.animationDuration;
    final normalized = WaveformPainter.normalize(widget.amplitudes);
    if (listEquals(normalized, _target) &&
        oldWidget.animationDuration == widget.animationDuration) {
      return;
    }
    _start = _resizeList(_displayed, normalized.length);
    _target = _resizeList(normalized, normalized.length);
    if (_target.isEmpty) {
      setState(() {
        _displayed = const [];
      });
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTick)
      ..dispose();
    super.dispose();
  }

  void _handleTick() {
    final t = Curves.easeOut.transform(_controller.value);
    final result = <double>[];
    final length = _target.length;
    final current = _resizeList(_start, length);
    for (var i = 0; i < length; i++) {
      final interpolated = lerpDouble(current[i], _target[i], t) ?? _target[i];
      result.add(interpolated);
    }
    setState(() {
      _displayed = result;
    });
  }

  List<double> _resizeList(List<double> source, int length) {
    if (length == 0) {
      return const [];
    }
    if (source.length == length) {
      return List<double>.from(source);
    }
    final result = List<double>.filled(length, 0);
    for (var i = 0; i < length; i++) {
      result[i] = i < source.length ? source[i] : 0;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.backgroundColor),
        child: CustomPaint(
          painter: WaveformPainter(
            amplitudes: _displayed,
            barColor: widget.barColor,
            barWidth: widget.barWidth,
            spacing: widget.spacing,
          ),
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  const WaveformPainter({
    required this.amplitudes,
    required this.barColor,
    required this.barWidth,
    required this.spacing,
  });

  final List<double> amplitudes;
  final Color barColor;
  final double barWidth;
  final double spacing;

  static List<double> normalize(List<double> values) {
    return values
        .map((value) {
          final safeValue = value.isNaN ? 0.0 : value;
          return safeValue.clamp(0.0, 1.0).toDouble();
        })
        .toList(growable: false);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = barColor
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    final totalWidth =
        amplitudes.length * barWidth + (amplitudes.length - 1) * spacing;
    final startX = math.max((size.width - totalWidth) / 2, 0.0);
    final maxHeight = size.height;

    for (var i = 0; i < amplitudes.length; i++) {
      final normalized = amplitudes[i].clamp(0.0, 1.0).toDouble();
      final barHeight = normalized * maxHeight;
      final x = startX + i * (barWidth + spacing);
      final top = (maxHeight - barHeight) / 2;
      canvas.drawLine(Offset(x, top), Offset(x, top + barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.barColor != barColor ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.spacing != spacing;
  }
}

class WaveformStream extends StatelessWidget {
  const WaveformStream({
    super.key,
    required this.stream,
    required this.initialAmplitudes,
    this.height = 220,
    this.barColor = Colors.black,
    this.barWidth = 3,
    this.spacing = 6,
    this.backgroundColor = Colors.transparent,
    this.animationDuration = const Duration(milliseconds: 120),
  });

  final Stream<List<double>> stream;
  final List<double> initialAmplitudes;
  final double height;
  final Color barColor;
  final double barWidth;
  final double spacing;
  final Color backgroundColor;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<double>>(
      stream: stream,
      initialData: initialAmplitudes,
      builder: (context, snapshot) {
        final amplitudes = snapshot.data ?? const <double>[];
        return WaveformWidget(
          amplitudes: amplitudes,
          height: height,
          barColor: barColor,
          barWidth: barWidth,
          spacing: spacing,
          backgroundColor: backgroundColor,
          animationDuration: animationDuration,
        );
      },
    );
  }
}
