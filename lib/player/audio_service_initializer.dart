// lib/player/audio_service_initializer.dart
import 'package:playcard_app/config/config.dart';
import 'package:playcard_app/utils/app_startup.dart'; // Damit AppStartup.currentPlatform bekannt ist

AudioPlayerHandler? _audioHandler;

AudioPlayerHandler get audioHandler {
  if (_audioHandler == null) {
    throw StateError('AudioService has not been initialized. Call initializeAudioServiceIfNeeded() first.');
  }
  return _audioHandler!;
}
  bool shouldUseJustAudio() {
  final p = AppStartup.currentPlatform;
  return p == SupportedPlatform.android || p == SupportedPlatform.ios;
  }

Future<void> initializeAudioServiceIfNeeded() async {
  if (_audioHandler != null) {
    print('AudioService already initialized, skipping.');
    return;
  }
  try {
    _audioHandler = AudioPlayerHandler();
    await AudioService.init(
      builder: () => _audioHandler!,
      config: const AudioServiceConfig(
        androidNotificationChannelId: kNotificationChannelId,
        androidNotificationChannelName: kNotificationChannelName,
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/music_icon_notification',
      ),
    );
    print('AudioService initialized.');
  } catch (e) {
    print('Error initializing AudioService: $e');
    rethrow;
  }
}
