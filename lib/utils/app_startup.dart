import 'package:playcard_app/config/config.dart';

class AppStartup {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) {
      print('AppStartup: Already initialized, skipping.');
      return;
    }
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await AudioService.init<AudioPlayerHandler>(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: kNotificationChannelId,
          androidNotificationChannelName: kNotificationChannelName,
          androidNotificationOngoing: true,
        ),
      );
      print('AudioService initialized.');
    } catch (e) {
      print('Error initializing AudioService: $e');
    }
    _isInitialized = true;
    print('AppStartup: Initialization completed.');
  }

  static Widget build({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => MediaPlayerProvider()),
      ],
      child: child,
    );
  }
}
