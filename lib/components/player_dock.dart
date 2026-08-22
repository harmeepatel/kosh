import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kosh/components/mini_player_content.dart';
import 'package:kosh/components/music_player_placeholder.dart';
import 'package:kosh/style.dart';

import 'frosted_glass.dart';

class PlayerDock extends StatefulWidget {
  const PlayerDock({
    super.key,
    required this.isOpenNotifier,
    required this.isBottomBarVisibleNotifier,
  });

  final ValueNotifier<bool> isOpenNotifier;
  final ValueListenable<bool> isBottomBarVisibleNotifier;

  @override
  State<PlayerDock> createState() => _PlayerDockState();
}

class _PlayerDockState extends State<PlayerDock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppTiming.lg,
    value: widget.isOpenNotifier.value ? 1.0 : 0.0,
  );

  final double _draggableDistance = 0.7; // Stops sliding straight at 70%

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
    _controller.animateTo(
      widget.isOpenNotifier.value ? 1.0 : 0.0,
      curve: Curves.easeOutCubic,
    );
  }

  void _onTap() {
    if (_controller.value != 0) return;
    widget.isOpenNotifier.value = true;
    _controller.animateTo(1.0, curve: Curves.easeOutCubic);
  }

  void _onDragStart(DragStartDetails details) {
    _controller.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final delta = details.primaryDelta ?? 0;

    // The total draggable distance is now 70% of the screen height
    final travelDistance = screenHeight * _draggableDistance;

    _controller.value = (_controller.value - delta / travelDistance).clamp(
      0.0,
      1.0,
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final isFlickUp = velocity < -300;
    final isPastThreshold = velocity <= 300 && _controller.value >= 0.5;
    final shouldOpen = isFlickUp || isPastThreshold;

    widget.isOpenNotifier.value = shouldOpen;
    _controller.animateTo(shouldOpen ? 1.0 : 0.0, curve: Curves.easeOutCubic);
  }

  Rect _getPillRect(
    Size screen,
    double actualNavHeight,
    double navProgress,
    double bottomMargin,
  ) {
    final navHeight = AppInset.navBarHeight();
    final gap = AppInset.screenEdgePadding;
    final collapsedNavWidth = navHeight;

    final collapsedRect = Rect.fromLTWH(
      AppInset.screenEdgePadding + collapsedNavWidth + gap,
      screen.height - bottomMargin - navHeight,
      screen.width - (AppInset.screenEdgePadding * 2) - collapsedNavWidth - gap,
      navHeight,
    );

    final expandedRect = Rect.fromLTWH(
      AppInset.screenEdgePadding,
      screen.height - actualNavHeight - navHeight - gap,
      screen.width - (AppInset.screenEdgePadding * 2),
      navHeight,
    );

    return Rect.lerp(collapsedRect, expandedRect, navProgress)!;
  }

  _DockLayout _calculateLayout({
    required double t,
    required Rect pill,
    required Size screen,
  }) {
    final sheetRadius = AppGeometry.deviceCornerRadius;
    final pillRadius = pill.height / 2;

    const morphThreshold = 0.3;

    if (t >= morphThreshold) {
      final slideProgress = (t - morphThreshold) / (1.0 - morphThreshold);
      final maxOffset = screen.height * _draggableDistance;
      final topOffset = (1.0 - slideProgress) * maxOffset;

      return _DockLayout(
        rect: Rect.fromLTWH(0, topOffset, screen.width, screen.height),
        radius: sheetRadius,
        pillOpacity: 0.0,
        sheetOpacity: 1.0,
        borderAlpha: 0.0,
      );
    } else {
      final morphProgress = t / morphThreshold;

      final slideEndRect = Rect.fromLTWH(
        0,
        screen.height * _draggableDistance,
        screen.width,
        screen.height,
      );

      return _DockLayout(
        rect: Rect.lerp(pill, slideEndRect, morphProgress)!,
        radius: lerpDouble(pillRadius, sheetRadius, morphProgress)!,
        pillOpacity: (1.0 - morphProgress).clamp(0.0, 1.0),
        sheetOpacity: morphProgress.clamp(0.0, 1.0),
        borderAlpha: lerpDouble(AppGeometry.borderOpacity, 0.0, morphProgress)!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final actualNavHeight = AppInset.bottomNavHeightWithPad(context);
    final bottomMargin = AppInset.bottomMargin(context);

    return ValueListenableBuilder<bool>(
      valueListenable: widget.isBottomBarVisibleNotifier,
      builder: (context, navVisible, _) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: navVisible ? 1.0 : 0.0),
          duration: AppTiming.md,
          curve: Curves.easeOutCubic,
          builder: (context, navProgress, _) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final pill = _getPillRect(
                  screen,
                  actualNavHeight,
                  navProgress,
                  bottomMargin,
                );
                final layout = _calculateLayout(
                  t: _controller.value,
                  pill: pill,
                  screen: screen,
                );

                return Positioned.fromRect(
                  rect: layout.rect,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _onTap,
                    onVerticalDragStart: _onDragStart,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: FrostedGlassShell(
                      radius: layout.radius,
                      borderAlpha: layout.borderAlpha,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: pill.height,
                              child: Opacity(
                                opacity: layout.pillOpacity,
                                child: IgnorePointer(
                                  ignoring: layout.pillOpacity < 0.5,
                                  child: const MiniPlayerContent(),
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: layout.sheetOpacity,
                            child: IgnorePointer(
                              ignoring: layout.sheetOpacity < 0.5,
                              child: OverflowBox(
                                alignment: Alignment.topCenter,
                                minWidth: 0,
                                maxWidth: double.infinity,
                                minHeight: 0,
                                maxHeight: double.infinity,
                                child: SizedBox(
                                  width: screen.width,
                                  height: screen.height,
                                  child: const MusicPlayerPlaceholder(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ); // return
              },
            );
          },
        );
      },
    );
  }
}

/// Immutable snapshot of animation attributes for a single frame
class _DockLayout {
  final Rect rect;
  final double radius;
  final double pillOpacity;
  final double sheetOpacity;
  final double borderAlpha;

  const _DockLayout({
    required this.rect,
    required this.radius,
    required this.pillOpacity,
    required this.sheetOpacity,
    required this.borderAlpha,
  });
}
