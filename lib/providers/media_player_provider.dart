// Import your custom models and services
import 'package:playcard_app/config/constants.dart'; // For kBaseUrl
import 'package:playcard_app/utils/stream_item_mapper.dart'; // Your StreamItemMapper for converting API responses
// lib/providers/media_player_provider.dart
import 'package:flutter/material.dart'; // Für ChangeNotifier
import 'package:audio_service/audio_service.dart' as audio_service; // Wichtig: Mit Prefix!
import 'package:provider/provider.dart'; // Für context.read falls verwendet

import 'package:playcard_app/config/constants.dart'; // Falls in MediaPlayerProvider benötigt
import 'package:playcard_app/models/stream_item.dart'; // Hinzugefügt für StreamItem
import 'package:playcard_app/models/stream_type.dart'; // Hinzugefügt für StreamType
import 'package:playcard_app/services/audio_handler.dart'; // Für AudioPlayerHandler
import 'package:playcard_app/providers/video_player_provider.dart'; // Hinzugefügt für VideoPlayerProvider
import 'package:playcard_app/services/api_service.dart'; // Falls API-Aufrufe direkt hier
import 'package:playcard_app/providers/search_provider.dart'; // Für searchProvider.searchResults


class MediaPlayerProvider extends ChangeNotifier {
  late AudioPlayerHandler _audioHandler; // Your custom handler, delegates to platform-specific player
  VideoPlayerProvider? _videoProvider; // Optional video player provider

  // Changed from Song to StreamItem
  StreamItem? _currentStreamItem; // Represents the currently playing item
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  bool _isBuffering = false;
  final ApiService _apiService = ApiService();

  // Changed getters from currentSong to currentStreamItem
  StreamItem? get currentStreamItem => _currentStreamItem;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get currentDuration => _currentDuration;
  bool get isBuffering => _isBuffering;

  // Add for playlist functionality (if you want to implement skip next/previous for tracks)
  List<StreamItem> _currentPlaylist = [];
  int _currentPlaylistIndex = -1;

  MediaPlayerProvider() {
    // Initialisiere AudioPlayerHandler.
    // Wichtig: AudioService.start() muss zuvor in main/app_startup aufgerufen worden sein.
    // Das direkte Instanziieren hier (_audioHandler = AudioPlayerHandler();) ist ok,
    // wenn AudioService.start() die Handler-Instanz verwaltet und diese statisch verfügbar macht,
    // oder wenn AudioPlayerHandler einen Singleton-Zugriff bietet.
    // Die sicherste Methode ist AudioService.handler, aber wenn Ihr AudioPlayerHandler
    // ein Singleton ist, dann ist diese Zeile auch in Ordnung.
    // Gehen wir davon aus, dass Ihr AudioPlayerHandler intern den AudioService richtig registriert.
    _audioHandler = audio_service.AudioService.handler as AudioPlayerHandler; // Safest way to get handler after AudioService.start()

    _audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing ?? false;
      _currentPosition = state.updatePosition ?? Duration.zero;
      _isBuffering = state.processingState == audio_service.AudioProcessingState.buffering ||
          state.processingState == audio_service.AudioProcessingState.loading;
      
      // If a track finishes, play the next one in the playlist (if not a radio stream)
      // For radio streams, restart them.
      if (state.processingState == audio_service.AudioProcessingState.completed && _currentStreamItem != null) {
        if (_currentStreamItem!.mediaType == StreamType.radioStream) {
          play(_currentStreamItem!); // Restart radio stream
        } else {
          skipNext(); // Skip to next track in playlist
        }
      }
      notifyListeners();
    });

    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        // Convert audio_service.MediaItem back to our StreamItem
        // Ensure all necessary fields are mapped correctly from MediaItem and its extras.
        _currentStreamItem = StreamItem(
          id: mediaItem.id, // Usually the URL or unique identifier
          name: mediaItem.title,
          artist: mediaItem.artist,
          streamUrl: mediaItem.id, // Re-use ID as streamUrl, or get from extras if different
          coverImageUrl: mediaItem.artUri?.toString(),
          relativePath: mediaItem.extras?['relativePath'] as String?, // Retrieve relativePath from extras
          isRadioStream: mediaItem.extras?['isRadioStream'] ?? false, // Retrieve isRadioStream from extras
          duration: mediaItem.duration, // Use duration from MediaItem
          mediaType: _getStreamTypeFromAudioServiceExtras(mediaItem.extras), // Determine media type
        );
        _currentDuration = mediaItem.duration ?? Duration.zero;
        notifyListeners();
      } else {
        _currentStreamItem = null;
        _currentDuration = Duration.zero;
        notifyListeners();
      }
    });
  }

  // Helper to determine StreamType from AudioService extras (similar to previous approach)
  StreamType _getStreamTypeFromAudioServiceExtras(Map<String, dynamic>? extras) {
    if (extras == null) return StreamType.localFile; // Default or fallback

    // Check for 'isRadioStream' first, as it's a strong indicator
    if (extras['isRadioStream'] == true) {
      return StreamType.radioStream;
    }
    
    // Check for explicit 'mediaTypeString' if stored
    final String? mediaTypeString = extras['mediaTypeString'];
    if (mediaTypeString != null) {
      try {
        return StreamType.values.firstWhere((e) => e.toString().split('.').last == mediaTypeString);
      } catch (_) {
        // Fallback if conversion fails
      }
    }

    // Fallback: Infer from streamUrl if no other info is available
    final String? streamUrl = extras['streamUrl'] as String?; // Assuming original streamUrl is in extras
    if (streamUrl != null) {
      final String lowerCaseUrl = streamUrl.toLowerCase();
      if (lowerCaseUrl.endsWith('.mp4') || lowerCaseUrl.endsWith('.mkv') || lowerCaseUrl.endsWith('.webm') || lowerCaseUrl.endsWith('.ogv')) {
        return StreamType.videoStream;
      }
      // You might add more checks for audio file extensions if needed
      // else if (lowerCaseUrl.endsWith('.mp3') || lowerCaseUrl.endsWith('.wav')) {
      //   return StreamType.localFile; // Or StreamType.audioFile if you have it
      // }
    }
    return StreamType.localFile; // Default fallback for unknown types
  }


  // This method remains crucial for conditionally initializing VideoPlayerProvider
  void initializeVideoProvider(BuildContext context) {
    if (_videoProvider == null) {
      try {
        _videoProvider = context.read<VideoPlayerProvider>();
        _videoProvider?.addListener(() {
          if (_isVideoStream()) { // Check if the current item is actually a video stream
            _isPlaying = _videoProvider?.isPlaying ?? false;
            _currentPosition = _videoProvider?.currentPosition ?? Duration.zero;
            _currentDuration = _videoProvider?.currentDuration ?? Duration.zero;
            _isBuffering = _videoProvider?.isBuffering ?? false;
            notifyListeners();
          }
        });
      } catch (e) {
        print('VideoPlayerProvider not available in context: $e');
        _videoProvider = null; // Ensure it's null if not found
      }
    }
  }

  // Changed _currentSong to _currentStreamItem and Song to StreamItem
  bool _isVideoStream() {
    return _currentStreamItem != null &&
        _currentStreamItem!.mediaType == StreamType.videoStream; // Use the new mediaType enum
  }

  // Changed Song to StreamItem, added optional playlist
  Future<void> play(StreamItem streamItem, {List<StreamItem>? playlist}) async {
    await stop(); // Stop any currently playing media
    _currentStreamItem = streamItem; // Set the new current item

    // Set the current playlist for skip functionality
    if (playlist != null && playlist.isNotEmpty) {
      _currentPlaylist = List.from(playlist); // Create a copy of the list
      _currentPlaylistIndex = _currentPlaylist.indexOf(streamItem);
      if (_currentPlaylistIndex == -1) {
         _currentPlaylist = [streamItem];
         _currentPlaylistIndex = 0;
      }
    } else {
      _currentPlaylist = [streamItem];
      _currentPlaylistIndex = 0;
    }

    notifyListeners(); // Notify UI about the new item being selected

    // Conditional playback based on media type
    if (_isVideoStream()) {
      // If it's a video stream, we need to check if VideoPlayerProvider is available.
      // The actual context to initialize VideoPlayerProvider will come from the UI call.
      // So, if initializeVideoProvider was not called by the UI yet, _videoProvider might be null.
      // This is okay, as the UI will usually call play with context, triggering initializeVideoProvider.
      if (_videoProvider != null) {
        try {
          await _videoProvider!.playVideo(streamItem.streamUrl);
          print('Playing video via VideoPlayerProvider: ${streamItem.name}');
        } catch (e) {
          print('Error playing video with VideoPlayerProvider: $e. Falling back to audio.');
          await _playAudio(streamItem); // Fallback to audio if video playback fails
        }
      } else {
        print('VideoPlayerProvider not initialized for video stream. Falling back to audio: ${streamItem.name}');
        await _playAudio(streamItem); // Fallback to audio if VideoPlayerProvider is null
      }
    } else {
      await _playAudio(streamItem); // Play audio if not a video stream
    }
  }

  // Changed Song to StreamItem
  Future<void> _playAudio(StreamItem streamItem) async {
    String mediaUrl = streamItem.streamUrl;
    // For local files, resolve relativePath if applicable
    if (streamItem.mediaType == StreamType.localFile && streamItem.relativePath != null) {
      mediaUrl = '$kBaseUrl${streamItem.relativePath}'; // Ensure kBaseUrl is defined in config.dart
    }

    if (mediaUrl.isEmpty || Uri.tryParse(mediaUrl)?.isAbsolute != true) {
      print('Invalid media URL: $mediaUrl');
      return;
    }
    
    try {
      // Prepare MediaItem for AudioService
      await _audioHandler.playMediaItem(
        audio_service.MediaItem(
          id: mediaUrl, // AudioService uses ID for URL/URI
          title: streamItem.name,
          artist: streamItem.artist ?? 'Unknown',
          artUri: streamItem.coverImageUrl != null ? Uri.parse(streamItem.coverImageUrl!) : null,
          duration: streamItem.duration, // Use duration from StreamItem
          extras: {
            'isRadioStream': streamItem.isRadioStream,
            'mediaTypeString': streamItem.mediaType.toString().split('.').last, // Store enum as string
            'relativePath': streamItem.relativePath, // Store relativePath
            'streamUrl': streamItem.streamUrl, // Store original streamUrl
          },
        ),
      );
      print('Playing audio via AudioService: ${streamItem.name} - URL: $mediaUrl');
    } catch (e) {
      print('Error playing audio: $e');
      Future.delayed(const Duration(seconds: 2), () => _playAudio(streamItem)); // Retry
    }
  }

  // Unified play/pause logic
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

  // Unified stop logic
  Future<void> stop() async {
    try {
      if (_isVideoStream() && _videoProvider != null) {
        await _videoProvider!.stop();
      }
      await _audioHandler.stop(); // Stop audio (and background service)
      _currentStreamItem = null;
      _isPlaying = false;
      _currentPosition = Duration.zero;
      _currentDuration = Duration.zero;
      _isBuffering = false;
      _currentPlaylist = []; // Reset playlist
      _currentPlaylistIndex = -1; // Reset index
      notifyListeners();
    } catch (e) {
      print('Error stopping player: $e');
    }
  }

  // Skip functionality (forward/backward are generic, not specific to playlist)
  Future<void> skipForward(Duration duration) async {
    try {
      if (_isVideoStream() && _videoProvider != null) {
        await _videoProvider!.skipForward(duration);
      } else {
        // For audio, seek forward
        final newPosition = _currentPosition + duration;
        // Ensure not to seek beyond actual duration if known
        if (_currentDuration != Duration.zero && newPosition > _currentDuration) {
          await _audioHandler.seek(_currentDuration); // Go to end
        } else {
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
        // For audio, seek backward
        final newPosition = _currentPosition - duration;
        if (newPosition < Duration.zero) {
          await _audioHandler.seek(Duration.zero); // Go to beginning
        } else {
          await _audioHandler.seek(newPosition);
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error skipping backward: $e');
    }
  }

  // New: Skip to next item in the current playlist
  Future<void> skipNext() async {
    if (_currentPlaylist.isEmpty || _currentPlaylistIndex == -1) {
      print('Skip Next: No active playlist or stream item. Stopping.');
      await stop();
      return;
    }

    int nextIndex = _currentPlaylistIndex + 1;
    if (nextIndex < _currentPlaylist.length) {
      await play(_currentPlaylist[nextIndex], playlist: _currentPlaylist);
    } else {
      print('Skip Next: End of playlist. Stopping.');
      await stop(); // Stop if at the end of the playlist
    }
  }

  // New: Skip to previous item in the current playlist
  Future<void> skipPrevious() async {
    if (_currentPlaylist.isEmpty || _currentPlaylistIndex == -1) {
      print('Skip Previous: No active playlist or stream item. Stopping.');
      await stop();
      return;
    }

    // If current song has played for more than 3 seconds, restart it. Otherwise, go to previous.
    if (_currentPosition.inSeconds > 3 || _currentPlaylistIndex == 0) {
      print('Skip Previous: Restarting current stream item or no previous item.');
      await seek(Duration.zero);
    } else {
      int previousIndex = _currentPlaylistIndex - 1;
      if (previousIndex >= 0) {
        await play(_currentPlaylist[previousIndex], playlist: _currentPlaylist);
      } else {
        print('Skip Previous: Beginning of playlist. Stopping.');
        await stop();
      }
    }
  }

  // Renamed and adapted to StreamItem
  Future<void> playRandomRadioStream() async {
    try {
      final randomRadioStreamData = await _apiService.fetchRandomRadioStream();
      if (randomRadioStreamData != null) {
        final streamItem = StreamItemMapper.fromJson(randomRadioStreamData);
        await play(streamItem); // Play the fetched StreamItem
      }
    } catch (e) {
      print('Error fetching random radio stream: $e');
    }
  }

  // Renamed and adapted to StreamItem, requires BuildContext to access SearchProvider
  Future<void> playRandomTrack(BuildContext context) async {
    try {
      final searchProvider = context.read<SearchProvider>();
      if (searchProvider.searchResults.isNotEmpty) {
        final randomIndex = Random().nextInt(searchProvider.searchResults.length);
        final nextStreamItem = searchProvider.searchResults[randomIndex];
        await play(nextStreamItem, playlist: searchProvider.searchResults); // Pass search results as playlist
        return;
      }
      final randomTrackData = await _apiService.fetchRandomTrack();
      final streamItem = StreamItemMapper.fromJson(randomTrackData); // Use StreamItemMapper
      await play(streamItem);
    } catch (e) {
      print('Error fetching random track: $e');
      await playRandomRadioStream(); // Fallback to radio if track fetching fails
    }
  }

  // Unified seek logic
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
      // _audioHandler and _videoProvider are managed by their respective services/providers.
      // Do not dispose them directly here unless MediaPlayerProvider is their sole owner.
      // If _videoProvider is managed by ChangeNotifierProvider, it will be disposed automatically.
      print('MediaPlayerProvider disposed.');
    } catch (e) {
      print('Error disposing MediaPlayerProvider: $e');
    }
    super.dispose();
  }
}
