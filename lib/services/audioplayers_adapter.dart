// lib/services/audioplayers_adapter.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:playcard_app/services/adapter_interface.dart';

class AudioplayersAdapter implements AudioPlayerAdapter {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(String url) async {
    try {
      await _player.play(UrlSource(url));
    } catch (e) {
      print('Error playing with audioplayers: $e');
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      print('Error pausing with audioplayers: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Error stopping with audioplayers: $e');
      rethrow;
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('Error seeking with audioplayers: $e');
      rethrow;
    }
  }

  @override
  Stream<Duration> get positionStream => _player.onPositionChanged;

  @override
  Stream<Duration> get durationStream => _player.onDurationChanged;

  @override
  Stream<bool> get playingStream => _player.onPlayerStateChanged.map(
        (state) => state == PlayerState.playing,
      );
}
