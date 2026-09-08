import 'package:flutter/foundation.dart';
import 'package:kosh/player/song.dart';

class PlayerState {
  PlayerState._();
  static final ValueNotifier<Song?> currentSong = ValueNotifier<Song?>(null);
}
