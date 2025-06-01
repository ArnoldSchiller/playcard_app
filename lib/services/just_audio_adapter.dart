//lib/services/just_audio_adapter.dart
import 'package:playcard_app/config/config.dart'; 
import 'package:playcard_app/services/adapter_interface.dart';
import 'package:just_audio/just_audio.dart';
import 'package:playcard_app/services/platform_audio_adapter_mobile.dart';

class JustAudioAdapter implements AudioPlayerAdapter {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(String url) async {
    await _player.setUrl(url);
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration> get durationStream => _player.durationStream.map((duration) => duration ?? Duration.zero);

  @override
  Stream<bool> get playingStream => _player.playingStream;
}

