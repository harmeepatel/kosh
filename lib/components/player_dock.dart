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
    // Physics constant for flick detection, kept hardcoded
    final open =
        velocity < -300 || (velocity <= 300 && _controller.value >= 0.5);
    _controller.animateTo(open ? 1.0 : 0.0, curve: Curves.easeOutBack);
    widget.isOpenNotifier.value = open;
  }

  Rect _pillRect(Size screen, bool navVisible) {
    // Standardized spacing and insets
    final bottom = navVisible
        ? AppInset.bottomNavHeight + Spacing.xs
        : AppGeometry.bottomPadding;

    return Rect.fromLTRB(
      AppGeometry.bottomPadding,
      screen.height - bottom - AppGeometry.miniPlayerHeight,
      screen.width - AppGeometry.bottomPadding,
      screen.height - bottom,
    );
  }

  Rect _sheetRect(Size screen) =>
      Rect.fromLTWH(0, 0, screen.width, screen.height);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return ValueListenableBuilder<bool>(
      valueListenable: widget.isBottomBarVisibleNotifier,
      builder: (context, navVisible, _) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final pill = _pillRect(screen, navVisible);
            final sheet = _sheetRect(screen);

            final movingRect = Rect.lerp(pill, sheet, t)!;
            final startRadius = pill.height / 2;

            // Standardized device corner radius
            final radius = lerpDouble(
              startRadius,
              AppGeometry.deviceCornerRadius,
              t,
            )!;

            // Animation timing constants (0.3, 0.7 thresholds) kept hardcoded
            final pillContentOpacity = (1 - t * 3).clamp(0.0, 1.0);
            final sheetContentOpacity = ((t - 0.7) / 0.3).clamp(0.0, 1.0);

            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _GooeyPainter(
                        pillRect: pill,
                        movingRect: movingRect,
                        startRadius: startRadius,
                        radius: radius,
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: movingRect,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _onTap,
                    onVerticalDragStart: _onDragStart,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
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
              ],
            );
          },
        );
      },
    );
  }
}

class _GooeyPainter extends CustomPainter {
  _GooeyPainter({
    required this.pillRect,
    required this.movingRect,
    required this.startRadius,
    required this.radius,
  });

  final Rect pillRect;
  final Rect movingRect;
  final double startRadius;
  final double radius;

  // Mathematically coupled gooey constants (Do not replace with Spacing variables)
  static final Paint _filterPaint = Paint()
    ..colorFilter = const ColorFilter.matrix(<double>[
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      20,
      -2400,
    ]);

  static final Paint _blurPaint = Paint()
    ..color = const Color(0xFF1C1C1E)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

  @override
  void paint(Canvas canvas, Size size) {
    // Standardized buffer expansion using deviceCornerRadius instead of hardcoded 50
    final layerBounds = pillRect
        .expandToInclude(movingRect)
        .inflate(AppGeometry.deviceCornerRadius);

    canvas.saveLayer(layerBounds, _filterPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, Radius.circular(startRadius)),
      _blurPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(movingRect, Radius.circular(radius)),
      _blurPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GooeyPainter oldDelegate) {
    return pillRect != oldDelegate.pillRect ||
        movingRect != oldDelegate.movingRect ||
        radius != oldDelegate.radius;
  }
}
