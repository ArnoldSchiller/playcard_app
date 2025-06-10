// lib/screens/now_playing_screen.dart
import 'package:playcard_app/config/config.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});
  

  @override
  Widget build(BuildContext context) {
    final mediaPlayerProvider = context.watch<MediaPlayerProvider>();
    final StreamItem? currentSong = mediaPlayerProvider.currentSong;

    // Bestimmen, ob es sich um einen Live-Stream handelt
    // Ein Live-Stream hat oft eine Dauer von Duration.zero oder Duration.infinity
    // oder einfach eine sehr große Dauer, die nicht seekbar ist.
    // Hier nutzen wir currentDuration == Duration.zero als Indikator.
    // Sie könnten auch prüfen, ob currentDuration.inSeconds < 1 oder ähnliches ist.
    final bool isLiveStream = mediaPlayerProvider.currentDuration == Duration.zero;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
      ),
      body: currentSong == null
          ? const Center(child: Text('No song is currently playing.'))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentSong.coverImageUrl != null && currentSong.coverImageUrl!.isNotEmpty)
                  Image.network(
                    currentSong.coverImageUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.music_note, size: 200),
                  )
                else
                  const Icon(Icons.music_note, size: 200),
                const SizedBox(height: 16),
                Text(
                  currentSong.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  currentSong.artist ?? 'Unknown Artist',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () {
                        mediaPlayerProvider.stop();
                        
                      },
                    ),
		    IconButton(
			   icon: Icon(
                             mediaPlayerProvider.isProcessing
			     ? Icons.hourglass_empty // Or a CircularProgressIndicator
			     : mediaPlayerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
			   ),
			   onPressed: mediaPlayerProvider.isProcessing ? null : () { // Disable when processing
			   mediaPlayerProvider.playOrPause();
		   	},
		    ),	
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {
                        mediaPlayerProvider.playNextRandom();
                      },
                    ),
                  ],
                ),
                // === HIER IST DIE WICHTIGE ÄNDERUNG FÜR DEN SLIDER ===
                if (!mediaPlayerProvider.isBuffering && !isLiveStream) // Nur anzeigen, wenn nicht puffert UND NICHT LIVE-STREAM
                  Slider(
                    value: mediaPlayerProvider.currentPosition.inSeconds.toDouble(),
                    min: 0,
                    // Die max-Property muss einen sinnvollen Wert haben.
                    // Wenn currentDuration 0 ist (Live-Stream), setzen wir max auf einen kleinen Wert (z.B. 1.0),
                    // aber da wir den Slider für Live-Streams ausblenden, sollte das hier kein Problem mehr sein.
                    // Der .clamp ist gut, um sicherzustellen, dass es mindestens 1.0 ist,
                    // falls die Dauer mal kurzzeitig 0 oder kleiner als 1 ist.
                    max: mediaPlayerProvider.currentDuration.inSeconds.toDouble().clamp(1.0, double.infinity),
                    onChanged: (value) {
                      mediaPlayerProvider.seek(Duration(seconds: value.toInt()));
                    },
                  )
                else if (mediaPlayerProvider.isBuffering) // Nur anzeigen, wenn puffert
                  const CircularProgressIndicator()
                else if (isLiveStream) // Wenn es ein Live-Stream ist, zeigen wir keinen Slider, vielleicht nur einen Text
                  const Text('Live Stream') // Oder ein leeres SizedBox(), wenn Sie nichts anzeigen wollen
                , // Komma am Ende des Conditional-Widgets

                Text(
                  // Überprüfen Sie, ob currentDuration.inSeconds gültig ist, um die Anzeige zu steuern
                  isLiveStream
                      ? 'Live' // Oder eine andere Anzeige für Live-Streams
                      : '${mediaPlayerProvider.currentPosition.inMinutes}:${(mediaPlayerProvider.currentPosition.inSeconds % 60).toString().padLeft(2, '0')} / '
                        '${mediaPlayerProvider.currentDuration.inMinutes}:${(mediaPlayerProvider.currentDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                ),
              ],
            ),
    );
  }
}
