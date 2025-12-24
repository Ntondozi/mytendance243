// file: lib/services/notification_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Créez un canal de notification pour Android (nécessaire pour Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // ID unique du canal
      'High Importance Notifications', // Nom visible par l'utilisateur
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    // Enregistrez le canal auprès du plugin
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialisation pour Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialisation pour iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialisation globale
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static void showNotification(RemoteMessage message) {
    if (message.notification != null) {
      _flutterLocalNotificationsPlugin.show(
        message.hashCode, // Un ID unique pour la notification
        message.notification!.title,
        message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // ID du canal (doit correspondre à celui créé ci-dessus)
            'High Importance Notifications', // Nom du canal
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/notification_icon', // Utilise l'icône que vous avez ajoutée
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['notificationId'] ?? '', // Pour identifier la notification si l'utilisateur clique dessus
      );
    }
  }
}
