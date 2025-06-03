// lib/core/app_startup.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:playcard_app/config/config.dart';
import 'package:playcard_app/player/audio_service_initializer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

enum SupportedPlatform {
  android,
  ios,
  linux,
  windows,
  macos,
  web,
  unknown,
}

class AppStartup {
  static bool _isInitialized = false;
  static SupportedPlatform currentPlatform = SupportedPlatform.unknown;

  static T createPlatformHandler<T>({
    required T Function() android,
    required T Function() ios,
    required T Function() linux,
    required T Function() windows,
    required T Function() macos,
    required T Function() web,
    required T Function() defaultHandler,
  }) {
    switch (currentPlatform) {
      case SupportedPlatform.android:
        return android();
      case SupportedPlatform.ios:
        return ios();
      case SupportedPlatform.linux:
        return linux();
      case SupportedPlatform.windows:
        return windows();
      case SupportedPlatform.macos:
        return macos();
      case SupportedPlatform.web:
        return web();
      case SupportedPlatform.unknown:
      default:
        return defaultHandler();
    }
  }
  static Future<void> requestIgnoreBatteryOptimizations() async {
 		 if (Platform.isAndroid) {
     			final status = await Permission.ignoreBatteryOptimizations.request();
     		 	if (status.isGranted) {
       				print('Battery optimization disabled');
     		 	} else {
       				print('Battery optimization permission denied');
     		 	}
   		   }
 		}
 
  
  static Future<void> init() async {
    if (_isInitialized) {
      print('AppStartup: Already initialized, skipping.');
      return;
    }
    WidgetsFlutterBinding.ensureInitialized();

    // Plattform bestimmen
    if (kIsWeb) {
      currentPlatform = SupportedPlatform.web;
    } else {
      try {
        if (Platform.isAndroid) {
          currentPlatform = SupportedPlatform.android;
	  await requestIgnoreBatteryOptimizations();
        } else if (Platform.isIOS) {
          currentPlatform = SupportedPlatform.ios;
        } else if (Platform.isLinux) {
          currentPlatform = SupportedPlatform.linux;
        } else if (Platform.isWindows) {
          currentPlatform = SupportedPlatform.windows;
        } else if (Platform.isMacOS) {
          currentPlatform = SupportedPlatform.macos;
        } else {
          currentPlatform = SupportedPlatform.unknown;
        }
      } catch (e) {
        print('Fehler bei der Plattform-Erkennung: $e');
        currentPlatform = SupportedPlatform.unknown;
      }
    }
    print('AppStartup: Plattform festgelegt auf $currentPlatform');

    // Initialisiere den NotificationService
    try {
      await NotificationService().init();
      print('NotificationService initialized.');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }


    try {
      // Initialisiere AudioService
      await initializeAudioServiceIfNeeded();
    } catch (e) {
      print('Error during initialization: $e');
    }

    _isInitialized = true;
    print('AppStartup: Initialization completed.');
  }


  static Widget build({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => MediaPlayerProvider()),
        // VideoPlayerProvider wird später hinzugefügt, nachdem wir ihn korrekt eingerichtet haben
      ],
      child: child,
    );
  }
}
