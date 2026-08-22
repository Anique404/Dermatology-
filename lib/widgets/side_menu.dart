import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../theme/theme_controller.dart';
import '../utils/constants.dart';
import 'app_chrome.dart';

class SideMenu extends StatelessWidget {
  final List<ChatModel> chats;
  final VoidCallback onNewChat;
  final Function(String) onSelectChat;
  final Function(String) onDeleteChat;
  final VoidCallback onLogout;
  final String currentChatId;
  final VoidCallback onProfile;

  const SideMenu({
    Key? key,
    required this.chats,
    required this.onNewChat,
    required this.onSelectChat,
    required this.onDeleteChat,
    required this.onLogout,
    required this.currentChatId,
    required this.onProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: AppColors.secondaryBg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  BrandMini(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DermaAI', style: AppTextStyles.subtitle1),
                        Text('Skin care assistant', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const ThemeToggleButton(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onNewChat();
                  },
                  icon: Icon(Icons.add, size: 18),
                  label: Text('New chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textLight,
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: chats.isEmpty
                  ? Center(
                      child: Text('No chats yet', style: AppTextStyles.caption),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final isSelected = chat.id == currentChatId;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.muted,
                          ),
                          title: Text(
                            chat.title,
                            style: AppTextStyles.subtitle1.copyWith(
                              fontSize: 14,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormat('MMM d, HH:mm').format(chat.updatedAt),
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            onSelectChat(chat.id);
                          },
                          trailing: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: AppColors.muted,
                              size: 16,
                            ),
                            onPressed: () => onDeleteChat(chat.id),
                          ),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surface,
                    child: Text(
                      user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user?.email ?? 'No email',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: AppColors.errorRed),
              title: Text(
                'Log out',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}
