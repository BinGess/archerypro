import 'package:audioplayers/audioplayers.dart';

/// Service for playing competition whistle sounds
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// Two short whistles - preparation signal
  Future<void> playShortWhistles(int count) async {
    for (int i = 0; i < count; i++) {
      await _player.play(AssetSource('audio/whistle_short.mp3'));
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  /// One long whistle - start shooting signal
  Future<void> playLongWhistle() async {
    await _player.play(AssetSource('audio/whistle_long.mp3'));
  }

  /// Three long whistles - stop shooting signal
  Future<void> playStopWhistles() async {
    for (int i = 0; i < 3; i++) {
      await _player.play(AssetSource('audio/whistle_long.mp3'));
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 1400));
      }
    }
  }

  void dispose() {
    _player.dispose();
  }
}
