//lib/models/stream_item.dart
enum StreamType {
  localFile,
  radioStream,
  videoStream,
}

class StreamItem {
  final String id;
  final String name;
  final String? artist;
  final String streamUrl;
  final String? coverImageUrl;
  final String? relativePath;
  final bool isRadioStream;
  final StreamType mediaType;
  final Duration? duration;

  StreamItem({
    String? id,
    required this.name,
    this.artist,
    required this.streamUrl,
    this.coverImageUrl,
    this.relativePath,
    this.isRadioStream = false,
    this.mediaType = StreamType.localFile,
    this.duration,
  }) : id = id ?? streamUrl; // fallback für Kompatibilität

  factory StreamItem.fromJson(Map<String, dynamic> json) {
    final bool isRadioStream = json.containsKey('mount_point');
    final String id = json['stream_url'] ?? json['mount_point'] ?? json['relative_path'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    String name = json['title']?.toString() ??
        json['name']?.toString() ??
        json['server_title']?.toString() ??
        json['mount_point']?.toString() ??
        json['relative_path']?.toString() ??
        'Unbekannter Titel';

    if (isRadioStream && name.startsWith('http')) {
      name = json['server_title']?.toString() ?? name;
    } else if (isRadioStream && name.contains(' - https://')) {
      final parts = name.split(' - https://');
      if (parts.isNotEmpty) name = parts[0].trim();
    }

    final String? artist = (json['artist'] as String?)?.isEmpty == true ? null : json['artist'];
    final String? relativePath = json['relative_path'];
    final String streamUrl = json['stream_url'] ?? json['mount_point'] ?? '';
    final String? coverImageUrl = json['cover_image_url'];

    final StreamType mediaType = isRadioStream
        ? StreamType.radioStream
        : (json['extension']?.toString().toLowerCase().contains('mp4') == true
            ? StreamType.videoStream
            : StreamType.localFile);

    return StreamItem(
      id: id,
      name: name,
      artist: artist,
      streamUrl: streamUrl,
      coverImageUrl: coverImageUrl,
      relativePath: relativePath,
      isRadioStream: isRadioStream,
      mediaType: mediaType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          streamUrl == other.streamUrl;

  @override
  int get hashCode => id.hashCode ^ streamUrl.hashCode;

  @override
  String toString() {
    return 'StreamItem(id: $id, name: $name, artist: $artist, streamUrl: $streamUrl, '
        'coverImageUrl: $coverImageUrl, relativePath: $relativePath, '
        'isRadioStream: $isRadioStream, mediaType: $mediaType, duration: $duration)';
  }

  StreamItem copyWith({
    String? id,
    String? name,
    String? artist,
    String? streamUrl,
    String? coverImageUrl,
    String? relativePath,
    bool? isRadioStream,
    StreamType? mediaType,
    Duration? duration,
  }) {
    return StreamItem(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      streamUrl: streamUrl ?? this.streamUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      relativePath: relativePath ?? this.relativePath,
      isRadioStream: isRadioStream ?? this.isRadioStream,
      mediaType: mediaType ?? this.mediaType,
      duration: duration ?? this.duration,
    );
  }
}

