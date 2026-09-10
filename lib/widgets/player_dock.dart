import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kosh/player/song.dart';
import 'package:kosh/player/state.dart';
import 'package:kosh/style/style.dart';
import 'package:kosh/widgets/album_art.dart';
import 'package:kosh/widgets/frosted_glass.dart';
import 'package:kosh/widgets/full_player.dart';
import 'package:kosh/widgets/mini_player_content.dart';
import 'package:kosh/widgets/song_info.dart';

class PlayerDock extends StatefulWidget {
  const PlayerDock({super.key, required this.isOpenNotifier, this.isLeftHanded = false});

  final ValueNotifier<bool> isOpenNotifier;
  final bool isLeftHanded;

  @override
  State<PlayerDock> createState() => _PlayerDockState();
}

class _PlayerDockState extends State<PlayerDock> with TickerProviderStateMixin {
  static const double _draggableDistance = 0.7;

  late final AnimationController _position = AnimationController(
    vsync: this,
    duration: AppTiming.lg,
    value: widget.isOpenNotifier.value ? 1.0 : 0.0,
  );

  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: AppTiming.lg,
    value: widget.isOpenNotifier.value ? 1.0 : 0.0,
  );

  bool _isDragging = false;
  bool _holdFullSize = false;

  @override
  void initState() {
    super.initState();
    widget.isOpenNotifier.addListener(_syncWithExternalState);
  }

  @override
  void dispose() {
    widget.isOpenNotifier.removeListener(_syncWithExternalState);
    _position.dispose();
    _morph.dispose();
    super.dispose();
  }

  void _syncWithExternalState() {
    if (_isDragging) return;
    _animateTo(widget.isOpenNotifier.value);
  }

  void _onTap() {
    if (_position.value > 0) return;
    widget.isOpenNotifier.value = true;
  }

  void _onDragStart(DragStartDetails _) {
    _position.stop();
    _morph.stop();

    _isDragging = true;
    _holdFullSize = _morph.value > 0.5;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dragDistance = MediaQuery.sizeOf(context).height * _draggableDistance;

    final delta = details.primaryDelta ?? 0.0;

    _position.value = (_position.value - delta / dragDistance).clamp(0.0, 1.0);

    if (!_holdFullSize) {
      _morph.value = _position.value;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;

    final shouldOpen = velocity < -300 || (velocity <= 300 && _position.value >= 0.5);

    _isDragging = false;
    _holdFullSize = false;

    widget.isOpenNotifier.value = shouldOpen;
    _animateTo(shouldOpen);
  }

  void _onDragCancel() {
    _isDragging = false;
    _holdFullSize = false;

    _animateTo(widget.isOpenNotifier.value);
  }

  void _animateTo(bool open) {
    final target = open ? 1.0 : 0.0;

    _position.animateTo(target, curve: Curves.easeOutCubic);

    _morph.animateTo(target, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final topSafeArea = MediaQuery.paddingOf(context).top;
    final bottomMargin = AppInset.bottomMargin(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_position, _morph]),
      builder: (context, _) {
        final position = _position.value;
        final morph = _morph.value;

        // -----------------------------------------------------------------
        // MINI PLAYER GEOMETRY
        // -----------------------------------------------------------------

        const navSize = AppAlbumCover.sm;
        const gap = AppSpacing.xs;

        final miniPillWidth = screen.width - (AppInset.screenEdgePadding * 2) - navSize - gap;

        final miniPillLeft = widget.isLeftHanded
            ? AppInset.screenEdgePadding + navSize + gap
            : AppInset.screenEdgePadding;

        final miniPillRect = Rect.fromLTWH(
          miniPillLeft,
          screen.height - bottomMargin - navSize,
          miniPillWidth,
          navSize,
        );

        const miniArtSize = AppAlbumCover.xs;

        final miniArtRect = Rect.fromLTWH(
          AppSpacing.lg,
          (miniPillRect.height - miniArtSize) / 2,
          miniArtSize,
          miniArtSize,
        );

        final miniTitleLeft = AppSpacing.lg + miniArtSize + AppSpacing.md;

        const miniControlsWidth = (kMinInteractiveDimension * 2) + (AppSpacing.md * 2);

        final miniTitleRect = Rect.fromLTWH(
          miniTitleLeft,
          (miniPillRect.height - AppAlbumCover.sm) / 2,
          (miniPillRect.width - miniTitleLeft - miniControlsWidth).clamp(0.0, double.infinity),
          AppAlbumCover.sm,
        );

        // -----------------------------------------------------------------
        // FULL PLAYER GEOMETRY
        // -----------------------------------------------------------------

        // Only position controls this while dragging.
        //
        // Width stays screen.width until morph begins after release.
        final topOffset = (1.0 - position) * (screen.height * _draggableDistance);
        final fullSheetRect = Rect.fromLTWH(0, topOffset, screen.width, screen.height);
        final fullArtSize = screen.width - (horizontalPadding * 1.2);
        final fullArtTop = topSafeArea + AppSpacing.md + AppSpacing.xs3 + AppSpacing.lg;
        final fullArtRect = Rect.fromLTWH((screen.width - fullArtSize) / 2, fullArtTop, fullArtSize, fullArtSize);
        const fullPlayerActionsWidth = kMinInteractiveDimension * 2;

        final fullTitleRect = Rect.fromLTWH(
          horizontalPadding,
          fullArtTop + fullArtSize + AppSpacing.lg,
          (screen.width - (horizontalPadding * 2) - fullPlayerActionsWidth).clamp(0.0, double.infinity),
          AppAlbumCover.sm,
        );

        // -----------------------------------------------------------------
        // MORPH
        // -----------------------------------------------------------------

        // This is the important change:
        //
        // position != morph.
        //
        // During a downward drag from the full player:
        //
        //     position -> decreases
        //     morph    -> stays at 1
        //
        // Therefore the sheet moves down but remains full width.
        //
        // Once released, morph animates toward zero and the card finally
        // transforms into the mini player.
        final currentSheetRect = Rect.lerp(miniPillRect, fullSheetRect, morph)!;

        final currentRadius = lerpDouble(miniPillRect.height / 2, AppGeometry.deviceCornerRadius, morph)!;

        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        double snap(double value) => (value * devicePixelRatio).round() / devicePixelRatio;
        final lerpedArtRect = Rect.lerp(miniArtRect, fullArtRect, morph)!;
        final currentArtRect = Rect.fromLTWH(
          snap(lerpedArtRect.left),
          snap(lerpedArtRect.top),
          snap(lerpedArtRect.width),
          snap(lerpedArtRect.height),
        );

        final currentArtRadius = lerpDouble(AppRadii.sm, AppRadii.lg, morph)!;

        final currentTitleRect = Rect.lerp(miniTitleRect, fullTitleRect, morph)!;

        final pillOpacity = (1.0 - (morph / 0.3)).clamp(0.0, 1.0);

        final sheetOpacity = (morph / 0.3).clamp(0.0, 1.0);

        final borderAlpha = lerpDouble(AppGeometry.borderOpacity, 0.0, morph)!;

        // -----------------------------------------------------------------
        // PLAYER
        // -----------------------------------------------------------------

        return Positioned.fromRect(
          rect: currentSheetRect,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _onTap,
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            onVerticalDragCancel: _onDragCancel,
            child: FrostedGlassShell(
              radius: currentRadius,
              borderAlpha: borderAlpha,
              child: Stack(
                children: [
                  // -------------------------------------------------------
                  // MINI PLAYER CONTROLS
                  // -------------------------------------------------------

                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: miniPillRect.height,
                      child: Opacity(
                        opacity: pillOpacity,
                        child: IgnorePointer(ignoring: pillOpacity < 0.5, child: const MiniPlayerContent()),
                      ),
                    ),
                  ),

                  // -------------------------------------------------------
                  // FULL PLAYER
                  // -------------------------------------------------------
                  Opacity(
                    opacity: sheetOpacity,
                    child: IgnorePointer(
                      ignoring: sheetOpacity < 0.5,
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minWidth: 0,
                        maxWidth: double.infinity,
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: SizedBox(
                          width: screen.width,
                          height: screen.height,
                          child: FullPlayer(progress: morph),
                        ),
                      ),
                    ),
                  ),

                  // -------------------------------------------------------
                  // SHARED ALBUM ART
                  // -------------------------------------------------------
                  Positioned.fromRect(
                    rect: currentArtRect,
                    child: ValueListenableBuilder<Song?>(
                      valueListenable: PlayerState.currentSong,
                      builder: (context, song, _) {
                        return AlbumArt(
                          radius: currentArtRadius,
                          imageBytes: song?.albumArt,
                          fallbackIconColor: Colors.white54,
                          showBorder: false,
                        );
                      },
                    ),
                  ),

                  // -------------------------------------------------------
                  // SHARED SONG INFO
                  // -------------------------------------------------------
                  Positioned.fromRect(
                    rect: currentTitleRect,
                    child: ValueListenableBuilder<Song?>(
                      valueListenable: PlayerState.currentSong,
                      builder: (context, song, _) {
                        return _SharedSongInfo(progress: morph, song: song);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SharedSongInfo extends StatelessWidget {
  const _SharedSongInfo({required this.progress, required this.song});

  final double progress;
  final Song? song;

  @override
  Widget build(BuildContext context) {
    return SongInfo(
      title: song?.title ?? 'Not Playing',
      artist: song?.artist ?? (progress < 0.5 ? 'Tap a song to play' : '-'),
      format: song?.format,
      showFormat: false,
      titleStyle: TextStyle(
        color: AppColors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: lerpDouble(AppSpacing.md, AppSpacing.xl, progress)!,
        height: 1.1,
      ),
      artistStyle: TextStyle(
        color: AppColors.primaryText.withValues(alpha: lerpDouble(0.7, 0.65, progress)!),
        fontSize: lerpDouble(AppSpacing.sm, AppSpacing.lg, progress)!,
        height: 1.1,
      ),
      spacing: lerpDouble(AppSpacing.xs5, AppSpacing.xs3, progress)!,
    );
  }
}
