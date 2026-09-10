import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_symbols/flutter_cupertino_symbols.dart';
import 'package:kosh/player/state.dart';
import 'package:kosh/style/style.dart';

const horizontalPadding = AppSpacing.lg;

class FullPlayer extends StatelessWidget {
  const FullPlayer({super.key, this.progress = 1.0});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final handleOpacity = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<MediaItem?>(
        stream: PlayerState.mediaItemStream,
        initialData: PlayerState.currentMediaItem,
        builder: (context, snapshot) {
          final item = snapshot.data;

          return Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // Handle container
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
                      child: Opacity(
                        opacity: handleOpacity,
                        child: Container(
                          width: MediaQuery.sizeOf(context).width / 5,
                          height: AppSpacing.xs5,
                          decoration: ShapeDecoration(
                            color: Colors.white30,
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                cornerRadius: AppRadii.xs,
                                cornerSmoothing: AppRadii.cornerSmoothing,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const _AlbumArtCover(),
                    const _SongDetails(),

                    _PlaybackProgress(mediaType: item?.extras?['format'] as String?),

                    const _PlaybackControls(),
                    const _VolumeControls(),
                    const _BottomActions(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlbumArtCover extends StatelessWidget {
  const _AlbumArtCover();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width - (horizontalPadding * 1.2);
    return SizedBox(width: size, height: size);
  }
}

class _SongDetails extends StatelessWidget {
  const _SongDetails();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppAlbumCover.sm,
      margin: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Spacer for floating shared song info title
          const Expanded(child: SizedBox.expand()),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: AppAlbumCover.xs, minHeight: AppAlbumCover.xs),
            onPressed: () {},
            icon: const Icon(SFSymbols.suit_heart, color: Colors.white, size: AppIcon.md),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: AppAlbumCover.xs, minHeight: AppAlbumCover.xs),
            onPressed: () {},
            icon: const Icon(SFSymbols.ellipsis, color: Colors.white, size: AppIcon.md),
          ),
        ],
      ),
    );
  }
}

class _PlaybackProgress extends StatefulWidget {
  const _PlaybackProgress({this.mediaType});

  final String? mediaType;

  @override
  State<_PlaybackProgress> createState() => _PlaybackProgressState();
}

class _PlaybackProgressState extends State<_PlaybackProgress> {
  double? _dragFraction;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlaybackTimeline>(
      valueListenable: PlayerState.timeline,
      builder: (context, timeline, _) {
        final totalUs = timeline.duration.inMicroseconds;
        final hasDuration = totalUs > 0;

        final engineFraction = hasDuration ? (timeline.position.inMicroseconds / totalUs).clamp(0.0, 1.0) : 0.0;

        final displayedFraction = (_dragFraction ?? engineFraction).clamp(0.0, 1.0);

        final rawDisplayedPosition = _dragFraction == null || !hasDuration
            ? timeline.position
            : Duration(microseconds: (totalUs * displayedFraction).round());

        // Drive BOTH labels from the same integer-second clock.
        // This guarantees elapsed and remaining change on the same rebuild.
        final totalSeconds = hasDuration
            ? (timeline.duration.inMicroseconds / Duration.microsecondsPerSecond).ceil()
            : 0;

        final elapsedSeconds = hasDuration
            ? (rawDisplayedPosition.inMicroseconds / Duration.microsecondsPerSecond).floor().clamp(0, totalSeconds)
            : 0;

        final remainingSeconds = (totalSeconds - elapsedSeconds).clamp(0, totalSeconds);

        final displayedPosition = Duration(seconds: elapsedSeconds);
        final remaining = Duration(seconds: remainingSeconds);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              _SeekBar(
                value: displayedFraction,
                enabled: hasDuration,
                onScrubStart: (value) {
                  setState(() {
                    _dragFraction = value;
                  });
                },
                onScrubUpdate: (value) {
                  setState(() {
                    _dragFraction = value;
                  });
                },
                onScrubEnd: (value) {
                  // PlayerState publishes the requested position immediately,
                  // so clearing local drag state here does not cause snap-back.
                  setState(() {
                    _dragFraction = null;
                  });

                  PlayerState.seekFraction(value);
                },
              ),
              _ProgressLabels(position: displayedPosition, remaining: remaining, mediaType: widget.mediaType),
            ],
          ),
        );
      },
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({
    required this.value,
    required this.enabled,
    required this.onScrubStart,
    required this.onScrubUpdate,
    required this.onScrubEnd,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onScrubStart;
  final ValueChanged<double> onScrubUpdate;
  final ValueChanged<double> onScrubEnd;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  static const double _idleHeight = 6.0;
  static const double _activeHeight = 10.0;
  static const double _hitHeight = 32.0;

  bool _isScrubbing = false;
  double _lastValue = 0.0;

  double _fractionForDx(double dx, double width) {
    if (width <= 0) return 0.0;
    return (dx / width).clamp(0.0, 1.0);
  }

  void _start(PointerDownEvent event, double width) {
    if (!widget.enabled) return;

    _lastValue = _fractionForDx(event.localPosition.dx, width);

    setState(() {
      _isScrubbing = true;
    });

    widget.onScrubStart(_lastValue);
  }

  void _update(PointerMoveEvent event, double width) {
    if (!_isScrubbing || !widget.enabled) return;

    final next = _fractionForDx(event.localPosition.dx, width);
    if (next == _lastValue) return;

    _lastValue = next;
    widget.onScrubUpdate(next);
  }

  void _end() {
    if (!_isScrubbing) return;

    final value = _lastValue;

    setState(() {
      _isScrubbing = false;
    });

    widget.onScrubEnd(value);
  }

  void _cancel() {
    if (!_isScrubbing) return;

    final value = _lastValue;

    setState(() {
      _isScrubbing = false;
    });

    widget.onScrubEnd(value);
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.value.clamp(0.0, 1.0);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    return SizedBox(
      height: _hitHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => _start(event, width),
            onPointerMove: (event) => _update(event, width),
            onPointerUp: (_) => _end(),
            onPointerCancel: (_) => _cancel(),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: _isScrubbing ? _activeHeight : _idleHeight,
                child: CustomPaint(
                  painter: _SeekBarPainter(progress: progress, devicePixelRatio: devicePixelRatio),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SeekBarPainter extends CustomPainter {
  const _SeekBarPainter({required this.progress, required this.devicePixelRatio});

  final double progress;
  final double devicePixelRatio;

  static const Color _playedColor = Colors.white70;
  static const Color _remainingColor = Colors.white24;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final radius = size.height / 2;
    final track = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));

    final remainingPaint = Paint()
      ..color = _remainingColor
      ..isAntiAlias = true;

    final playedPaint = Paint()
      ..color = _playedColor
      ..isAntiAlias = false;

    // Draw the complete-duration track first.
    canvas.drawRRect(track, remainingPaint);

    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;

    // Only true 100% is allowed to cover the right cap.
    if (p >= 1.0) {
      canvas.drawRRect(track, playedPaint);
      return;
    }

    // Convert progress to an exact physical-pixel boundary. Flooring rather
    // than rounding guarantees the played portion never visually gets ahead
    // of the real playback clock.
    final rawEdge = size.width * p;
    var playedEdge = (rawEdge * devicePixelRatio).floorToDouble() / devicePixelRatio;

    // A capsule's rounded right cap can visually swallow a very small
    // remaining segment. Keep enough of that cap visible to communicate that
    // playback has NOT actually finished. This affects only the final few
    // visual pixels; the underlying progress/seek math remains exact.
    final onePhysicalPixel = 1.0 / devicePixelRatio;
    final minVisibleRemaining = math.max(onePhysicalPixel, math.min(radius, 2.0));

    playedEdge = math.min(playedEdge, math.max(0.0, size.width - minVisibleRemaining));

    if (playedEdge <= 0) return;

    canvas.save();
    canvas.clipRRect(track);

    // The played/unplayed boundary is intentionally a plain vertical edge:
    // no thumb, knob, radius, separator, gradient, or center decoration.
    canvas.drawRect(Rect.fromLTWH(0, 0, playedEdge, size.height), playedPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SeekBarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.devicePixelRatio != devicePixelRatio;
  }
}

class _ProgressLabels extends StatelessWidget {
  const _ProgressLabels({required this.position, required this.remaining, required this.mediaType});

  final Duration position;
  final Duration remaining;
  final String? mediaType;

  static const _secondaryText = TextStyle(color: Colors.white54, fontSize: AppSpacing.sm, fontWeight: FontWeight.w500);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.lg,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Time labels occupy the full row independently of the center badge.
          // Their changing text widths can therefore never move the badge.
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_formatElapsed(position), style: _secondaryText, maxLines: 1),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('-${_formatRemaining(remaining)}', style: _secondaryText, maxLines: 1),
                ),
              ),
            ],
          ),

          // Geometrically pinned to the exact horizontal center.
          if (mediaType != null)
            IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs5, vertical: AppSpacing.xs6),
                decoration: ShapeDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: AppRadii.xs,
                      cornerSmoothing: AppRadii.cornerSmoothing,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(SFSymbols.waveform, color: Colors.white70, size: AppRadii.md),
                    const SizedBox(width: AppSpacing.xs5),
                    Text(
                      mediaType!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: AppSpacing.xs2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatElapsed(Duration duration) {
  return _formatSeconds(duration.inSeconds);
}

String _formatRemaining(Duration duration) {
  return _formatSeconds(duration.inSeconds);
}

String _formatSeconds(int totalSeconds) {
  final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
  final hours = safeSeconds ~/ 3600;
  final minutes = (safeSeconds % 3600) ~/ 60;
  final seconds = safeSeconds % 60;

  if (hours > 0) {
    return '$hours:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  return '$minutes:'
      '${seconds.toString().padLeft(2, '0')}';
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: PlayerState.skipToPrevious,
          iconSize: AppIcon.md,
          icon: const Icon(SFSymbols.backward_fill, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.xxxl),
        ValueListenableBuilder<bool>(
          valueListenable: PlayerState.isPlaying,
          builder: (context, isPlaying, _) {
            return IconButton(
              onPressed: PlayerState.togglePlayPause,
              iconSize: AppIcon.lg,
              icon: Icon(isPlaying ? SFSymbols.pause_fill : SFSymbols.play_fill, color: Colors.white),
            );
          },
        ),
        const SizedBox(width: AppSpacing.xxxl),
        IconButton(
          onPressed: PlayerState.skipToNext,
          iconSize: AppIcon.md,
          icon: const Icon(SFSymbols.forward_fill, color: Colors.white),
        ),
      ],
    );
  }
}

class _VolumeControls extends StatelessWidget {
  const _VolumeControls();

  @override
  Widget build(BuildContext context) {
    const double iconSize = AppAlbumCover.xs;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          const Icon(SFSymbols.speaker_fill, color: Colors.white70, size: iconSize),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: AppRadii.sm,
                thumbShape: SliderComponentShape.noThumb,
                tickMarkShape: SliderTickMarkShape.noTickMark,
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.white70,
                inactiveTrackColor: Colors.white24,
              ),
              child: Slider(value: 0.58, onChanged: (_) {}),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(SFSymbols.speaker_wave_3_fill, color: Colors.white70, size: iconSize),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    const double size = AppIcon.md;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(SFSymbols.text_bubble, color: Colors.white70, size: size),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(SFSymbols.airpodspro, color: Colors.white70, size: size),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(SFSymbols.list_bullet, color: Colors.white70, size: size),
        ),
      ],
    );
  }
}
