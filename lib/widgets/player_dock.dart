import 'dart:io';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
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

class _PlayerDockState extends State<PlayerDock> with TickerProviderStateMixin, WidgetsBindingObserver {
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

    WidgetsBinding.instance.addObserver(this);
    widget.isOpenNotifier.addListener(_syncWithExternalState);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // The audio handler can continue changing media while iOS suspends UI
      // rendering. Force the first live frame after resume to read the
      // handler's retained MediaItem directly.
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

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

        final currentSheetRect = Rect.lerp(miniPillRect, fullSheetRect, morph)!;

        final currentRadius = lerpDouble(miniPillRect.height / 2, AppGeometry.deviceCornerRadius, morph)!;

        double snap(double value) {
          return (value * devicePixelRatio).round() / devicePixelRatio;
        }

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

        // Stable decode size.
        //
        // This is based on the FULL player artwork size and therefore
        // does not change while mini -> full -> mini animates.
        final artworkDecodeSize = (fullArtSize * devicePixelRatio).round();

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
                    child: StreamBuilder<MediaItem?>(
                      stream: PlayerState.mediaItemStream,
                      initialData: PlayerState.currentMediaItem,
                      builder: (context, snapshot) {
                        // The retained handler value wins over a stale
                        // StreamBuilder snapshot on the first frame after
                        // resume/background transitions.
                        final item = PlayerState.currentMediaItem ?? snapshot.data;
                        final song = PlayerState.songForMediaItem(item);
                        final artworkUri = item?.artUri;

                        final bytes = song?.albumArt;
                        final ImageProvider? imageProvider;

                        if (bytes != null && bytes.isNotEmpty) {
                          // Zero filesystem round-trip for Kosh itself while
                          // retaining the same fixed full-player decode size
                          // that prevents mini/full morph re-decodes.
                          imageProvider = ResizeImage(
                            MemoryImage(bytes),
                            width: artworkDecodeSize,
                            height: artworkDecodeSize,
                          );
                        } else if (artworkUri != null) {
                          imageProvider = ResizeImage(
                            FileImage(File.fromUri(artworkUri)),
                            width: artworkDecodeSize,
                            height: artworkDecodeSize,
                          );
                        } else {
                          imageProvider = null;
                        }

                        return AlbumArt(
                          key: ValueKey(item?.id),
                          radius: currentArtRadius,
                          imageProvider: imageProvider,
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
                    child: StreamBuilder<MediaItem?>(
                      stream: PlayerState.mediaItemStream,
                      initialData: PlayerState.currentMediaItem,
                      builder: (context, snapshot) {
                        final item = PlayerState.currentMediaItem ?? snapshot.data;
                        return _SharedSongInfo(progress: morph, item: item);
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
  const _SharedSongInfo({required this.progress, required this.item});

  final double progress;
  final MediaItem? item;

  @override
  Widget build(BuildContext context) {
    return SongInfo(
      title: item?.title ?? 'Not Playing',
      artist: item?.artist ?? (progress < 0.5 ? 'Tap a song to play' : '-'),
      format: item?.extras?['format'] as String?,
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
