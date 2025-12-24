// Fichier du bouton : par exemple lib/widgets/notification_button.dart
// VERSION CORRIGÉE ET OPTIMISÉE

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../controlers/subscription_controller.dart';

class NotificationButton extends StatelessWidget {
  final SubscriptionController controller = SubscriptionController.to;

  NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.notificationStatus.value;
      String label;
      IconData icon = Icons.notifications;
      bool enabled = true;

      switch (status) {
        case AuthorizationStatus.authorized:
          label = 'Notifications activées';
          icon = Icons.notifications_active;
          enabled = false; // déjà activé -> on désactive le bouton
          break;
        case AuthorizationStatus.provisional:
          label = 'Notifications (provisoire)';
          icon = Icons.notifications_active_outlined;
          enabled = false;
          break;
        case AuthorizationStatus.denied:
          label = 'Activer les notifications';
          icon = Icons.notifications_off;
          // Si la permission est refusée, vous pouvez soit permettre de redemander,
          // soit guider l'utilisateur vers les paramètres. Ici, on permet de redemander.
          enabled = true;
          break;
        case AuthorizationStatus.notDetermined:
        default:
          label = 'Activer les notifications';
          icon = Icons.notifications;
          enabled = true;
      }

      return ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: enabled
            // On appelle uniquement la méthode de demande. C'est tout.
            ? () => controller.requestNotificationPermission()
            : null,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    });
  }
}
