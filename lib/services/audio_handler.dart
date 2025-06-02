// lib/services/audio_handler.dart
import 'package:audio_service/audio_service.dart';
import 'package:playcard_app/services/adapter_interface.dart';
import 'package:playcard_app/services/just_audio_adapter.dart';
import 'package:playcard_app/services/audioplayers_adapter.dart';
import 'package:playcard_app/core/app_startup.dart';




class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  AudioPlayerAdapter? _playerAdapter;
  PlaybackState _playbackState = PlaybackState();
  MediaItem? _currentMediaItem;

  AudioPlayerHandler() {
    // Plattform-spezifische Präferenz
    bool preferAudioplayers = AppStartup.currentPlatform == SupportedPlatform.linux;

    if (preferAudioplayers) {
      try {
        _playerAdapter = AudioplayersAdapter();
        print('Using AudioplayersAdapter (preferred for Linux)');
      } catch (e) {
        print('audioplayers not available or failed on Linux: $e');
        try {
          _playerAdapter = JustAudioAdapter();
          print('Using JustAudioAdapter (fallback on Linux)');
        } catch (e) {
          throw UnsupportedError(
              'Neither audioplayers nor just_audio is available. Please add at least one to pubspec.yaml.');
        }
      }
    } else {
      try {
        _playerAdapter = JustAudioAdapter();
        print('Using JustAudioAdapter (preferred for non-Linux platforms)');
      } catch (e) {
        print('just_audio not available: $e');
        try {
          _playerAdapter = AudioplayersAdapter();
          print('Using AudioplayersAdapter (fallback on non-Linux platforms)');
        } catch (e) {
          throw UnsupportedError(
              'Neither just_audio nor audioplayers is available. Please add at least one to pubspec.yaml.');
        }
      }
    }

    // Listen to play state
    _playerAdapter!.playingStream.listen((playing) {
      _playbackState = _playbackState.copyWith(
        playing: playing,
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        processingState: playing ? AudioProcessingState.ready : AudioProcessingState.idle,
      );
      playbackState.add(_playbackState);
    });

    // Listen to playback position
    _playerAdapter!.positionStream.listen((position) {
      _playbackState = _playbackState.copyWith(updatePosition: position);
      playbackState.add(_playbackState);
    });

    // Listen to duration
    _playerAdapter!.durationStream.listen((duration) {
      if (_currentMediaItem != null) {
        _currentMediaItem = _currentMediaItem!.copyWith(duration: duration);
        mediaItem.add(_currentMediaItem!);
      }
      _playbackState = _playbackState.copyWith(bufferedPosition: duration);
      playbackState.add(_playbackState);
    });
  }

  @override
  Future<void> play() async {
    if (_currentMediaItem != null) {
      await _playerAdapter!.play(_currentMediaItem!.id);
    }
  }

  @override
  Future<void> pause() async {
    await _playerAdapter!.pause();
  }

  @override
  Future<void> stop() async {
    await _playerAdapter!.stop();
    _currentMediaItem = null;
    mediaItem.add(null);
    _playbackState = _playbackState.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    );
    playbackState.add(_playbackState);
  }

  @override
  Future<void> seek(Duration position) async {
    await _playerAdapter!.seek(position);
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    _currentMediaItem = mediaItem;
    this.mediaItem.add(mediaItem);
    await _playerAdapter!.play(mediaItem.id);
  }

  // Optional: useful for UI
  Stream<Duration> get positionStream => _playerAdapter!.positionStream;
  Stream<Duration> get durationStream => _playerAdapter!.durationStream;
  Stream<bool> get playingStream => _playerAdapter!.playingStream;
}
