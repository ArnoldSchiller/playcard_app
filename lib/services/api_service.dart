//lib/services/api_service.dart
/*
Import: package:playcard_app/config/config.dart statt package:playcard_app/config/constants.dart.

fetchRandomRadioStream:
Nutzt response['data'] statt response['radio_streams'], um mit deiner API-Struktur (fetchIndex liefert data) konsistent zu sein.

Kompatibel mit Song.fromJson aus deinem Code.

Falls deine Radio-Stream-API radio_streams statt data verwendet, bestätige bitte die Struktur des /api/radio-Endpunkts (z. B. via curl https://jaquearnoux.de/playcard/api/radio).

Rest: Identisch zu deiner ursprünglichen Version, behält alle Endpunkte und Logik bei.
*/
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:playcard_app/config/config.dart';
import 'package:playcard_app/models/song.dart';

/// Exception-Klasse für sauberere Fehlerausgabe
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

/// Zentrale Service-Klasse für alle API-Aufrufe
class ApiService {
  ApiService(); // Konstruktor ohne 'const'

  final String kApiUrl = '$kBaseUrl/api';

  /// Allgemeine GET-Methode, die JSON zurückliefert
  /// Diese Methode ist primär für Endpunkte gedacht, die eine Map zurückgeben.
  Future<Map<String, dynamic>> _getJson(String endpoint) async {
    final uri = Uri.parse('$kApiUrl/$endpoint');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data;
      } else {
        throw ApiException('Unerwartetes Format für $endpoint: Erwartet Map, bekam ${data.runtimeType}. Inhalt: ${response.body}');
      }
    } else {
      throw ApiException('Fehler beim Laden von $endpoint: ${response.statusCode}. Details: ${response.body}');
    }
  }

  /// 🔊 Holt den aktuellen Status des Radios
  Future<Map<String, dynamic>> fetchRadioStatus() => _getJson('radio');

  /// 🎵 Holt die Trackliste
  ///
  /// Wenn [structured] true ist, bekommst du eine Ordnerstruktur (die "data" Liste aus der Map).
  /// Wenn [structured] false ist, bekommst du eine flache Liste der "files".
  Future<List<Map<String, dynamic>>> fetchIndex({
    required bool structured,
    String? search,
  }) async {
    final params = <String>[];

    params.add('structured=${structured ? 1 : 0}');
    if (search != null && search.trim().isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await http.get(Uri.parse('$kApiUrl/index$query'));

    if (response.statusCode == 200) {
      final decodedData = jsonDecode(response.body);

      if (decodedData is List<dynamic>) {
        return List<Map<String, dynamic>>.from(decodedData);
      } else if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
        final List<dynamic> rawDataList = decodedData['data'] as List<dynamic>;

        if (structured) {
          return List<Map<String, dynamic>>.from(rawDataList);
        } else {
          List<Map<String, dynamic>> flatTracks = [];
          for (var folderItem in rawDataList) {
            if (folderItem is Map<String, dynamic> && folderItem.containsKey('files')) {
              final List<dynamic> rawFilesList = folderItem['files'] as List<dynamic>;
              flatTracks.addAll(List<Map<String, dynamic>>.from(rawFilesList));
            }
          }
          return flatTracks;
        }
      } else {
        throw ApiException('Unerwartetes Format bei fetchIndex: Weder Liste noch Map mit "data" Schlüssel. Bekam ${decodedData.runtimeType}. Inhalt: ${response.body}');
      }
    } else {
      throw ApiException('Fehler beim Laden des Index: ${response.statusCode}. Details: ${response.body}');
    }
  }

  /// ❓ Holt Details zu einem bestimmten Track
  ///
  /// [title] ist der relative Pfad zur Datei, z. B. "Rock/Queen - Bohemian.mp3"
  Future<Map<String, dynamic>> fetchTrackInfo(String title) async {
    final encodedTitle = Uri.encodeComponent(title);
    return _getJson('track_info?title=$encodedTitle');
  }

  /// 🔀 Holt einen zufälligen Track
  Future<Map<String, dynamic>> fetchRandomTrack() => _getJson('random_track');

  /// 🧪 API-Einstiegsbeschreibung
  Future<Map<String, dynamic>> fetchApiOverview() => _getJson('');

  /// 📻 Holt einen zufälligen Radio-Stream
  Future<Song?> fetchRandomRadioStream() async {
    try {
      final response = await fetchRadioStatus();
      final List<dynamic> rawStreams = response['radio_streams'] ?? [];
      if (rawStreams.isEmpty) return null;
      rawStreams.shuffle();
      final stream = rawStreams.first as Map<String, dynamic>;
      return Song.fromJson({...stream, 'isRadioStream': true});
    } catch (e) {
      print('Error fetching random radio stream: $e');
      return null;
    }
  }
}
