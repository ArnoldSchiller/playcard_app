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
const String kNotificationIcon = kLogo; 
const String kNotificationChannelDescription = 'Media $kNotificationChannelName';
