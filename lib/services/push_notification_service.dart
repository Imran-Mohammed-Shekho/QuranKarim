import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';
import 'notification_localization.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background push message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService({required NotificationService notificationService})
    : _notificationService = notificationService;

  final NotificationService _notificationService;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _initialized = false;
  String? _token;

  String? get token => _token;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (_initialized || !isSupported) {
      return;
    }

    await Firebase.initializeApp();
    await _notificationService.initialize();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notification permission denied.');
    }

    await _notificationService.ensurePermissions();

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _token = await messaging.getToken();
    if (_token != null) {
      debugPrint('FCM token: $_token');
    }

    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) {
      _token = token;
      debugPrint('FCM token refreshed: $token');
    });

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }

    _initialized = true;
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final language = await NotificationLocalization.loadCurrentLanguage();
    final content = NotificationLocalization.resolvePushContent(
      data: message.data,
      language: language,
      fallbackTitle: notification?.title,
      fallbackBody: notification?.body,
    );
    final title = content.title;
    final body = content.body;

    if (title == null || body == null) {
      debugPrint(
        'Foreground push received without title/body: ${message.data}',
      );
      return;
    }

    await _notificationService.showPushNotification(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    debugPrint(
      'Push notification opened: messageId=${message.messageId}, data=${message.data}',
    );
  }
}
