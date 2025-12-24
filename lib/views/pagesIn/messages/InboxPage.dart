// file: lib/views/chat/inboxPage.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tendance/controlers/ColorsData.dart';
import '../../../controlers/authControler.dart';
import '../../../controlers/messageController.dart';
import 'messagesPage.dart';

class InboxPage extends StatelessWidget {
  final AuthController authController = Get.find();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final MessageController messageController = Get.find<MessageController>();
  final RxString searchQuery = ''.obs;
  final RxMap<String, Map<String, dynamic>> profilesCache = <String, Map<String, dynamic>>{}.obs;
  
  InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width >= 800;
    final Colorsdata myColors = Colorsdata();
    
    

    final user = authController.currentUser.value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final currentUserId = user.id;

    Widget chatListBuilder(List<QueryDocumentSnapshot<Map<String, dynamic>>> chatDocs) {
      return Obx(() {
        final filteredChats = chatDocs.where((doc) {
          final parts = doc.id.split('_');
          final otherUserId = parts[0] == currentUserId ? parts[1] : parts[0];
          final profile = profilesCache[otherUserId];
          if (profile == null) return true;
          final username = (profile['username'] ?? '').toString().toLowerCase();
          return username.contains(searchQuery.value.toLowerCase());
        }).toList();

        if (filteredChats.isEmpty) return const Center(child: Text("Aucune conversation"));

        return ListView.builder(
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            
            final chatDoc = filteredChats[index];
            final data = chatDoc.data();
            final parts = chatDoc.id.split('_');
            final otherUserId = parts[0] == currentUserId ? parts[1] : parts[0];

            final profile = profilesCache[otherUserId];
            final username = profile?['username'] ?? 'Utilisateur';
            final photoUrl = profile?['photoUrl'];

            // Précharger le profil si pas encore en cache
            if (!profilesCache.containsKey(otherUserId)) {
              firestore.collection('profiles').doc(otherUserId).get().then((snap) {
                if (snap.exists) profilesCache[otherUserId] = snap.data()!;
              });
            }

            final lastMessage = data['lastMessage'] ?? '';
            final timestamp = (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now();
            final unread = List<String>.from(data['unread'] ?? []);
            final lastStatus = data['lastMessageStatus'];
            final lastSenderId = data['lastMessageSenderId'];

            
            

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 125, 41, 35),
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    : null,
              ),
              title: Text(username,
                  overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Row(
                children: [

                  // 🔥 RÉCUPÉRER UNIQUEMENT LE STATUT, SANS TOUCHER LA LOGIQUE
                                  FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  // ↪️ CHANGER : prendre la sous-collection messages du chat
                  future: firestore
                      .collection('chats')
                      .doc(chatDoc.id)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .get(),
                  builder: (context, msgSnapshot) {
                    if (!msgSnapshot.hasData || msgSnapshot.data!.docs.isEmpty) {
                      return const SizedBox(); // pas d’icône le temps du chargement ou s'il n'y a pas de message
                    }

                    final msg = msgSnapshot.data!.docs.first.data();
                    final lastStatus = msg['status'];
                    final lastSenderId = msg['senderId'];

                    // n'affiche l'icône que si c'est bien un message envoyé par moi
                    if (lastSenderId != currentUserId) return const SizedBox();

                    return Row(
                      children: [
                        _buildStatusIcon(lastStatus),
                        const SizedBox(width: 4),
                      ],
                    );
                  },
                ),


                  // 🔥 LE RESTE NE CHANGE PAS
                  Expanded(
                    child: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (unread.contains(currentUserId))
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                ],
              ),
              selected: messageController.selectedReceiverId.value == otherUserId,
              selectedTileColor: myColors.buttonHover.withOpacity(0.1),
              onTap: () {
                if (isLargeScreen) {
                  messageController.selectConversation(
                    receiverId: otherUserId,
                    receiverName: username,
                    receiverPhotoUrl: photoUrl,
                  );
                } else {
                  Get.to(() => ChatPage(
                        receiverId: otherUserId,
                        receiverName: username,
                        receiverPhotoUrl: photoUrl,
                      ));
                }
              },
            );
          },
        );
      });
    }

    return Scaffold(
      backgroundColor: myColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Discussions",
            style: TextStyle(color: Colors.black, fontSize: isLargeScreen ? 24 : 20, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: TextField(
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: "Rechercher par nom...",
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.grey.shade100,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestore.collection('chats').orderBy('lastMessageTime', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final chatDocs = snapshot.data!.docs.where((doc) => doc.id.contains(currentUserId)).toList();

                return isLargeScreen
                    ? Row(
                        children: [
                          SizedBox(width: width * 0.35, child: chatListBuilder(chatDocs)),
                          VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade300),
                          Expanded(
                            child: Obx(() {
                              if (messageController.selectedReceiverId.value == null) {
                                return const Center(
                                    child: Text("Sélectionnez une conversation pour commencer",
                                        style: TextStyle(fontSize: 18, color: Colors.grey)));
                              } else {
                                return ChatPage(
                                  receiverId: messageController.selectedReceiverId.value!,
                                  receiverName: messageController.selectedReceiverName.value!,
                                  receiverPhotoUrl: messageController.selectedReceiverPhotoUrl.value,
                                  isTwoPane: true,
                                );
                              }
                            }),
                          ),
                        ],
                      )
                    : chatListBuilder(chatDocs);
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildStatusIcon(String? status) {
  switch (status) {
    case 'sent':
      return const Icon(Icons.check, size: 15, color: Colors.grey);
    case 'delivered':
      return Stack(
        alignment: Alignment.centerLeft,
        children: const [
          Icon(Icons.check, size: 15, color: Colors.grey),
          Positioned(left: 4, child: Icon(Icons.check, size: 15, color: Colors.grey)),
        ],
      );
    case 'read':
      return Stack(
        alignment: Alignment.centerLeft,
        children: const [
          Icon(Icons.check, size: 15, color: Colors.blue),
          Positioned(left: 4,  child: Icon(Icons.check, size: 15, color: Colors.blue)),
        ],
      );
    default:
      return const SizedBox();
  }
}
