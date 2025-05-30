import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:playcard_app/config/config.dart';
import 'package:provider/provider.dart';

class MediaPlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final ApiService _apiService = ApiService();
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  bool _isBuffering = false;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get currentDuration => _currentDuration;
  bool get isBuffering => _isBuffering;

  MediaPlayerProvider() {
    _player.playingStream.listen((isPlaying) {
      _isPlaying = isPlaying;
      notifyListeners();
    });
    _player.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    _player.durationStream.listen((duration) {
      _currentDuration = duration ?? Duration.zero;
      notifyListeners();
    });
    _player.processingStateStream.listen((state) {
      _isBuffering = state == ProcessingState.buffering || state == ProcessingState.loading;
      if (state == ProcessingState.completed && _currentSong != null) {
        play(_currentSong!);
      }
      notifyListeners();
    });
  }

  Future<void> play(Song song) async {
    if (song.streamUrl.isEmpty || Uri.tryParse(song.streamUrl)?.isAbsolute != true) {
      print('Invalid stream URL: ${song.streamUrl}');
      return;
    }
    _currentSong = song;
    try {
      // Android: Nutze AudioService
      await AudioService.playMediaItem(MediaItem(
        id: song.streamUrl,
        title: song.name,
        artist: song.artist ?? 'Unknown',
        artUri: song.coverImageUrl != null ? Uri.parse(song.coverImageUrl!) : null,
      ));
      print('Playing with audio_service: ${song.name} - URL: ${song.streamUrl}');
      // Synchronisiere just_audio für lokale Steuerung
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.streamUrl),
          tag: MediaItem(
            id: song.streamUrl,
            title: song.name,
            artist: song.artist ?? 'Unknown',
            artUri: song.coverImageUrl != null ? Uri.parse(song.coverImageUrl!) : null,
          ),
        ),
        preload: false,
      );
      await _player.play();
    } catch (e) {
      print('Error playing stream: $e');
      Future.delayed(const Duration(seconds: 2), () => play(song));
    }
    notifyListeners();
  }

  Future<void> playOrPause() async {
    try {
      if (_isPlaying) {
        await AudioService.pause();
        await _player.pause();
      } else {
        await AudioService.play();
        await _player.play();
      }
    } catch (e) {
      print('Error in playOrPause: $e');
    }
  }

  Future<void> stop() async {
    try {
      await AudioService.stop();
      await _player.stop();
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
      await AudioService.seekTo(position);
      await _player.seek(position);
      notifyListeners();
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  @override
  void dispose() {
    try {
      _player.dispose();
    } catch (e) {
      print('Error disposing player: $e');
    }
    super.dispose();
    print('MediaPlayerProvider disposed.');
  }
}
