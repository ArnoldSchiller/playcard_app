import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Für @required und andere Flutter-Typen
import 'package:timezone/data/latest.dart' as tz; // Wichtig für die Initialisierung der Zeitzonen-Daten
import 'package:timezone/timezone.dart' as tz; // Für die tz.TZDateTime Klasse
import 'package:playcard_app/config/config.dart';

/// Ein Singleton-Dienst zum Verwalten von lokalen Benachrichtigungen.
class NotificationService {
  // Singleton-Instanz
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialisiert den Benachrichtigungsdienst.
  /// Muss vor dem Senden von Benachrichtigungen aufgerufen werden.
  Future<void> init() async {
    // Initialisiere Zeitzonen-Daten
    tz.initializeTimeZones(); // Dies muss einmalig aufgerufen werden

    // Android-Einstellungen
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(kNotificationIcon); 

    // iOS-Einstellungen
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialisierungseinstellungen für alle Plattformen
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialisiere das Plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('Notification tapped with payload: ${response.payload}');
        // Beispiel: Navigiere zu einem bestimmten Bildschirm basierend auf der Payload
        // if (response.payload != null) {
        //   Navigator.push(
        //     context, // Du müsstest hier einen BuildContext übergeben
        //     MaterialPageRoute(builder: (context) => DetailScreen(payload: response.payload)),
        //   );
        // }
      },
      onDidReceiveBackgroundNotificationResponse: (NotificationResponse response) async {
        debugPrint('Background notification tapped with payload: ${response.payload}');
        // Hier können Hintergrundaufgaben oder Navigation ausgeführt werden.
      },
    );
    debugPrint('NotificationService initialized.');
  }

  /// Zeigt eine einfache Benachrichtigung an.
  ///
  /// [id]: Eine eindeutige ID für die Benachrichtigung (wichtig, um sie später zu aktualisieren oder zu löschen).
  /// [title]: Der Titel der Benachrichtigung.
  /// [body]: Der Haupttext der Benachrichtigung.
  /// [payload]: Optionale Daten, die mit der Benachrichtigung verknüpft sind und beim Tippen abgerufen werden können.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      kNotificationChannelId, 
      kNotificationChannelName, 
      channelDescription: kNotificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      ongoing: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
    debugPrint('Notification shown: $title - $body');
  }

  /// Zeigt eine Benachrichtigung an, die nach einer bestimmten Zeit ausgelöst wird.
  /// Verwendet `zonedSchedule` für zeitzonenbewusste Planung.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'scheduled_channel_id',
      'Scheduled Notifications',
      channelDescription: 'Channel for scheduled notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Konvertiere DateTime zu TZDateTime, um die lokale Zeitzone zu berücksichtigen
    final tz.TZDateTime scheduledTZDateTime = tz.TZDateTime.from(
      scheduledDate,
      tz.local, // Nutzt die lokale Zeitzone des Geräts
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDateTime, // Hier wird die TZDateTime verwendet
      platformChannelSpecifics,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Wichtig für genaue Zeiten
      matchDateTimeComponents: null, // Optional: Wenn du nur bestimmte Komponenten matchen willst (z.B. nur den Tag)
    );
    debugPrint('Notification scheduled for $scheduledDate: $title - $body');
  }

  /// Bricht eine bestimmte Benachrichtigung ab.
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('Notification with ID $id cancelled.');
  }

  /// Bricht alle ausstehenden Benachrichtigungen ab.
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('All notifications cancelled.');
  }
}

