// lib/providers/media_player_provider.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:playcard_app/config/config.dart';
import 'package:playcard_app/player/audio_service_initializer.dart';
import 'package:playcard_app/services/audio_handler.dart';
import 'package:playcard_app/providers/video_player_provider.dart';
import 'package:playcard_app/models/song.dart';

class MediaPlayerProvider extends ChangeNotifier {
  late AudioPlayerHandler _audioHandler;
  VideoPlayerProvider? _videoProvider;
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  bool _isBuffering = false;
  final ApiService _apiService = ApiService();

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get currentDuration => _currentDuration;
  bool get isBuffering => _isBuffering;

  MediaPlayerProvider() {
    _audioHandler = AudioPlayerHandler();

    _audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing ?? false;
      _currentPosition = state.updatePosition ?? Duration.zero;
      _isBuffering = state.processingState == audio_service.AudioProcessingState.buffering ||
          state.processingState == audio_service.AudioProcessingState.loading;
      if (state.processingState == audio_service.AudioProcessingState.completed && _currentSong != null) {
        play(_currentSong!);
      }
      notifyListeners();
    });

    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        _currentSong = Song(
          name: mediaItem.title,
          artist: mediaItem.artist,
          streamUrl: mediaItem.id,
          coverImageUrl: mediaItem.artUri?.toString(),
          relativePath: null,
          isRadioStream: mediaItem.extras?['isRadioStream'] ?? false,
        );
        _currentDuration = mediaItem.duration ?? Duration.zero;
        notifyListeners();
      }
    });
  }

  void initializeVideoProvider(BuildContext context) {
    try {
      _videoProvider = context.read<VideoPlayerProvider>();
      _videoProvider?.addListener(() {
        if (_isVideoStream()) {
          _isPlaying = _videoProvider?.isPlaying ?? false;
          _currentPosition = _videoProvider?.currentPosition ?? Duration.zero;
          _currentDuration = _videoProvider?.currentDuration ?? Duration.zero;
          _isBuffering = _videoProvider?.isBuffering ?? false;
          notifyListeners();
        }
      });
    } catch (e) {
      print('VideoPlayerProvider not available: $e');
      _videoProvider = null;
    }
  }

  bool _isVideoStream() {
    return _currentSong != null &&
        !_currentSong!.isRadioStream &&
        (_currentSong!.streamUrl.endsWith('.mp4') ||
            _currentSong!.streamUrl.endsWith('.mkv') ||
            _currentSong!.streamUrl.endsWith('.webm'));
  }

  Future<void> play(Song song) async {
    await stop();
    _currentSong = song;

    if (_isVideoStream() && _videoProvider != null) {
      try {
        await _videoProvider!.playVideo(song.streamUrl);
      } catch (e) {
        print('Error playing video: $e');
        await _playAudio(song);
      }
    } else {
      await _playAudio(song);
    }
    notifyListeners();
  }

  Future<void> _playAudio(Song song) async {
    String mediaUrl = song.streamUrl;
    if (!song.isRadioStream && song.relativePath != null) {
      mediaUrl = '$kBaseUrl${song.relativePath}';
    }

    if (mediaUrl.isEmpty || Uri.tryParse(mediaUrl)?.isAbsolute != true) {
      print('Invalid media URL: $mediaUrl');
      return;
    }
    try {
      await _audioHandler.playMediaItem(audio_service.MediaItem(
        id: mediaUrl,
        title: song.name,
        artist: song.artist ?? 'Unknown',
        artUri: song.coverImageUrl != null ? Uri.parse(song.coverImageUrl!) : null,
        duration: _currentDuration,
        extras: {'isRadioStream': song.isRadioStream},
      ));
      print('Playing with audio_service: ${song.name} - URL: $mediaUrl');
    } catch (e) {
      print('Error playing media: $e');
      Future.delayed(const Duration(seconds: 2), () => _playAudio(song));
    }
  }

  Future<void> playOrPause() async {
    try {
      if (_isVideoStream() && _videoProvider != null) {
        await _videoProvider!.playOrPause();
      } else {
        if (_isPlaying) {
          await _audioHandler.pause();
        } else {
          await _audioHandler.play();
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error in playOrPause: $e');
    }
  }

  Future<void> stop() async {
    try {
      if (_isVideoStream() && _videoProvider != null) {
        await _videoProvider!.stop();
      }
      await _audioHandler.stop();
      _currentSong = null;
      _isPlaying = false;
      _currentPosition = Duration.zero;
      _currentDuration = Duration.zero;
      _isBuffering = false;
      notifyListeners();
    } catch (e) {
      print('Error stopping player: $e');
    }
  }

  Future<void> skipForward(Duration duration) async {
    try {
      if (_isVideoStream() && _videoProvider != null) {
        await _videoProvider!.skipForward(duration);
      } else {
        final newPosition = _currentPosition + duration;
        if (newPosition < _currentDuration) {
          await _audioHandler.seek(newPosition);
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error skipping forward: $e');
    }
  }

  Future<void> skipBackward(Duration duration) async {
    try {
      if (_isVideoStream() && _videoProvider != null) {
        await _videoProvider!.skipBackward(duration);
      } else {
        final newPosition = _currentPosition - duration;
        if (newPosition > Duration.zero) {
          await _audioHandler.seek(newPosition);
        } else {
          await _audioHandler.seek(Duration.zero);
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error skipping backward: $e');
    }
  }

  Future<void> playNextRandom() async {
    try {
      final randomSong = await _apiService.fetchRandomRadioStream();
      if (randomSong != null) {
        await play(randomSong);
      }
    } catch (e) {
      print('Error fetching random stream: $e');
    }
  }

  Future<void> playNextRandomTrack(BuildContext context) async {
    try {
      final searchProvider = context.read<SearchProvider>();
      if (searchProvider.searchResults.isNotEmpty) {
        final randomIndex = Random().nextInt(searchProvider.searchResults.length);
        final nextSong = searchProvider.searchResults[randomIndex];
        await play(nextSong);
        return;
      }
      final randomTrack = await _apiService.fetchRandomTrack();
      final song = Song.fromJson({...randomTrack, 'isRadioStream': false});
      await play(song);
    } catch (e) {
      print('Error fetching random track: $e');
      await playNextRandom();
    }
  }

  Future<void> seek(Duration position) async {
    try {
      if (_isVideoStream() && _videoProvider != null) {
        await _videoProvider!.seek(position);
      } else {
        await _audioHandler.seek(position);
      }
      notifyListeners();
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  @override
  void dispose() {
    try {
      print('MediaPlayerProvider disposed.');
    } catch (e) {
      print('Error disposing MediaPlayerProvider: $e');
    }
    super.dispose();
  }
}
