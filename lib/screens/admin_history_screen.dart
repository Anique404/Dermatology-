import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../services/firestore_service.dart';
import '../theme/theme_controller.dart';
import '../utils/constants.dart';
import '../widgets/app_chrome.dart';

class AdminChatHistoryScreen extends StatelessWidget {
  final String uid;
  final String email;

  const AdminChatHistoryScreen({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBg,
        title: Row(
          children: [
            const BrandMini(),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Chat history',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [ThemeToggleButton()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email, style: AppTextStyles.subtitle1),
                const SizedBox(height: 4),
                Text(
                  'Consultations for this account',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('chats')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.primaryColor),
                  );
                }
                final chats = snapshot.data!.docs;
                if (chats.isEmpty) {
                  return Center(
                    child: Text('No chats found', style: AppTextStyles.bodyText),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = chats[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'New Chat';
                    DateTime? created;
                    if (data['createdAt'] is Timestamp) {
                      created = (data['createdAt'] as Timestamp).toDate();
                    }
                    return Container(
                      decoration: AppDecorations.card.copyWith(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminChatMessagesScreen(
                                  uid: uid,
                                  chatId: chats[index].id,
                                  title: title.toString(),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title.toString(),
                                        style: AppTextStyles.subtitle1,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        created == null
                                            ? 'Unknown date'
                                            : DateFormat('MMM d, yyyy · HH:mm')
                                                .format(created),
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminChatMessagesScreen extends StatelessWidget {
  final String uid;
  final String chatId;
  final String title;

  const AdminChatMessagesScreen({
    super.key,
    required this.uid,
    required this.chatId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final service = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBg,
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: const [ThemeToggleButton()],
      ),
      body: FutureBuilder<List<MessageModel>>(
        future: service.getChatMessages(uid, chatId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }
          final messages = snapshot.data ?? [];
          if (messages.isEmpty) {
            return Center(
              child: Text('No messages', style: AppTextStyles.bodyText),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isUser = message.sender == 'user';
              return Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.userBubble : AppColors.secondaryBg,
                    borderRadius: BorderRadius.circular(16),
                    border: isUser
                        ? null
                        : Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: AppTextStyles.bodyText.copyWith(
                          color: isUser ? Colors.white : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d · HH:mm').format(message.timestamp),
                        style: AppTextStyles.caption.copyWith(
                          color: isUser ? Colors.white70 : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
