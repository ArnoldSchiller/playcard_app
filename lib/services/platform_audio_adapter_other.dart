// lib/services/platform_audio_adapter_other.dart
import 'package:playcard_app/services/adapter_interface.dart';
import 'package:playcard_app/services/audioplayers_adapter.dart';

AudioPlayerAdapter createAudioPlayerAdapter() {
  try {
    return AudioplayersAdapter();
  } catch (e) {
    throw UnsupportedError('audioplayers is not available. Ensure audioplayers is included in pubspec.yaml.');
  }
}
