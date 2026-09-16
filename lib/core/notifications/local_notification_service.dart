import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _plugin.initialize(settings);
    _initialized = true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'chat_messages',
      'Chat messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
    ));
  }

  Future<void> requestPermission() async {
    await initialize();

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final darwinPlugin = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
    await darwinPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> showChatMessage({
    required String sender,
    required String message,
  }) async {
    await initialize();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      'New message from $sender',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat messages',
          channelDescription: 'Notifications for new chat messages',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}