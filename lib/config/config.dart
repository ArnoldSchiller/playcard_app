//lib/config/config.dart
//für Random
// Für ChangeNotifierProvider, MultiProvider
// ein paar Konstanten wird schon bei app_startup gebraucht
// Das Theme der App
// "Dummer" Audiohandler für audio service
// Für ApiService
// suche über die api siehe constants.dart
// füttert audio_handler.dart je nach click
// Für StreamItem
// Hintergrundservice der audio_handlert
// Notification Hindergrundservice

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
export 'package:playcard_app/models/stream_item.dart'; // Für StreamItem
export 'package:audio_service/audio_service.dart'; 
export 'package:playcard_app/utils/notification.dart';
export 'package:playcard_app/models/stream_item.dart';
export 'package:playcard_app/config/routes.dart';
export 'package:playcard_app/screens/home_screen.dart';
export 'package:playcard_app/screens/now_playing_screen.dart';
// lib/providers/media_player_provider.dart

