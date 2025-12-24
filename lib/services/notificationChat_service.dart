// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../views/pagesIn/messages/messagesPage.dart';

class NotificationChatService {
  // Singleton pour un accès facile
  static final NotificationChatService _instance = NotificationChatService._internal();
  factory NotificationChatService() => _instance;
  NotificationChatService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // --- Initialisation pour Android ---
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher'); // Utilisez l'icône de votre app

    // --- Initialisation pour iOS ---
    // Gère les permissions
    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      settings,
      // Gère le clic sur la notification lorsque l'app est au premier plan
      onDidReceiveNotificationResponse: _onSelectNotification,
      onDidReceiveBackgroundNotificationResponse: _onSelectNotification,
    );
  }

  // --- Méthode pour AFFICHER la notification de chat ---
  Future<void> showChatNotification(RemoteMessage message) async {
    final senderId = message.data['senderId'];
    final senderName = message.data['senderName'];
    final messageBody = message.data['messageBody'];
    final chatId = message.data['chatId'];

    if (senderId == null || senderName == null || messageBody == null) return;

    // --- Style de notification pour Android (simule une conversation) ---
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_messages_channel', // ID du canal
      'Messages de Chat',
      channelDescription: 'Notifications pour les nouveaux messages de chat.',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: MessagingStyleInformation(
        const Person(name: "Moi"), // L'utilisateur actuel
        conversationTitle: senderName,
        messages: [
           Message(messageBody,  DateTime.now(),  Person(key: senderId, name: senderName)),
        ],
      ),
      // --- Action de Réponse Rapide ---
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'reply_action',
          'Répondre',
          inputs: <AndroidNotificationActionInput>[
             AndroidNotificationActionInput(
              label: 'Votre réponse...',
            ),
          ],
        ),
      ],
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Afficher la notification
    await _localNotifications.show(
      senderId.hashCode, // Un ID unique pour la notification
      senderName,
      messageBody,
      notificationDetails,
      payload: senderId, // On passe l'ID de l'expéditeur pour la navigation
    );
  }
}

// --- Gère le clic sur la notification ---
@pragma('vm:entry-point')
void _onSelectNotification(NotificationResponse response) async {
  final String? payload = response.payload; // C'est le senderId
  if (payload != null) {
    try {
      // Logique de navigation (similaire à ce que vous aviez dans MessageController)
      DocumentSnapshot userSnap = await FirebaseFirestore.instance.collection('profiles').doc(payload).get();
      if (userSnap.exists) {
        final userData = userSnap.data() as Map<String, dynamic>;
        Get.to(() => ChatPage(
              receiverId: payload,
              receiverName: userData['username'] ?? 'Utilisateur',
              receiverPhotoUrl: userData['photoUrl'],
            ));
      }
    } catch (e) {
      print("Erreur de navigation depuis la notif locale : $e");
    }
  }
}
