// lib/models/song.dart
class Song {
  final String name;
  final String? artist;
  final String? relativePath;
  final String streamUrl;
  final String? coverImageUrl;
  final bool isRadioStream;

  Song({
    required this.name,
    this.artist,
    this.relativePath,
    required this.streamUrl,
    this.coverImageUrl,
    this.isRadioStream = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    final bool isRadioStream = json.containsKey('mount_point') && (json['mount_point'] as String).isNotEmpty;

    String calculatedStreamUrl;
    if (isRadioStream) {
      calculatedStreamUrl = json['mount_point']?.toString() ?? '';
    } else {
      calculatedStreamUrl = json['relative_path']?.toString() ?? '';
    }

    String? title = json['title']?.toString();
    String? artist = json['artist']?.toString();

    if (isRadioStream && (title?.startsWith('http://') == true || title?.startsWith('https://') == true)) {
      title = json['server_title']?.toString() ?? json['mount_point']?.toString() ?? 'Live Stream';
    } else if (isRadioStream && title?.contains(' - https://') == true) {
      final parts = title!.split(' - https://');
      if (parts.isNotEmpty) {
        title = parts[0].trim();
      }
    }

    return Song(
      name: title ?? json['mount_point']?.toString() ?? json['relative_path']?.toString() ?? 'Unbekannter Song',
      artist: artist,
      relativePath: json['relative_path']?.toString(),
      streamUrl: calculatedStreamUrl,
      coverImageUrl: json['cover_image_url']?.toString(),
      isRadioStream: isRadioStream,
    );
  }
}
