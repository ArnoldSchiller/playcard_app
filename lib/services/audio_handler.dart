// lib/services/audio_handler.dart
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.playbackEventStream.map(_transformEvent).listen((event) {
      playbackState.add(event);
    });

    _player.sequenceStateStream.listen((event) {
      if (event?.currentSource != null) {
        final bool isRadioStream = event?.currentSource?.tag.extras?['isRadioStream'] ?? false;
        final MediaItem updatedMediaItem = MediaItem(
          id: event!.currentSource!.tag.id,
          title: event.currentSource!.tag.title,
          artist: event.currentSource!.tag.artist,
          artUri: event.currentSource!.tag.artUri,
          duration: event.currentSource?.duration,
          extras: {'isRadioStream': isRadioStream},
        );
        mediaItem.add(updatedMediaItem);
      } else {
        mediaItem.add(null);
      }
    });
  }

  @override
  Future<void> playMediaItem(MediaItem newMediaItem) async {
    mediaItem.add(newMediaItem);
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(newMediaItem.id), tag: newMediaItem),
    );
    await _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    mediaItem.add(null);
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() {
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.skipToNext],
      playing: true,
      processingState: AudioProcessingState.loading,
    ));
    return super.skipToNext();
  }

  @override
  Future<void> skipToPrevious() {
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.skipToPrevious],
      playing: true,
      processingState: AudioProcessingState.loading,
    ));
    return super.skipToPrevious();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        if (_player.playing) MediaControl.pause else MediaControl.play,
        if (_player.hasPrevious) MediaControl.skipToPrevious,
        if (_player.hasNext) MediaControl.skipToNext,
        MediaControl.stop,
      ],
      // NEU: Verwenden Sie systemActions anstelle von actions
      systemActions: const {
        MediaAction.seek, 
        MediaAction.play, 
        MediaAction.pause, 
        MediaAction.stop,
        MediaAction.skipToNext, 
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 3], 
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    );
  }
}
