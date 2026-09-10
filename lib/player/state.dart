import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:kosh/player/audio_handler.dart';
import 'package:kosh/player/song.dart';

@immutable
class PlaybackTimeline {
  const PlaybackTimeline({required this.position, required this.duration, required this.bufferedPosition});

  const PlaybackTimeline.zero() : position = Duration.zero, duration = Duration.zero, bufferedPosition = Duration.zero;

  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;

  double get progress {
    final totalUs = duration.inMicroseconds;
    if (totalUs <= 0) return 0;

    return (position.inMicroseconds / totalUs).clamp(0.0, 1.0);
  }

  Duration get remaining {
    if (duration <= Duration.zero) return Duration.zero;

    final value = duration - position;
    return value.isNegative ? Duration.zero : value;
  }
}

/// Thin UI-facing adapter around [KoshAudioHandler].
///
/// The handler owns playback state. This class only mirrors that state into
/// ValueNotifiers so the existing Kosh widgets can remain lightweight.
class PlayerState {
  PlayerState._();

  static late KoshAudioHandler _handler;

  static final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  static final ValueNotifier<Duration> position = ValueNotifier<Duration>(Duration.zero);
  static final ValueNotifier<Duration> duration = ValueNotifier<Duration>(Duration.zero);
  static final ValueNotifier<Duration> bufferedPosition = ValueNotifier<Duration>(Duration.zero);
  static final ValueNotifier<PlaybackTimeline> timeline = ValueNotifier<PlaybackTimeline>(
    const PlaybackTimeline.zero(),
  );

  static final ValueNotifier<List<Song>> queue = ValueNotifier<List<Song>>(<Song>[]);
  static Map<String, Song> _songsById = const {};

  static final List<StreamSubscription<dynamic>> _subscriptions = [];

  static AppLifecycleListener? _lifecycleListener;
  static bool _initialized = false;

  /// Canonical current-track metadata.
  ///
  /// Widgets should read/listen to this directly instead of maintaining
  /// separate Song/artwork caches.
  static Stream<MediaItem?> get mediaItemStream => _handler.mediaItem;
  static MediaItem? get currentMediaItem => _handler.currentItem;

  /// Returns the existing Song object for a MediaItem.
  ///
  /// This is only an ID lookup into the current queue. It does not create a
  /// second source of current-track state.
  static Song? songForMediaItem(MediaItem? item) {
    if (item == null) return null;
    return _songsById[item.id];
  }

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  static void initialize(KoshAudioHandler handler) {
    if (_initialized) return;

    _handler = handler;
    _initialized = true;

    // playbackState is the canonical play/pause/position/index state.
    _subscriptions.add(_handler.playbackState.listen(_applyPlaybackState));

    // The foreground seek bar needs the actual decoder clock, not occasional
    // AudioService PlaybackState snapshots. These streams remain owned by the
    // same AudioPlayer inside KoshAudioHandler, so there is still only one
    // source of playback truth.
    _subscriptions.add(
      _handler.positionStream.listen((value) {
        _publishTimeline(
          position: value,
          duration: _handler.currentDuration ?? _handler.currentItem?.duration ?? timeline.value.duration,
          buffered: _handler.currentBufferedPosition,
        );
      }),
    );

    _subscriptions.add(
      _handler.durationStream.listen((value) {
        _publishTimeline(
          position: _handler.currentPosition,
          duration: value ?? _handler.currentItem?.duration ?? Duration.zero,
          buffered: _handler.currentBufferedPosition,
        );
      }),
    );

    _subscriptions.add(
      _handler.bufferedPositionStream.listen((value) {
        _publishTimeline(
          position: _handler.currentPosition,
          duration: _handler.currentDuration ?? _handler.currentItem?.duration ?? timeline.value.duration,
          buffered: value,
        );
      }),
    );

    // The UI isolate may be suspended while iOS continues background audio.
    // On resume, read the latest retained values directly from the handler
    // before relying on any newly-delivered stream event.
    _lifecycleListener = AppLifecycleListener(onResume: _syncFromHandler);

    _syncFromHandler();
  }

  static Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    _lifecycleListener?.dispose();
    _lifecycleListener = null;

    await _handler.disposeHandler();

    isPlaying.dispose();
    position.dispose();
    duration.dispose();
    bufferedPosition.dispose();
    timeline.dispose();
    queue.dispose();

    _initialized = false;
  }

  // ---------------------------------------------------------------------------
  // PLAYBACK API USED BY THE EXISTING UI
  // ---------------------------------------------------------------------------

  static Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return;
    if (startIndex < 0 || startIndex >= songs.length) return;

    final immutableSongs = List<Song>.unmodifiable(songs);
    queue.value = immutableSongs;
    _songsById = {for (final song in immutableSongs) song.id: song};

    // Invalidate the previous track clock immediately. The authoritative
    // current item will arrive from KoshAudioHandler once the new queue loads.
    _publishTimeline(position: Duration.zero, duration: Duration.zero, buffered: Duration.zero);

    await _handler.loadQueue(songs, startIndex);

    // Explicit reconciliation makes this correct even if a platform stream
    // notification was coalesced during the load.
    _syncFromHandler();
  }

  static Future<void> playSong(Song song) {
    return playQueue([song], 0);
  }

  static Future<void> togglePlayPause() async {
    if (_handler.playing) {
      await _handler.pause();
    } else {
      await _handler.play();
    }

    _syncFromHandler();
  }

  static Future<void> skipToNext() async {
    await _handler.skipToNext();
    _syncFromHandler();
  }

  static Future<void> skipToPrevious() async {
    await _handler.skipToPrevious();
    _syncFromHandler();
  }

  static Future<void> seek(Duration target) async {
    await _handler.seek(target);
    _syncFromHandler();
  }

  static Future<void> seekFraction(double fraction) async {
    await _handler.seekFraction(fraction);
    _syncFromHandler();
  }

  // ---------------------------------------------------------------------------
  // HANDLER -> UI SYNCHRONIZATION
  // ---------------------------------------------------------------------------

  static void _applyPlaybackState(PlaybackState state) {
    if (isPlaying.value != state.playing) {
      isPlaying.value = state.playing;
    }

    _publishTimeline(
      position: _handler.currentPosition,
      duration: _handler.currentDuration ?? _handler.currentItem?.duration ?? Duration.zero,
      buffered: _handler.currentBufferedPosition,
    );
  }

  static void _syncFromHandler() {
    if (!_initialized) return;

    final handlerState = _handler.currentPlaybackState;

    if (isPlaying.value != handlerState.playing) {
      isPlaying.value = handlerState.playing;
    }

    _publishTimeline(
      position: _handler.currentPosition,
      duration: _handler.currentDuration ?? _handler.currentItem?.duration ?? Duration.zero,
      buffered: _handler.currentBufferedPosition,
    );
  }

  static void _publishTimeline({required Duration position, required Duration duration, required Duration buffered}) {
    final safePosition = position < Duration.zero
        ? Duration.zero
        : duration > Duration.zero && position > duration
        ? duration
        : position;

    final safeBuffered = buffered < Duration.zero
        ? Duration.zero
        : duration > Duration.zero && buffered > duration
        ? duration
        : buffered;

    final next = PlaybackTimeline(position: safePosition, duration: duration, bufferedPosition: safeBuffered);

    final previous = timeline.value;

    if (previous.position != next.position ||
        previous.duration != next.duration ||
        previous.bufferedPosition != next.bufferedPosition) {
      timeline.value = next;
    }

    if (PlayerState.position.value != next.position) {
      PlayerState.position.value = next.position;
    }
    if (PlayerState.duration.value != next.duration) {
      PlayerState.duration.value = next.duration;
    }
    if (PlayerState.bufferedPosition.value != next.bufferedPosition) {
      PlayerState.bufferedPosition.value = next.bufferedPosition;
    }
  }
}
