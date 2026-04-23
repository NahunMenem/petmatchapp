import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;

import '../core/constants/api_constants.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.ensureFirebaseReady();
}

class PushNotificationService {
  PushNotificationService._();

  static const String _androidChannelId = 'pawmatch_alerts_v2';
  static const String _androidChannelName = 'PawMatch';
  static const String _androidChannelDescription =
      'Notificaciones de PawMatch';
  static const fln.RawResourceAndroidNotificationSound _androidSound =
      fln.RawResourceAndroidNotificationSound('alerta');
  static const String _iosSound = 'alerta.caf';

  static final PushNotificationService instance = PushNotificationService._();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final fln.FlutterLocalNotificationsPlugin _localNotifications =
      fln.FlutterLocalNotificationsPlugin();

  static bool _firebaseReady = false;
  static bool _foregroundReady = false;
  static StreamSubscription<String>? _tokenSubscription;

  static Future<bool> ensureFirebaseReady() async {
    if (_firebaseReady) return true;
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      return true;
    } catch (error) {
      debugPrint('Firebase no esta configurado todavia: $error');
      return false;
    }
  }

  Future<void> start() async {
    final ready = await ensureFirebaseReady();
    if (!ready) return;

    await _setupForegroundNotifications();
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  Future<bool> areNotificationsEnabled() async {
    final ready = await ensureFirebaseReady();
    if (!ready) return false;

    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<bool> requestPermissionAndRegister() async {
    await registerDeviceForUser(requestPermission: true);
    return areNotificationsEnabled();
  }

  Future<void> registerDeviceForUser({bool requestPermission = false}) async {
    final ready = await ensureFirebaseReady();
    if (!ready) return;

    final settings = requestPermission
        ? await _messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          )
        : await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    if (!requestPermission &&
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await _sendToken(token);
    }

    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
      unawaited(_sendToken(newToken));
    });
  }

  Future<void> unregisterDevice() async {
    final ready = await ensureFirebaseReady();
    if (!ready) return;

    final token = await _messaging.getToken();
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    if (token == null) return;

    try {
      await ApiService().delete(
        '${ApiConstants.notificationDeviceToken}/${Uri.encodeComponent(token)}',
      );
    } catch (_) {}
  }

  Future<void> _sendToken(String token) async {
    try {
      await ApiService().post(
        ApiConstants.notificationDeviceToken,
        data: {
          'token': token,
          'platform': defaultTargetPlatform.name,
        },
      );
    } catch (_) {}
  }

  Future<void> _setupForegroundNotifications() async {
    if (_foregroundReady) return;

    const android = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = fln.DarwinInitializationSettings();
    const initSettings = fln.InitializationSettings(
      android: android,
      iOS: darwin,
    );
    await _localNotifications.initialize(initSettings);

    const channel = fln.AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: fln.Importance.high,
      playSound: true,
      sound: _androidSound,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundReady = true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const details = fln.NotificationDetails(
      android: fln.AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: fln.Importance.high,
        priority: fln.Priority.high,
        playSound: true,
        sound: _androidSound,
      ),
      iOS: fln.DarwinNotificationDetails(
        presentSound: true,
        sound: _iosSound,
      ),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['action_id'] as String?,
    );
  }
}
