import 'package:flutter/material.dart';

class TextDisplayWidget extends StatelessWidget {
  const TextDisplayWidget({
    super.key,
    required this.transcript,
    required this.activeWordIndex,
    this.isCursorVisible = true,
    this.scrollController,
  });

  final List<String> transcript;
  final int activeWordIndex;
  final bool isCursorVisible;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 227, 227, 198),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        controller: scrollController,
        child: _buildRichText(),
      ),
    );
  }

  Widget _buildRichText() {
    final spans = <InlineSpan>[];

    for (var i = 0; i < transcript.length; i++) {
      final word = transcript[i];

      if (i == activeWordIndex) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    word,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isCursorVisible) const SizedBox(width: 4),
                  if (isCursorVisible) const _BlinkingCursor(),
                ],
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: '$word ', style: _defaultTextStyle));
      }
    }

    return RichText(
      text: TextSpan(children: spans, style: _defaultTextStyle),
    );
  }

  TextStyle get _defaultTextStyle => const TextStyle(
    fontSize: 20,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  static const Duration blinkPeriod = Duration(milliseconds: 500);

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _BlinkingCursor.blinkPeriod,
      reverseDuration: _BlinkingCursor.blinkPeriod,
      lowerBound: 0.2,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(width: 2, height: 20, color: Colors.white),
    );
  }
}
