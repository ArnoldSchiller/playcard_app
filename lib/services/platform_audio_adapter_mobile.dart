// lib/services/platform_audio_adapter_mobile.dart
import 'package:playcard_app/services/adapter_interface.dart';
import 'package:playcard_app/services/just_audio_adapter.dart';

AudioPlayerAdapter createAudioPlayerAdapter() {
  try {
    return JustAudioAdapter();
  } catch (e) {
    throw UnsupportedError('just_audio is not available. Ensure just_audio is included in pubspec.yaml.');
  }
}
