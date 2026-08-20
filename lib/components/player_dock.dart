import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kosh/components/mini_player_content.dart';
import 'package:kosh/components/music_player_placeholder.dart';
import 'package:kosh/style.dart';

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

  static final _blurFilter = ImageFilter.blur(
    sigmaX: AppBlur.bottomNavBlur,
    sigmaY: AppBlur.bottomNavBlur,
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
    _controller.animateTo(
      widget.isOpenNotifier.value ? 1.0 : 0.0,
      curve: Curves.easeOutBack,
    );
  }

  void _onTap() {
    if (_controller.value != 0) return;
    _controller.animateTo(1.0, curve: Curves.easeOutBack);
    widget.isOpenNotifier.value = true;
  }

  void _onDragStart(DragStartDetails details) => _controller.stop();

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
    final isFlickUp = velocity < -300;
    final isPastThreshold = velocity <= 300 && _controller.value >= 0.5;
    final shouldOpen = isFlickUp || isPastThreshold;

    _controller.animateTo(shouldOpen ? 1.0 : 0.0, curve: Curves.easeOutBack);
    widget.isOpenNotifier.value = shouldOpen;
  }

  Rect _pillRect(
    Size screen,
    double actualNavHeight,
    double navProgress,
    double bottomMargin,
  ) {
    final navHeight = AppInset.navBarHeight();
    final gap = Spacing.md;
    final collapsedNavWidth = navHeight;

    // Side-by-side position (nav collapsed)
    final collapsedRect = Rect.fromLTWH(
      AppInset.screenEdgePadding + collapsedNavWidth + gap,
      screen.height - bottomMargin - navHeight,
      screen.width - (AppInset.screenEdgePadding * 2) - collapsedNavWidth - gap,
      navHeight,
    );

    // Stacked position (nav expanded)
    final expandedRect = Rect.fromLTWH(
      AppInset.screenEdgePadding,
      screen.height - actualNavHeight - navHeight - gap,
      screen.width - (AppInset.screenEdgePadding * 2),
      navHeight,
    );

    return Rect.lerp(collapsedRect, expandedRect, navProgress)!;
  }

  Rect _sheetRect(Size screen) =>
      Rect.fromLTWH(0, 0, screen.width, screen.height);

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
                final t = _controller.value;
                final pill = _pillRect(
                  screen,
                  actualNavHeight,
                  navProgress,
                  bottomMargin,
                );
                final sheet = _sheetRect(screen);

                final movingRect = Rect.lerp(pill, sheet, t)!;
                final startRadius = pill.height / 2;
                final radius = lerpDouble(
                  startRadius,
                  AppGeometry.deviceCornerRadius,
                  t,
                )!;

                final pillContentOpacity = (1 - t * 8).clamp(0.0, 1.0);
                final sheetContentOpacity = t.clamp(0.0, 1.0);

                // Fade out border as it opens to full screen
                final borderAlpha = lerpDouble(0.25, 0.0, t)!;

                return Positioned.fromRect(
                  rect: movingRect,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _onTap,
                    onVerticalDragStart: _onDragStart,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: ClipRRect(
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(radius),
                      child: BackdropFilter(
                        filter: _blurFilter,
                        child: Container(
                          foregroundDecoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: borderAlpha,
                              ),
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(radius),
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0x20000000),
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  height: pill.height,
                                  child: Opacity(
                                    opacity: pillContentOpacity,
                                    child: IgnorePointer(
                                      ignoring: t > 0.3,
                                      child: const MiniPlayerContent(),
                                    ),
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: sheetContentOpacity,
                                child: IgnorePointer(
                                  ignoring: t < 0.7,
                                  child: OverflowBox(
                                    alignment: Alignment.topLeft,
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
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
