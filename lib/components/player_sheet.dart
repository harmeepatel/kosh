import 'package:flutter/material.dart';
import 'package:kosh/components/music_player_placeholder.dart';
import 'package:kosh/style.dart';

class PlayerSheet extends StatefulWidget {
  const PlayerSheet({super.key, required this.isOpenNotifier});

  final ValueNotifier<bool> isOpenNotifier;

  @override
  State<PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<PlayerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppTiming.md,
    value: widget.isOpenNotifier.value ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    widget.isOpenNotifier.addListener(_syncWithExternalState);
  }

  @override
  void dispose() {
    widget.isOpenNotifier.removeListener(_syncWithExternalState);
    _controller.dispose();
    super.dispose();
  }

  void _syncWithExternalState() {
    if (_controller.isAnimating) return;
    final target = widget.isOpenNotifier.value ? 1.0 : 0.0;
    _controller.animateTo(target, curve: Curves.easeOutCubic);
  }

  void _onDragStart(DragStartDetails details) {
    _controller.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final delta = details.primaryDelta ?? 0;
    _controller.value = (_controller.value - delta / screenHeight).clamp(
      0.0,
      1.0,
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final open =
        velocity < -300 || (velocity <= 300 && _controller.value >= 0.5);
    _settle(open);
  }

  void _settle(bool open) {
    _controller.animateTo(open ? 1.0 : 0.0, curve: Curves.easeOutCubic);
    widget.isOpenNotifier.value = open;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final dy = screenHeight * (1 - _controller.value);
        return Positioned.fill(
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
      child: GestureDetector(
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppGeometry.deviceCornerRadius)),
          child: const Material(
            color: Colors.black,
            child: MusicPlayerPlaceholder(),
          ),
        ),
      ),
    );
  }
}
