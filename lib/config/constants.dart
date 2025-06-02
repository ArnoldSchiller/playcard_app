//lib/config/constants.dart
/*
import in /lib/config/config.dart
*/
const String kBaseUrl = 'https://jaquearnoux.de/playcard/'; //replace this with your playcard-server
const String kApiUrl = '$kBaseUrl/api'; 

// NEU: App-Name als Konstante
const String kAppName = 'Playcard';
const String kLogo = 'assets/radio.png';
const String kNotificationChannelId = 'de.jaquearnoux.playcard_app.channel.audio';
const String kNotificationChannelName = '$kAppName Audio Playback'; // Etwas spezifischer
const String kNotificationIcon = 'drawable/ic_stat_jaquearnoux_radio'; 
const String kNotificationChannelDescription = 'Media $kNotificationChannelName';

// Definiere Konstanten für Benachrichtigungs-IDs
const int kNowPlayingNotificationId = 1001; // Eindeutige ID für die aktive Wiedergabe-Benachrichtigung
const int kReminderNotificationBaseId = 2000; // Basis-ID für geplante Erinnerungen

// Definiere Konstanten für Benachrichtigungs-Aktions-IDs
const String kNotificationActionPrevious = 'previous';
const String kNotificationActionPlay = 'play';
const String kNotificationActionPause = 'pause';
const String kNotificationActionNext = 'next';

