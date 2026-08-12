import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// خدمة الإشعارات المحلية (تنبيه دخول جهاز جديد).
class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  Future<void> showNewDevice(String name, String detail) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'new_device',
        'دخول جهاز جديد',
        channelDescription: 'ينبّه عند اتصال جهاز جديد بالشبكة',
        importance: Importance.max,
        priority: Priority.high,
        color: null,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '⚠️ جهاز جديد على شبكتك',
      '$name — $detail',
      details,
    );
  }
}
