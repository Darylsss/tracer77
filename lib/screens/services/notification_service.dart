import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      'tracer77_sos',
      'Alertes SOS',
      description: "Notifications d'alerte SOS Tracer77",
      importance: Importance.max,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation
        <AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);
    await androidImpl?.requestNotificationsPermission();
  }

  static Future<void> showSosAlert(String message) async {
    const androidDetails = AndroidNotificationDetails(
      'tracer77_sos',
      'Alertes SOS',
      channelDescription: "Notifications d'alerte SOS Tracer77",
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Alerte SOS',
      message,
      details,
    );
  }
}