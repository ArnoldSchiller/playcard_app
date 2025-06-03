// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:playcard_app/config/constants.dart'; // Nutze deine existierende Konfiguration

/// Exception-Klasse für sauberere Fehlerausgabe
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

/// Zentrale Service-Klasse für alle API-Aufrufe
class ApiService {
  ApiService(); // Konstruktor

  // Nutze die bereits definierte kApiUrl direkt
  // final String _baseUrl = kApiUrl; // Diese Variable ist überflüssig, da kApiUrl direkt verwendet wird.

  /// Allgemeine GET-Methode, die JSON zurückliefert (als Map)
  Future<Map<String, dynamic>> _getJson(String endpoint) async {
    final uri = Uri.parse('$kApiUrl/$endpoint'); // Nutze kApiUrl als Basis
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

  /// Allgemeine GET-Methode, die JSON zurückliefert (als Liste)
  /// Nützlich für Endpunkte, die direkt ein JSON-Array zurückgeben.
  Future<List<dynamic>> _getList(String endpoint) async {
    final uri = Uri.parse('$kApiUrl/$endpoint'); // Nutze kApiUrl als Basis
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List<dynamic>) {
        return data;
      } else {
        throw ApiException('Unerwartetes Format für $endpoint: Erwartet Liste, bekam ${data.runtimeType}. Inhalt: ${response.body}');
      }
    } else {
      throw ApiException('Fehler beim Laden von $endpoint: ${response.statusCode}. Details: ${response.body}');
    }
  }


  /// 🔊 Holt den aktuellen Status des Radios (wiederhergestellt)
  /// Gibt eine Map<String, dynamic> zurück, wie es ursprünglich war.
  Future<Map<String, dynamic>> fetchRadioStatus() => _getJson('radio');


  /// 🎵 Holt die Trackliste
  ///
  /// Wenn [structured] true ist, bekommst du eine Ordnerstruktur (die "data" Liste aus der Map).
  /// Wenn [structured] false ist, bekommst du eine flache Liste der "files".
  /// Gibt List<Map<String, dynamic>> zurück.
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

      // Hier behalten wir deine ursprüngliche Logik, um die flache Liste oder die strukturierte Liste zu erhalten
      if (decodedData is List<dynamic>) {
        // Fall: API gibt direkt eine Liste von Files zurück (unstrukturiert)
        return List<Map<String, dynamic>>.from(decodedData);
      } else if (decodedData is Map<String, dynamic> && decodedData.containsKey('data')) {
        final List<dynamic> rawDataList = decodedData['data'] as List<dynamic>;

        if (structured) {
          // Wenn structured true ist, geben wir die Liste der Ordner-Maps zurück
          return List<Map<String, dynamic>>.from(rawDataList);
        } else {
          // Wenn structured false, aggregieren wir alle Dateien aus den Ordnern zu einer flachen Liste
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
  /// Gibt eine Map<String, dynamic> zurück.
  Future<Map<String, dynamic>> fetchTrackInfo(String title) async {
    final encodedTitle = Uri.encodeComponent(title);
    return _getJson('track_info?title=$encodedTitle');
  }

  /// 🔀 Holt einen zufälligen Track
  /// Gibt eine Map<String, dynamic> zurück.
  Future<Map<String, dynamic>> fetchRandomTrack() => _getJson('random_track');

  /// 🧪 API-Einstiegsbeschreibung
  Future<Map<String, dynamic>> fetchApiOverview() => _getJson('');

  /// 📻 Holt einen zufälligen Radio-Stream (wiederhergestellt)
  /// Gibt eine Map<String, dynamic> zurück und ist kompatibel mit dem alten StreamItem.fromJson
  /// (oder wird später mit MediaItemMapper im Provider gemappt)
  Future<Map<String, dynamic>?> fetchRandomRadioStream() async {
    try {
      final response = await fetchRadioStatus(); // Ruft den originalen fetchRadioStatus auf
      final List<dynamic> rawStreams = response['radio_streams'] ?? [];
      if (rawStreams.isEmpty) return null;
      rawStreams.shuffle();
      // Füge isRadioStream hinzu, damit es von einem Mapper/FromJson erkannt werden kann
      return {...rawStreams.first as Map<String, dynamic>, 'isRadioStream': true};
    } catch (e) {
      print('Error fetching random radio stream: $e');
      return null;
    }
  }
}
