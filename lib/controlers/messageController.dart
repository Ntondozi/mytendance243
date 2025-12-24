// file: lib/controlers/messageController.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendance/services/notificationChat_service.dart';
import 'package:tendance/views/pagesIn/messages/messagesPage.dart';

class MessageController extends GetxController {
  // Store the ID of the currently selected receiver for large screens
  // This will be null if no conversation is selected, or on small screens
  final RxnString selectedReceiverId = RxnString();
  final RxnString selectedReceiverName = RxnString();
  final RxnString selectedReceiverPhotoUrl = RxnString();

  // --- NOUVEAU CODE CI-DESSOUS ---

  @override
  void onInit() {
    super.onInit();
    _setupPushNotifications(); // 5. Lancer la configuration des notifications
  }

 void _setupPushNotifications() {
    // Gère uniquement la notification quand l'application est AU PREMIER PLAN
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Message reçu au premier plan : ${message.data}");
        // On utilise notre service pour afficher la notif personnalisée
        NotificationChatService().showChatNotification(message);
    });

    // onMessageOpenedApp est maintenant géré par onDidReceiveNotificationResponse
    // dans le service, donc on peut le supprimer d'ici.
  }

  void selectConversation({
    required String receiverId,
    required String receiverName,
    String? receiverPhotoUrl,
  }) {
    selectedReceiverId.value = receiverId;
    selectedReceiverName.value = receiverName;
    selectedReceiverPhotoUrl.value = receiverPhotoUrl;
  }

  void clearSelection() {
    selectedReceiverId.value = null;
    selectedReceiverName.value = null;
    selectedReceiverPhotoUrl.value = null;
  }
}
