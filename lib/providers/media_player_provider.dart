// lib/providers/media_player_provider.dart
import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:playcard_app/config/config.dart';
import 'package:playcard_app/providers/video_player_provider.dart';

class MediaPlayerProvider extends ChangeNotifier {
  late AudioPlayerHandler _audioHandler;
  VideoPlayerProvider? _videoProvider;
  StreamItem? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  bool _isBuffering = false;
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();

  StreamItem? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get currentDuration => _currentDuration;
  bool get isBuffering => _isBuffering;
  bool get isProcessing => _isProcessing;

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
        _currentSong = StreamItem(
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

  Future<void> play(StreamItem song) async {
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

  Future<void> _playAudio(StreamItem song) async {
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
    if (isProcessing) return; // Prevent multiple rapid taps
    _isProcessing = true;
    notifyListeners(); // Notify listeners to potentially show a loading state on the button immediately

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
      // Only if play/pause was successful, update the _isPlaying state
      // (Assuming _audioHandler updates its internal state which _isPlaying reflects)
      // Or, you might explicitly update _isPlaying here if it's managed by your provider
      // _isPlaying = !_isPlaying; // This might be handled by _audioHandler itself
    } catch (e) {
      print('Error in playOrPause: $e'); // Good for debugging, but not for user
      // --- THIS IS THE CRUCIAL PART ---
      // Handle the error for the user!
      // Example: Show a SnackBar or AlertDialog
      // You'll need access to a BuildContext to show UI elements like Snackbars.
      // This is often done by passing a callback to the UI or using a state management approach
      // that can trigger UI messages.
      // For now, let's just reverse the icon change if it already happened
      _isPlaying = !_isPlaying; // Revert the icon back to previous state if error occurred
      // --- END CRUCIAL PART ---
    } finally {
      _isProcessing = false; // Always reset processing state
      notifyListeners(); // Notify listeners again to update UI after success or failure
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
      final randomRadioStreamData = await _apiService.fetchRandomRadioStream(); // Dies ist das Map<String, dynamic>
      if (randomRadioStreamData != null) {
        // Wandle die Map in ein StreamItem-Objekt um
        final StreamItem randomSong = StreamItem.fromJson(randomRadioStreamData);
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
      final song = StreamItem.fromJson({...randomTrack, 'isRadioStream': false});
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
