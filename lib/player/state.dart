import 'package:flutter/foundation.dart';
import 'package:kosh/player/song.dart';

class PlayerState {
  static final currentSong = ValueNotifier<Song?>(null);
}
