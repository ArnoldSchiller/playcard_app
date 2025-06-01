// lib/screens/radio_status_screen.dart
/*
Importiert config.dart für material.dart, constants.dart, app_theme.dart.

Explizite Imports für Song, MediaPlayerProvider, SearchProvider, etc.


*/
import 'package:playcard_app/config/config.dart';
import 'package:playcard_app/widgets/playcard_app_bar.dart';
import 'package:playcard_app/widgets/radio_streams_list.dart';
import 'package:playcard_app/widgets/search_results_list.dart';
import 'package:playcard_app/screens/now_playing_screen.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _launchAudio(String url, BuildContext context) async {
  if (url.isNotEmpty && Uri.tryParse(url)?.isAbsolute == true) {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open URL: $url')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid URL to open.')),
    );
  }
}

class RadioStatusScreen extends StatefulWidget {
  const RadioStatusScreen({super.key});

  @override
  State<RadioStatusScreen> createState() => _RadioStatusScreenState();
}

class _RadioStatusScreenState extends State<RadioStatusScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _radioStreamsFuture;

  @override
  void initState() {
    super.initState();
    _radioStreamsFuture = _fetchRadioStreams();
  }

  Future<List<Map<String, dynamic>>> _fetchRadioStreams() async {
    try {
      final response = await _apiService.fetchRadioStatus();
      print('Radio API response: $response');
      final List<dynamic> rawStreams = response['radio_streams'] ?? [];
      if (rawStreams.isEmpty) {
        print('No radio streams found');
      }
      return List<Map<String, dynamic>>.from(rawStreams);
    } catch (e) {
      print('Error fetching radio streams: $e');
      throw Exception('Error fetching radio streams: $e');
    }
  }

  void _playSong(Song song) {
    print('Attempting to play song: ${song.name}, URL: ${song.streamUrl}');
    if (song.streamUrl.isEmpty || Uri.tryParse(song.streamUrl)?.isAbsolute != true) {
      print('Invalid stream URL: ${song.streamUrl}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid stream URL for this song.')),
      );
      return;
    }
    final mediaPlayerProvider = context.read<MediaPlayerProvider>();
    try {
      mediaPlayerProvider.play(song);
      print('Song sent to internal player: ${song.streamUrl}');
    } catch (e) {
      print('Error with internal player: $e');
      _launchAudio(song.streamUrl, context);
    }
    final searchProvider = context.read<SearchProvider>();
    if (searchProvider.searchController.text.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const NowPlayingScreen(),
          fullscreenDialog: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final mediaPlayerProvider = context.watch<MediaPlayerProvider>();

    return WillPopScope(
      onWillPop: () async {
        if (mediaPlayerProvider.currentSong != null) {
          mediaPlayerProvider.stop();
          return true;
        }
        return !Navigator.of(context).canPop();
      },
      child: Scaffold(
        appBar: PlaycardAppBar(
          title: kAppName,
          searchController: searchProvider.searchController,
          onSearchChanged: (text) {},
          hintText: 'Search songs, artists, or genres...',
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: searchProvider.isSearching &&
                          searchProvider.searchResults.isNotEmpty
                      ? SearchResultsList(
                          searchResults: searchProvider.searchResults,
                          isLoadingSearch: searchProvider.isLoadingSearch,
                          errorMessageSearch: searchProvider.errorMessageSearch,
                          onSongTap: _playSong,
                        )
                      : (searchProvider.isSearching &&
                              searchProvider.searchResults.isEmpty &&
                              !searchProvider.isLoadingSearch)
                          ? const Center(child: Text('No search results found.'))
                          : RadioStreamsList(
                              radioStreamsFuture: _radioStreamsFuture,
                              onPlayStream: _playSong,
                            ),
                ),
                if (mediaPlayerProvider.currentSong != null)
                  Material(
                    elevation: 8.0,
                    child: Container(
                      color: Theme.of(context).cardColor,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          mediaPlayerProvider.currentSong!.coverImageUrl != null &&
                                  mediaPlayerProvider.currentSong!.coverImageUrl!.isNotEmpty
                              ? Image.network(
                                  mediaPlayerProvider.currentSong!.coverImageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.music_note, size: 50),
                                )
                              : const Icon(Icons.music_note, size: 50),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mediaPlayerProvider.currentSong!.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  mediaPlayerProvider.currentSong!.artist ?? 'Unknown Artist',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            onPressed: () {
                              mediaPlayerProvider.stop();
                              Navigator.pop(context);
                            },
                          ),
                          IconButton(
                            icon: Icon(mediaPlayerProvider.isPlaying ? Icons.pause : Icons.play_arrow),
                            onPressed: () {
                              mediaPlayerProvider.playOrPause();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            onPressed: () {
                              mediaPlayerProvider.playNextRandom();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_full),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const NowPlayingScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
