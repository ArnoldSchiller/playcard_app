// lib/providers/media_player_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // Importieren für BuildContext
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:playcard_app/config/constants.dart';
import 'package:playcard_app/models/song.dart';
import 'package:playcard_app/services/api_service.dart'; // API Service für zufälligen Song

class MediaPlayerProvider extends ChangeNotifier {
  Player? _player;
  VideoController? _videoController;
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  bool _isBuffering = false;
  bool _hasVideo = false;

  // NEU: Historie für "Zurück"
  final List<Song> _history = [];
  // NEU: Referenz zum ApiService
  final ApiService _apiService;

  Player? get player => _player;
  VideoController? get videoController => _videoController;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get currentDuration => _currentDuration;
  bool get isBuffering => _isBuffering;
  bool get hasVideo => _hasVideo;

  // MediaPlayerProvider benötigt jetzt den ApiService
  MediaPlayerProvider(this._apiService) { // <-- Änderung im Konstruktor
    _player = Player();
    _player!.stream.playing.listen((isPlaying) {
      _isPlaying = isPlaying;
      notifyListeners();
    });
    _player!.stream.position.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    _player!.stream.duration.listen((duration) {
      _currentDuration = duration;
      notifyListeners();
    });
    _player!.stream.buffering.listen((isBuffering) {
      _isBuffering = isBuffering;
      notifyListeners();
    });
    _player!.stream.error.listen((error) {
      //print('MediaPlayerProvider Error: $error');
    });
  }

  @override
  Future<void> play(Song song) async { // <-- async hinzugefügt, falls noch nicht da
    if (_player == null) {
      //print('Error: Player not initialized.');
      return;
    }

    // NEU: Aktuellen Song zur Historie hinzufügen, BEVOR ein neuer gespielt wird
    if (_currentSong != null && _currentSong!.streamUrl != song.streamUrl) {
      _history.add(_currentSong!);
      // Optional: Limit der Historie, z.B. nur die letzten 20 Songs behalten
      if (_history.length > 20) {
        _history.removeAt(0);
      }
    }

    _currentSong = song;
    _hasVideo = song.streamUrl.endsWith('.mp4');

    if (_hasVideo && _videoController == null) {
      _videoController = VideoController(_player!);
    } else if (!_hasVideo && _videoController != null) {
      _videoController = null;
    }

    notifyListeners();

    //print('Playing: ${song.name} - URL: ${song.streamUrl}');
    await _player!.open(Media(song.streamUrl));
    _player!.play();
  }

  Future<void> playOrPause() async {
    if (_player != null) {
      await _player!.playOrPause();
    }
  }

  Future<void> stop() async {
    if (_player != null) {
      await _player!.stop();
      _currentSong = null;
      _isPlaying = false;
      _currentPosition = Duration.zero;
      _currentDuration = Duration.zero;
      _isBuffering = false;
      _hasVideo = false;
      _history.clear(); // Optional: Historie beim Stoppen leeren
      notifyListeners();
    }
  }

  Future<void> resetPlayer() async {
    if (_player != null) {
      await _player!.dispose();
      _currentSong = null;
      _isPlaying = false;
      _hasVideo = false;
      _videoController = null;
      _history.clear(); // Auch hier Historie leeren
      notifyListeners();
    }
  }

  // NEU: Methode für "Nächster Song" (zufällig)
  Future<void> playNextRandom() async {
    try {
      final randomSong = await _apiService.fetchRandomSong(); // API aufrufen
      if (randomSong != null) {
        await play(randomSong); // Neuen Song abspielen (fügt ihn automatisch zur Historie hinzu)
      } else {
        //print('No random song fetched.');
      }
    } catch (e) {
      //print('Error fetching random song: $e');
      // Hier können Sie Fehlerbehandlung einfügen, z.B. eine Toast-Nachricht anzeigen
    }
  }

  // NEU: Methode für "Vorheriger Song" (Historie oder Screen zurück)
  Future<void> playPreviousOrPopScreen(BuildContext context) async {
    if (_history.isNotEmpty) {
      final previousSong = _history.removeLast(); // Letzten Song aus Historie holen
      await play(previousSong); // Abspielen
    } else {
      // Wenn der Verlauf leer ist, versuchen wir, einen Screen zurückzugehen
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // Dies ist der Fall, wenn kein Song in der Historie und kein Screen mehr zum Poppen da ist.
        // Hier können Sie entscheiden, was passieren soll:
        // 1. Nichts tun (App bleibt auf dem aktuellen Screen)
        // 2. Explizit zum Home-Screen navigieren (um sicherzustellen, dass die App nicht "steckenbleibt")
        // Beispiel für 2:
        // Navigator.of(context).pushAndRemoveUntil(
        //   MaterialPageRoute(builder: (ctx) => HomeScreen()), // Ersetzen Sie HomeScreen() durch Ihren tatsächlichen Startscreen
        //   (route) => false, // Entfernt alle vorherigen Routen
        // );
        //print("INFO: No previous song in history and cannot pop screen. Consider navigating to a default screen.");
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    // KEIN _videoController?.dispose() hier! Der VideoController wird mit dem Player disposed.
    super.dispose();
    //print('MediaPlayerProvider disposed.');
  }
}
