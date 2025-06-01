// lib/services/video_player_provider.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as vp;

class VideoPlayerProvider extends ChangeNotifier {
  vp.VideoPlayerController? _controller;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  String? _currentVideoUrl;
  bool _isBuffering = false;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get currentDuration => _currentDuration;
  String? get currentVideoUrl => _currentVideoUrl;
  vp.VideoPlayerController? get controller => _controller;
  bool get isBuffering => _controller?.value.isBuffering ?? false;

  VideoPlayerProvider() {
    // Initialisiere Listener, wenn ein Controller erstellt wird
  }


  Future<void> playVideo(String videoUrl) async {
    if (videoUrl.isEmpty || Uri.tryParse(videoUrl)?.isAbsolute != true) {
      print('Invalid video URL: $videoUrl');
      return;
    }
    _currentVideoUrl = videoUrl;
    try {
      await _controller?.dispose();
      _controller = vp.VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();
      _controller!.addListener(() {
        _isPlaying = _controller!.value.isPlaying;
        _currentPosition = _controller!.value.position;
        _currentDuration = _controller!.value.duration;
        _isBuffering = _controller!.value.isBuffering;
        notifyListeners();
      });
      await _controller!.play();
      print('Playing video: $videoUrl');
    } catch (e) {
      print('Error playing video: $e');
      Future.delayed(const Duration(seconds: 2), () => playVideo(videoUrl));
    }
    notifyListeners();
  }

  Future<void> playOrPause() async {
    try {
      if (_isPlaying) {
        await _controller?.pause();
      } else {
        await _controller?.play();
      }
    } catch (e) {
      print('Error in playOrPause: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _controller?.pause();
      await _controller?.dispose();
      _controller = null;
      _currentVideoUrl = null;
      _isPlaying = false;
      _currentPosition = Duration.zero;
      _currentDuration = Duration.zero;
      _isBuffering = false;
      notifyListeners();
    } catch (e) {
      print('Error stopping video: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _controller?.seekTo(position);
      notifyListeners();
    } catch (e) {
      print('Error seeking video: $e');
    }
  }

  Future<void> skipForward(Duration duration) async {
    final newPosition = _currentPosition + duration;
    if (newPosition < _currentDuration) {
      await seek(newPosition);
    }
  }

  Future<void> skipBackward(Duration duration) async {
    final newPosition = _currentPosition - duration;
    if (newPosition > Duration.zero) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  void dispose() {
    try {
      _controller?.dispose();
      print('VideoPlayerProvider disposed.');
    } catch (e) {
      print('Error disposing VideoPlayerProvider: $e');
    }
    super.dispose();
  }
}
