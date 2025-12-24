// import 'package:flutter/material.dart';
// import 'package:pwa_install/pwa_install.dart';

// class InstallPwaButton extends StatefulWidget {
//   const InstallPwaButton({super.key});

//   @override
//   State<InstallPwaButton> createState() => _InstallPwaButtonState();
// }

// class _InstallPwaButtonState extends State<InstallPwaButton> {
//   String? message;

//   void _handleInstall() {
//     // Vérifie si le bouton peut déclencher l'installation
//     if (PWAInstall().installPromptEnabled) {
//       try {
//         PWAInstall().promptInstall_();
//       } catch (e) {
//         setState(() {
//           message = "Erreur lors de l'installation : $e";
//         });
//       }
//     } else {
//       setState(() {
//         message = "Installation non disponible ou déjà installée";
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         ElevatedButton(
//           onPressed: _handleInstall,
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           ),
//           child: Text(
//             PWAInstall().installPromptEnabled
//                 ? "Installer l'application"
//                 : "Application déjà installée / non installable",
//           ),
//         ),
//         if (message != null)
//           Padding(
//             padding: const EdgeInsets.only(top: 8),
//             child: Text(
//               message!,
//               style: const TextStyle(
//                   fontWeight: FontWeight.bold, color: Colors.red),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         const SizedBox(height: 10),
//         Text('Launch Mode: ${PWAInstall().launchMode?.shortLabel ?? "Browser"}'),
//         Text('Has Install Prompt: ${PWAInstall().hasPrompt}'),
//       ],
//     );
//   }
// }
