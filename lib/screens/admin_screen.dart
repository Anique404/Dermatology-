import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../screens/login_screen.dart';

// ============================================
// ADMIN SCREEN (UC6)
// ============================================
class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  int _totalUsers = 0;
  int _totalChats = 0;
  int _totalPredictions = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final users = await _firestoreService.getAllUsers();
      setState(() {
        _totalUsers = users.length;
      });
    } catch (e) {
      print('❌ Error loading stats: $e');
    }
  }

  // ============================================
  // STAT CARD
  // ============================================
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.subtitle1),
              Icon(icon, color: color, size: 28),
            ],
          ),
          const SizedBox(height: AppSpacing.normal),
          Text(value, style: AppTextStyles.headline1.copyWith(color: color)),
        ],
      ),
    );
  }

  // ============================================
  // STATISTICS TAB (Only 3 Cards)
  // ============================================
  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1: Total Users
          _buildStatCard(
            title: 'Total Registered Users',
            value: '$_totalUsers',
            icon: Icons.people,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: AppSpacing.large),

          // Card 2: Active Chats
          _buildStatCard(
            title: 'Active Chats',
            value: '$_totalChats',
            icon: Icons.chat,
            color: AppColors.accentTeal,
          ),
          const SizedBox(height: AppSpacing.large),

          // Card 3: Predictions
          _buildStatCard(
            title: 'Predictions',
            value: '$_totalPredictions',
            icon: Icons.analytics,
            color: AppColors.successGreen,
          ),
        ],
      ),
    );
  }

  // ============================================
  // USERS TAB (UC6)
  // ============================================
  Widget _buildUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _firestoreService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: AppTextStyles.bodyText,
            ),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Text('No users found', style: AppTextStyles.bodyText),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.normal),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.normal),
              child: _buildUserCard(user),
            );
          },
        );
      },
    );
  }

  // ============================================
  // USER CARD
  // ============================================
  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.normal),
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: BorderRadius.circular(AppBorderRadius.normal),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📧 ${user['email'] ?? 'Unknown'}',
                      style: AppTextStyles.subtitle1,
                    ),
                    Text(
                      'UID: ${user['uid']?.substring(0, 12)}...',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.normal),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showUserDetailsDialog(user);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.small,
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: AppColors.accentTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showUserChatHistory(user['uid']);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.small,
                      ),
                    ),
                    child: const Text(
                      'Chat History',
                      style: TextStyle(
                        color: AppColors.accentTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // USER DETAILS DIALOG
  // ============================================
  void _showUserDetailsDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBg,
        title: const Text('User Details', style: AppTextStyles.headline2),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', user['email'] ?? 'N/A'),
              _buildDetailRow('UID', user['uid'] ?? 'N/A'),
              _buildDetailRow(
                'Created At',
                user['createdAt']?.toString() ?? 'N/A',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.accentTeal),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // USER CHAT HISTORY (UC6)
  // ============================================
  void _showUserChatHistory(String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('User Chat History', style: AppTextStyles.headline2),
                const SizedBox(height: 16),
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
                        return const Center(child: CircularProgressIndicator());
                      }
                      final chats = snapshot.data!.docs;
                      if (chats.isEmpty) {
                        return Center(
                          child: Text(
                            'No chats found',
                            style: AppTextStyles.bodyText,
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final data =
                              chats[index].data() as Map<String, dynamic>;
                          return Card(
                            color: AppColors.secondaryBg,
                            child: ListTile(
                              title: Text(
                                data['title'] ?? 'New Chat',
                                style: AppTextStyles.bodyText,
                              ),
                              subtitle: Text(
                                data['createdAt'] != null
                                    ? (data['createdAt'] as Timestamp)
                                          .toDate()
                                          .toString()
                                          .substring(0, 16)
                                    : 'Unknown date',
                                style: AppTextStyles.caption,
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward,
                                color: AppColors.accentTeal,
                              ),
                              onTap: () {
                                _showChatMessages(uid, chats[index].id);
                              },
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
        },
      ),
    );
  }

  // ============================================
  // CHAT MESSAGES (UC6)
  // ============================================
  void _showChatMessages(String uid, String chatId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Chat Messages', style: AppTextStyles.headline2),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('chats')
                        .doc(chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final messages = snapshot.data!.docs;
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages',
                            style: AppTextStyles.bodyText,
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final data =
                              messages[index].data() as Map<String, dynamic>;
                          final isUser = data['sender'] == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? AppColors.primaryColor
                                    : AppColors.secondaryBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['content'] ?? '',
                                    style: AppTextStyles.bodyText,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['timestamp'] != null
                                        ? (data['timestamp'] as Timestamp)
                                              .toDate()
                                              .toString()
                                              .substring(0, 16)
                                        : '',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
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
        },
      ),
    );
  }

  // ============================================
  // DETAIL ROW
  // ============================================
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.normal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.accentTeal),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyText,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBg,
        elevation: 0,
        title: const Text('Admin Panel', style: AppTextStyles.headline2),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.secondaryBg,
                  title: const Text('Logout', style: AppTextStyles.headline2),
                  content: const Text(
                    'Are you sure you want to logout?',
                    style: AppTextStyles.bodyText,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.accentTeal),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _authService.logout();
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LoginScreen(onSwitchToRegister: () {}),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout, color: AppColors.errorRed),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: AppColors.accentTeal,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primaryColor,
              tabs: const [
                Tab(text: 'Statistics'),
                Tab(text: 'Users'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [_buildStatisticsTab(), _buildUsersTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
