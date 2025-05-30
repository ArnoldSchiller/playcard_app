import 'package:playcard_app/config/config.dart';
import 'package:provider/provider.dart'; // Korrigiert
import 'package:playcard_app/providers/media_player_provider.dart';

class VideoControls extends StatefulWidget {
  const VideoControls({super.key});

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaPlayerProvider>();

    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: () {
                  provider.stop();
                  Navigator.pop(context);
                },
              ),
              IconButton(
                icon: Icon(
                  provider.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: () => provider.playOrPause(),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: () => provider.playNextRandom(),
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  provider.stop();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!provider.isBuffering)
            Slider(
              value: provider.currentPosition.inSeconds.toDouble(),
              max: provider.currentDuration.inSeconds.toDouble() > 0
                  ? provider.currentDuration.inSeconds.toDouble()
                  : 1.0,
              onChanged: (value) {
                provider.seek(Duration(seconds: value.toInt()));
              },
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
            )
          else
            const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
