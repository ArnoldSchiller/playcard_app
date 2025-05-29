// lib/utils/app_startup.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:playcard_app/player/media_kit_initializer.dart';
import 'package:playcard_app/providers/search_provider.dart';
import 'package:playcard_app/config/constants.dart';
import 'package:playcard_app/providers/media_player_provider.dart';
import 'package:flutter/services.dart';
import 'package:audio_service_platform_interface/no_op_audio_service.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:playcard_app/services/audio_handler.dart';

class AppStartup {
    static Future<void> initializeApp() async {
    // Sicherstellen, dass WidgetsBinding initialisiert ist
    WidgetsFlutterBinding.ensureInitialized();

    // 1. MediaKit initialisieren
    ////print('AppStartup: Initialisiere MediaKit...');
    initializeMediaKitIfNeeded();
    ////print('AppStartup: MediaKit Initialisierung abgeschlossen.');
    ////print('AppStartup: JustAudioMediaKit initialisieren
    JustAudioMediaKit.protocolWhitelist = [
      "http",
      "https",
      "file", // notice how we allow the file protocol when reading assets!
    ];
    JustAudioMediaKit.ensureInitialized(
    linux: true,            // default: true  - dependency: media_kit_libs_linux
    windows: true,          // default: true  - dependency: media_kit_libs_windows_audio
    android: true,          // default: false - dependency: media_kit_libs_android_audio
    iOS: true,              // default: false - dependency: media_kit_libs_ios_audio
    macOS: true,            // default: false - dependency: media_kit_libs_macos_audio
    );  
    // 2. Andere wichtige Initialisierungen (asynchron)
    // Hier könnten zukünftig weitere Dienste oder Bibliotheken initialisiert werden.
    // Beispiel:
    // await Firebase.initializeApp();
    // await SentryFlutter.init(...);
    // await SharedPreferences.getInstance(); // Für lokale Daten
     // Jetzt AudioService mit Ihrem neuen Handler initialisieren
    await AudioService.init(
       builder: () => AudioPlayerHandler(), // <-- Hier Ihre neue Klasse einfügen!
  	);
    // Simuliere eine kurze Ladezeit, damit der Splash Screen sichtbar ist
    await Future.delayed(const Duration(milliseconds: 150));

    ////print('AppStartup: Alle Initialisierungen abgeschlossen.');
  }

  // Dies ist eine Hilfsfunktion, um die Provider zentral zu definieren
  // und in `main.dart` zu verwenden.
  static Widget setupProviders({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => MediaPlayerProvider()), // <--- HIER DEN NEUEN PROVIDER HINZUFÜGEN
        // Zukünftige Provider können hier einfach hinzugefügt werden
      ],
      child: child,
    );
  }
}
