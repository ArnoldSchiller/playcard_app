// lib/models/stream_item.dart
import 'package:playcard_app/models/stream_type.dart'; // Import the StreamType enum

class StreamItem {
  final String id;
  final String name;
  final String? artist;
  final String streamUrl;
  final String? coverImageUrl;
  final String? relativePath; // For local files
  final bool isRadioStream;
  final StreamType mediaType; // Use the new enum
  final Duration? duration; // <<< HINZUGEFÜGT: Für lokale Dateien, wenn bekannt

  StreamItem({
    required this.id,
    required this.name,
    this.artist,
    required this.streamUrl,
    this.coverImageUrl,
    this.relativePath,
    this.isRadioStream = false,
    this.mediaType = StreamType.localFile, // Default to localFile
    this.duration, // <<< HINZUGEFÜGT
  });

  // Equality comparison to easily find items in lists
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          streamUrl == other.streamUrl; // Using ID and URL for uniqueness

  @override
  int get hashCode => id.hashCode ^ streamUrl.hashCode;

  @override
  String toString() {
    return 'StreamItem(id: $id, name: $name, artist: $artist, streamUrl: $streamUrl, '
           'coverImageUrl: $coverImageUrl, relativePath: $relativePath, '
           'isRadioStream: $isRadioStream, mediaType: $mediaType, duration: $duration)';
  }

  // Optional: A copyWith method for immutability
  StreamItem copyWith({
    String? id,
    String? name,
    String? artist,
    String? streamUrl,
    String? coverImageUrl,
    String? relativePath,
    bool? isRadioStream,
    StreamType? mediaType,
    Duration? duration, // <<< HINZUGEFÜGT
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
      duration: duration ?? this.duration, // <<< HINZUGEFÜGT
    );
  }
}
