// lib/player/video_player_initializer.dart
import 'package:video_player/video_player.dart';

/// Initialisiert einen VideoPlayerController für die Wiedergabe.
/// Da video_player keine globale Initialisierung benötigt, erstellen wir
/// einfach einen neuen Controller bei Bedarf.
Future<VideoPlayerController> createVideoPlayerController(String videoUrl) async {
  final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
  await controller.initialize();
  return controller;
}

/// Entsorgt einen VideoPlayerController.
Future<void> disposeVideoPlayerController(VideoPlayerController controller) async {
  await controller.dispose();
}
