//lib/config/config.dart
import 'dart:math'; //für Random
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Für ChangeNotifierProvider, MultiProvider
import 'package:playcard_app/config/constants.dart'; // ein paar Konstanten wird schon bei app_startup gebraucht
import 'package:playcard_app/config/app_theme.dart'; // Das Theme der App
import 'package:playcard_app/services/audio_handler.dart'; // "Dummer" Audiohandler für audio service
import 'package:playcard_app/services/api_service.dart'; // Für ApiService
import 'package:playcard_app/providers/search_provider.dart'; // suche über die api siehe constants.dart
import 'package:playcard_app/providers/media_player_provider.dart'; // füttert audio_handler.dart je nach click
import 'package:playcard_app/models/song.dart'; // Für Song
import 'package:audio_service/audio_service.dart'; // Hintergrundservice der audio_handlert

// Ja ist eine Wiederholung, die exports funktionierenten bei einigen, 
// aber bei der app_startup.dart wollte es nicht deswegen die imports oben.
export 'dart:math';
export 'package:flutter/material.dart';   
export 'package:provider/provider.dart'; // Für ChangeNotifierProvider, MultiProvider
export 'package:playcard_app/config/constants.dart';
export 'package:playcard_app/config/app_theme.dart';
export 'package:playcard_app/services/audio_handler.dart';
export 'package:playcard_app/services/api_service.dart'; // Für ApiService
export 'package:playcard_app/providers/search_provider.dart';
export 'package:playcard_app/providers/media_player_provider.dart';
export 'package:playcard_app/models/song.dart'; // Für Song
export 'package:audio_service/audio_service.dart';
