import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../utils/constants.dart';

// ============================================
// SIDE MENU WIDGET
// ============================================
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
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: AppColors.secondaryBg,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.spa, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: AppSpacing.normal),
                  const Text('DermaAI', style: AppTextStyles.headline2),
                  const Text(
                    'Skin Care Assistant',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.accentTeal, height: 1, thickness: 1),

            // New Chat Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.normal),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onNewChat,
                  icon: const Icon(Icons.add),
                  label: const Text('New Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.small,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Chat History
            Expanded(
              child: chats.isEmpty
                  ? Center(
                      child: Text(
                        'No chats yet',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textLight.withOpacity(0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.normal,
                      ),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final isSelected = chat.id == currentChatId;
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.small,
                          ),
                          child: ListTile(
                            title: Text(
                              chat.title,
                              style: AppTextStyles.subtitle1.copyWith(
                                color: isSelected
                                    ? AppColors.accentTeal
                                    : AppColors.textLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              DateFormat(
                                'MMM dd, HH:mm',
                              ).format(chat.updatedAt),
                              style: AppTextStyles.caption,
                            ),
                            selected: isSelected,
                            selectedTileColor: AppColors.primaryColor
                                .withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.small,
                              ),
                              side: isSelected
                                  ? const BorderSide(
                                      color: AppColors.accentTeal,
                                    )
                                  : BorderSide.none,
                            ),
                            onTap: () => onSelectChat(chat.id),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.errorRed,
                              ),
                              onPressed: () => onDeleteChat(chat.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(color: AppColors.accentTeal, height: 1, thickness: 1),

            // Footer Menu - Profile with Email
            Padding(
              padding: const EdgeInsets.all(AppSpacing.normal),
              child: Column(
                children: [
                  // User Email Only (No Profile text, No onTap)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accentTeal,
                          child: Text(
                            user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            user?.email ?? 'No email',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Logout
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppColors.errorRed,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
