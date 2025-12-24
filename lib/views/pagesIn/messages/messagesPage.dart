// file: lib/views/chat/chatPage.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:tendance/controlers/ColorsData.dart';
import 'package:tendance/models/messageModel.dart';
import '../../../controlers/authControler.dart';
import 'profilReceiver.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;
  final bool isTwoPane;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
    this.isTwoPane = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AuthController authController = Get.find();
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final Colorsdata myColors = Colorsdata();
  String? _floatingDate;

  // messages en mémoire (GetX)
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  // map d'éléments pour détecter la visibilité par message (clé unique par message)
  final Map<String, GlobalKey> _messageKeys = {};
  // éviter d'envoyer plusieurs fois la mise à jour "read" pour un même message
  final Set<String> _markedReadLocal = {};

  StreamSubscription<QuerySnapshot>? _messagesSub;
  bool _initialScrollDone = false;

  String get chatId {
    final currentUserId = authController.currentUser.value!.id;
    return currentUserId.hashCode <= widget.receiverId.hashCode
        ? '${currentUserId}_${widget.receiverId}'
        : '${widget.receiverId}_${currentUserId}';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _listenMessages();
    _listenPendingToSent();
    // Ne pas marquer "read" automatiquement ici !
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  // -------------------------
  // LISTENERS / SYNC FIRESTORE
  // -------------------------
  void _listenMessages() {
    final messagesRef = firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true);

    _messagesSub = messagesRef.snapshots().listen((snap) {
      final currentUserId = authController.currentUser.value!.id;

      // Construire la liste locale depuis les docs
      final newMessages = snap.docs.map((doc) {
        final data = doc.data();
        return ChatMessage.fromMap(
          data,
          id: doc.id,
          hasPendingWrites: doc.metadata.hasPendingWrites,
        );
      }).toList();

      // Mettre à jour l'observable
      messages.assignAll(newMessages);

      // Créer des GlobalKeys pour chaque message si nécessaire
      for (var msg in newMessages) {
        if (msg.id != null && !_messageKeys.containsKey(msg.id)) {
          _messageKeys[msg.id!] = GlobalKey();
        }
      }

            // 🔥 Marquer immédiatement les nouveaux messages visibles comme "read"
      for (var msg in newMessages) {
        final key = _messageKeys[msg.id];
        if (key != null && _isMessageVisible(key)) {
          _markMessageReadOnVisible(msg);
        }
      }


      // Marquer delivered pour messages destinés à moi qui sont en 'sent'
      // (c'est la livraison côté destinataire, mais pas 'read')
      for (var doc in snap.docs) {
  final data = doc.data();
  final status = data['status'] ?? 'pending';
  final receiverId = data['receiverId'];

  // si je suis destinataire et le message vient d'être envoyé → delivered
  if (receiverId == currentUserId && status == 'sent') {
    doc.reference.update({
      'status': 'delivered',
      'deliveredAt': FieldValue.serverTimestamp(),
    }).then((_) {
      firestore.collection('chats').doc(chatId).update({
        'lastMessageStatus': 'delivered',
      });
    });
  }
}


      // En s'assurant de détecter les messages visibles après mise à jour de la liste
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkVisibleMessagesAndMarkRead();
        if (!_initialScrollDone) {
          // garder la vue en bas (dernier message) à l'ouverture
          _scrollToBottom(animate: false);
          _initialScrollDone = true;
        }
      });
    });
  }
  
  

  // Listener pour transformer pending (local) => sent (après commit serveur)
  void _listenPendingToSent() {
    final messagesRef = firestore.collection('chats').doc(chatId).collection('messages');

    messagesRef.snapshots().listen((snap) async {
      for (var doc in snap.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        final hasPending = doc.metadata.hasPendingWrites;

                  // Ce listener ne s'occupe QUE de "pending → sent"
          // Jamais autre chose.
          if (!hasPending && status == 'pending') {
            await doc.reference.update({
              'status': 'sent',
              'sentAt': FieldValue.serverTimestamp(),
            });

          // Mettre à jour uniquement si c'est vraiment le dernier message
          final chatRef = firestore.collection('chats').doc(chatId);
          final chatSnap = await chatRef.get();
          final lastSender = chatSnap.data()?['lastMessageSenderId'];

          if (lastSender == authController.currentUser.value!.id) {
            chatRef.update({'lastMessageStatus': 'sent'});
          }


            

          // mettre à jour local si présent
          final index = messages.indexWhere((m) => m.id == doc.id);
          if (index != -1) {
            messages[index] = messages[index].copyWith(
              status: 'sent',
              hasPendingWrites: false,
            );
          }
        }
      }
    });
  }

  // -------------------------
  // ENVOI MESSAGE (optimistic)
  // -------------------------
  void sendMessage() {
    final msgText = messageController.text.trim();
    if (msgText.isEmpty) return;

    final currentUserId = authController.currentUser.value!.id;
    final chatRef = firestore.collection('chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');
    final newMessageRef = messagesRef.doc();
    final messageId = newMessageRef.id;

    final localMessage = ChatMessage(
      id: messageId,
      senderId: currentUserId,
      receiverId: widget.receiverId,
      message: msgText,
      createdAt: DateTime.now(),
      status: 'pending',
      hasPendingWrites: true,
    );

    messages.insert(0, localMessage);
    _messageKeys[messageId] = GlobalKey();
    messageController.clear();
    _scrollToBottom();

    newMessageRef.set({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'message': msgText,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    }).then((_) async {
      await chatRef.set({
        'participants': [currentUserId, widget.receiverId],
        'lastMessage': msgText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,  // <-- ajouté
        'lastMessageStatus': 'pending', 
        'unread': FieldValue.arrayUnion([widget.receiverId])
      }, SetOptions(merge: true));
    }).catchError((e) {
      // gérer erreur en UI si besoin
    });
  }

  // -------------------------
  // READ ON VISIBLE (core)
  // -------------------------
  void _onScroll() {
    _updateFloatingDate();
    // limiter fréquence si besoin, mais ici on appelle la fonction de check
    _checkVisibleMessagesAndMarkRead();
  }
  void _updateFloatingDate() {
  try {
    for (var entry in _messageKeys.entries) {
      final key = entry.value;
      final ctx = key.currentContext;
      if (ctx == null) continue;

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;

      final pos = box.localToGlobal(Offset.zero).dy;
      if (pos > 50 && pos < 200) { 
        final msg = messages.firstWhereOrNull((m) => m.id == entry.key);
        if (msg != null) {
          final newDate = DateFormat('yyyy-MM-dd').format(msg.createdAt!);
          if (_floatingDate != newDate) {
            setState(() {
              _floatingDate = newDate;
            });
          }
        }
        break;
      }
    }
  } catch (_) {}
}


  void _checkVisibleMessagesAndMarkRead() {
    // Pour chaque message visible : si je suis destinataire et non lu -> update
    final currentUserId = authController.currentUser.value!.id;

    for (final msg in messages) {
      if (msg.id == null) continue;
      final key = _messageKeys[msg.id];
      if (key == null) continue;

      if (_isMessageVisible(key)) {
        // vérifier conditions : je suis destinataire ET pas déjà lu localement
        if (msg.receiverId == currentUserId && msg.status != 'read' && !_markedReadLocal.contains(msg.id)) {
          _markedReadLocal.add(msg.id!);
          _markMessageReadOnVisible(msg);
        }
      }
    }
  }

  bool _isMessageVisible(GlobalKey key) {
    try {
      final context = key.currentContext;
      if (context == null) return false;
      final renderObject = context.findRenderObject();
      if (renderObject == null || !(renderObject is RenderBox)) return false;
      final box = renderObject as RenderBox;

      // position du widget par rapport à l'écran
      final topLeft = box.localToGlobal(Offset.zero);
      final size = box.size;
      final bottom = topLeft.dy + size.height;
      final screenHeight = MediaQuery.of(context).size.height;

      // On considère visible si au moins 30% du widget est dans le viewport vertical
      final visibleTop = topLeft.dy.clamp(0.0, screenHeight);
      final visibleBottom = bottom.clamp(0.0, screenHeight);
      final visibleHeight = (visibleBottom - visibleTop).clamp(0.0, size.height);

      return visibleHeight >= size.height * 0.3;
    } catch (e) {
      return false;
    }
  }

  Future<void> _markMessageReadOnVisible(ChatMessage msg) async {
    final currentUserId = authController.currentUser.value!.id;
    if (msg.receiverId != currentUserId) return;
    if (msg.status == 'read') return;

    final docRef = firestore.collection('chats').doc(chatId).collection('messages').doc(msg.id);

    try {
      await docRef.update({
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });
      await firestore.collection('chats').doc(chatId).update({
        'lastMessageStatus': 'read',
      });


      // mise à jour locale si message encore dans liste
      final index = messages.indexWhere((m) => m.id == msg.id);
      if (index != -1) {
        messages[index] = messages[index].copyWith(status: 'read');
      }

      // Optionnel : mettre à jour le champ 'unread' du chat en retirant currentUser
      final chatRef = firestore.collection('chats').doc(chatId);
      await chatRef.update({
        'unread': FieldValue.arrayRemove([currentUserId])
      }).catchError((e) {
        // ignore si non présent
      });
    } catch (e) {
      // si erreur on retire du set pour retenter plus tard
      _markedReadLocal.remove(msg.id);
    }
  }

  // -------------------------
  // UTILITAIRES (FORMAT, COPY, EDIT, DELETE)
  // -------------------------
  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      }
    });
  }

  String formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) return "Aujourd’hui";
    if (difference == 1) return "Hier";
    if (difference < 7) {
      final jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      return jours[date.weekday - 1];
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).delete();
      Get.snackbar('Succès', 'Message supprimé.', backgroundColor: Colors.green, colorText: myColors.white);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de supprimer le message.', backgroundColor: Colors.red, colorText: myColors.white);
    }
  }

  Future<void> _editMessage(String messageId, String currentText) async {
    messageController.text = currentText;
    await Get.defaultDialog(
      title: "Modifier le message",
      content: TextField(
        controller: messageController,
        decoration: const InputDecoration(hintText: "Nouveau message", border: OutlineInputBorder()),
        maxLines: null,
        keyboardType: TextInputType.multiline,
      ),
      textConfirm: "Modifier",
      textCancel: "Annuler",
      confirmTextColor: myColors.white,
      buttonColor: myColors.accentColor,
      onConfirm: () async {
        final newText = messageController.text.trim();
        if (newText.isNotEmpty && newText != currentText) {
          try {
            await firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
              'message': newText,
              'editedAt': FieldValue.serverTimestamp(),
            });
            Get.back();
            Get.snackbar('Succès', 'Message modifié.', backgroundColor: Colors.green, colorText: myColors.white);
            messageController.clear();
          } catch (e) {
            Get.snackbar('Erreur', 'Impossible de modifier le message.', backgroundColor: Colors.red, colorText: myColors.white);
          }
        } else {
          Get.back();
        }
      },
      onCancel: () {
        messageController.clear();
        Get.back();
      },
    );
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('Copié', 'Message copié dans le presse-papiers.', backgroundColor: Colors.blue, colorText: myColors.white, duration: const Duration(seconds: 2));
  }

  Widget _statusIcon(ChatMessage msg) {
    if (msg.status == 'read') {
      return const Icon(Icons.done_all, size: 16, color: Colors.greenAccent);
    } else if (msg.status == 'delivered') {
      return const Icon(Icons.done_all, size: 16, color: Colors.white70);
    } else if (msg.status == 'sent') {
      return const Icon(Icons.done, size: 16, color: Colors.white70);
    } else {
      return const Icon(Icons.access_time, size: 14, color: Colors.white70);
    }
  }

  void _showContextMenu(BuildContext context, ChatMessage message) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: myColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Actions sur le message", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: myColors.color)),
            const Divider(),
            ListTile(
              leading: Icon(Icons.edit, color: myColors.accentColor),
              title: Text("Modifier", style: TextStyle(color: myColors.accentColor)),
              onTap: () {
                Get.back();
                _editMessage(message.id!, message.message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Supprimer", style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                Get.defaultDialog(
                  title: "Confirmer la suppression",
                  middleText: "Êtes-vous sûr de vouloir supprimer ce message ? Cette action est irréversible.",
                  textConfirm: "Supprimer",
                  textCancel: "Annuler",
                  confirmTextColor: myColors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    Get.back();
                    _deleteMessage(message.id!);
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text("Copier"),
              onTap: () {
                Get.back();
                _copyMessage(message.message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOptionsDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: myColors.color),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: myColors.accentColor,
                  backgroundImage: (widget.receiverPhotoUrl != null && widget.receiverPhotoUrl!.isNotEmpty) ? NetworkImage(widget.receiverPhotoUrl!) : null,
                  child: (widget.receiverPhotoUrl == null || widget.receiverPhotoUrl!.isEmpty) ? Text(widget.receiverName[0].toUpperCase(), style: TextStyle(color: myColors.white, fontWeight: FontWeight.bold, fontSize: 24)) : null,
                ),
                const SizedBox(height: 10),
                Text(widget.receiverName, style: TextStyle(color: myColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text("Options de conversation", style: TextStyle(color: myColors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.call, color: myColors.accentColor),
            title: Text("Appeler", style: TextStyle(color: Colors.black87)),
            onTap: () {
              Get.back();
              Get.snackbar("Bientôt disponible", "La fonction d'appel n'est pas encore implémentée.");
            },
          ),
          ListTile(
            leading: Icon(Icons.videocam, color: myColors.accentColor),
            title: Text("Appel vidéo", style: TextStyle(color: Colors.black87)),
            onTap: () {
              Get.back();
              Get.snackbar("Bientôt disponible", "La fonction d'appel vidéo n'est pas encore implémentée.");
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: myColors.accentColor),
            title: Text("Voir le profil", style: TextStyle(color: Colors.black87)),
            onTap: () {
              Get.back();
              Get.to(() => ProfilMessage(userId: widget.receiverId));
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text("Bloquer", style: TextStyle(color: Colors.red)),
            onTap: () {
              Get.back();
              Get.snackbar("Bientôt disponible", "La fonction de blocage n'est pas encore implémentée.");
            },
          ),
        ],
      ),
    );
  }

  // -------------------------
  // BUILD UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final currentUserId = authController.currentUser.value!.id;
    final Size screenSize = MediaQuery.of(context).size;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('profiles').doc(widget.receiverId).get(),
      builder: (context, snapshot) {
        String? photoUrl = widget.receiverPhotoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data()!;
          if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) {
            photoUrl = data['photoUrl'];
          }
        }

        return Scaffold(
          backgroundColor: myColors.background,
          appBar: widget.isTwoPane
              ? null
              : AppBar(
                  backgroundColor: myColors.color,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: myColors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: GestureDetector(
                    onTap: () {
                      Get.to(() => ProfilMessage(userId: widget.receiverId));
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: screenSize.width * 0.04,
                          backgroundColor: myColors.accentColor,
                          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? Text(widget.receiverName[0].toUpperCase(), style: TextStyle(color: myColors.white, fontWeight: FontWeight.bold, fontSize: screenSize.width * 0.04))
                              : null,
                        ),
                        SizedBox(width: screenSize.width * 0.02),
                        Expanded(
                          child: Text(widget.receiverName, overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(color: myColors.white, fontWeight: FontWeight.bold, fontSize: screenSize.width * 0.035)),
                        ),
                      ],
                    ),
                  ),
                ),
          // endDrawer: widget.isTwoPane ? null : _buildChatOptionsDrawer(context),
          body: Stack(
            children: [
                          if (_floatingDate != null)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formatDateHeader(DateTime.parse(_floatingDate!)),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  Expanded(
                    child: Obx(() {
                      if (messages.isEmpty) return const Center(child: Text("Aucun message"));
                      // grouper par date
                      final grouped = <String, List<ChatMessage>>{};
                      for (var m in messages) {
                        final dateKey = DateFormat('yyyy-MM-dd').format(m.createdAt ?? DateTime.now());
                        grouped.putIfAbsent(dateKey, () => []);
                        grouped[dateKey]!.add(m);
                      }
                      final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                      return ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, groupIndex) {
                          final dateKey = sortedKeys[groupIndex];
                          final msgs = grouped[dateKey]!;

                          final children = <Widget>[];

                          // HEADER DE DATE
                          children.add(
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  formatDateHeader(DateTime.parse(dateKey)),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );

                          for (var m in msgs.reversed) {
                            children.add(buildMessageWidget(m));
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: children,
                          );
                        },
                      );

                    }),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(left: 15, right: 10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: TextField(
                              controller: messageController,
                              decoration: const InputDecoration(hintText: 'Écrire un message...', border: InputBorder.none),
                              maxLines: 6,
                              minLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.blue)),
                          icon: const Icon(Icons.send, color: Colors.white, size: 25),
                          onPressed: sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // header date flottant si besoin (non implémenté ici pour rester simple)
            ],
          ),
        );
      },
    );
  }

  // Construction du widget d'un message (chaque container a sa GlobalKey pour visibilité)
  Widget buildMessageWidget(ChatMessage msg) {
    final currentUserId = authController.currentUser.value!.id;
    final isMe = msg.senderId == currentUserId;
    final createdAt = msg.createdAt ?? DateTime.now();
    final editedAt = msg.editedAt;
    // créer ou récupérer key pour ce message
    final GlobalKey key = _messageKeys.putIfAbsent(msg.id!, () => GlobalKey());

    return GestureDetector(
      onLongPress: isMe ? () => _showContextMenu(context, msg) : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          key: key,
          margin: isMe ? const EdgeInsets.only(left: 160, right: 10, top: 2, bottom: 3) : const EdgeInsets.only(left: 10, right: 160, top: 2, bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey[300],
            borderRadius: isMe
                ? const BorderRadius.only(bottomLeft: Radius.circular(7), bottomRight: Radius.circular(0), topLeft: Radius.circular(7), topRight: Radius.circular(7))
                : const BorderRadius.only(bottomLeft: Radius.circular(0), bottomRight: Radius.circular(7), topLeft: Radius.circular(7), topRight: Radius.circular(7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(msg.message, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (editedAt != null)
                    Text('Modifié • ', style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 10)),
                  Text(DateFormat('HH:mm').format(createdAt), style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 10)),
                  const SizedBox(width: 6),
                  if (isMe) _statusIcon(msg),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
