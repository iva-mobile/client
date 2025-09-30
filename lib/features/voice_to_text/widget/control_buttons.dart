import 'package:flutter/material.dart';

import '../view/voice_to_text_model.dart';

class ControlButtonsRow extends StatelessWidget {
  const ControlButtonsRow({
    super.key,
    required this.state,
    required this.onMicTap,
    required this.onPause,
    required this.onResume,
    required this.onDiscard,
  });

  final RecordingState state;
  final VoidCallback onMicTap;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  bool get _showSecondary =>
      state == RecordingState.recording || state == RecordingState.paused;

  @override
  Widget build(BuildContext context) {
    final leftIcon = state == RecordingState.paused
        ? Icons.play_arrow
        : Icons.pause;
    final leftLabel = state == RecordingState.paused
        ? 'Resume recording'
        : 'Pause recording';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showSecondary
                ? _SecondaryCircularButton(
                    key: const ValueKey('pause_button'),
                    icon: leftIcon,
                    tooltip: leftLabel,
                    onPressed: state == RecordingState.paused
                        ? onResume
                        : onPause,
                  )
                : const SizedBox(width: 64, height: 64),
          ),
          const SizedBox(width: 24),
          _MicButton(
            isRecording: state == RecordingState.recording,
            onPressed: onMicTap,
            state: state,
          ),
          const SizedBox(width: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showSecondary
                ? _SecondaryCircularButton(
                    key: const ValueKey('discard_button'),
                    icon: Icons.delete_outline,
                    tooltip: 'Discard recording',
                    onPressed: onDiscard,
                  )
                : const SizedBox(width: 64, height: 64),
          ),
        ],
      ),
    );
  }
}

class _SecondaryCircularButton extends StatelessWidget {
  const _SecondaryCircularButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
              ),
              child: Center(child: Icon(icon, color: Colors.black87, size: 28)),
            ),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.isRecording,
    required this.onPressed,
    required this.state,
  });

  final bool isRecording;
  final RecordingState state;
  final VoidCallback onPressed;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isRecording) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isRecording && _controller.isAnimating) {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tooltip = switch (widget.state) {
      RecordingState.recording => 'Stop recording',
      RecordingState.paused => 'Stop recording',
      RecordingState.stopped => 'Start new recording',
      RecordingState.idle => 'Start recording',
    };

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 0, 0, 0),
                Color.fromARGB(255, 0, 0, 0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.mic, size: 36, color: Colors.white),
        ),
      ),
    );

    return Semantics(
      label: tooltip,
      button: true,
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isRecording)
              ...List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final progress = (_controller.value + index / 3) % 1;
                    final scale = 1 + (progress * 0.6);
                    final opacity = (1 - progress).clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromARGB(
                            255,
                            87,
                            88,
                            88,
                          ).withValues(alpha: 0.1 * opacity),
                        ),
                      ),
                    );
                  },
                );
              }),
            Tooltip(message: tooltip, child: button),
          ],
        ),
      ),
    );
  }
}
