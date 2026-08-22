import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/theme_controller.dart';
import '../utils/constants.dart';
import '../widgets/app_chrome.dart';
import 'admin_history_screen.dart';

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
  bool _statsLoading = true;
  String? _statsError;
  List<Map<String, dynamic>> _users = [];
  bool _usersLoading = true;
  String? _usersError;
  StreamSubscription<QuerySnapshot>? _usersSub;
  StreamSubscription<QuerySnapshot>? _chatsSub;
  StreamSubscription<QuerySnapshot>? _predictionsSub;

  @override
  void initState() {
    super.initState();
    _ensureAuthAndStart();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _chatsSub?.cancel();
    _predictionsSub?.cancel();
    super.dispose();
  }

  Future<void> _ensureAuthAndStart() async {
    await _ensureFirebaseAuth();
    try {
      await _firestoreService.repairMissingUserDocs();
    } catch (e) {
      print('❌ Repair users error: $e');
    }
    await _loadStats();
    _listenForRealtimeUpdates();
  }

  Future<void> _ensureFirebaseAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'admin@gmail.com',
        password: 'admin123',
      );
    } catch (_) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: 'admin@gmail.com',
          password: 'admin123',
        );
      } catch (_) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (e) {
          print('❌ Admin auth failed: $e');
        }
      }
    }
  }

  void _listenForRealtimeUpdates() {
    final firestore = FirebaseFirestore.instance;
    _usersSub = firestore.collection('users').snapshots().listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _users = snapshot.docs.where((doc) => doc.exists).map((doc) {
          final data = doc.data();
          return {
            'uid': data['uid'] ?? doc.id,
            'email': data['email'] ?? 'Unknown',
            'password': data['password'],
            'createdAt': data['createdAt'],
            'isAdmin': data['isAdmin'] ?? false,
          };
        }).toList();
        _usersLoading = false;
        _usersError = null;
      });
      _loadStats();
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _statsError = _friendlyFirestoreError(e);
          _statsLoading = false;
          _usersError = _friendlyFirestoreError(e);
          _usersLoading = false;
        });
      }
    });
    _chatsSub = firestore.collection('chats').snapshots().listen((_) {
      _loadStats();
    }, onError: (e) => print('❌ Chats stream error: $e'));
    _predictionsSub =
        firestore.collection('predictions').snapshots().listen((_) {
      _loadStats();
    }, onError: (e) => print('❌ Predictions stream error: $e'));
  }

  String _friendlyFirestoreError(Object e) {
    final text = e.toString();
    if (text.contains('PERMISSION_DENIED') ||
        text.contains('not been used') ||
        text.contains('disabled')) {
      return 'Cloud Firestore is not enabled for project dermai-skin-care. Open Firebase Console → Firestore Database → Create database (test mode), wait 1–2 minutes, then pull to refresh.';
    }
    return 'Could not load stats: $e';
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _firestoreService.getAdminStats();
      if (!mounted) return;
      setState(() {
        _totalUsers = stats['users'] ?? 0;
        _totalChats = stats['chats'] ?? 0;
        _totalPredictions = stats['predictions'] ?? 0;
        _statsError = null;
        _statsLoading = false;
      });
    } catch (e) {
      print('❌ Error loading stats: $e');
      if (mounted) {
        setState(() {
          _statsError = _friendlyFirestoreError(e);
          _statsLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }
    if (date == null) return 'N/A';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  String _passwordLabel(dynamic password) {
    if (password == null) return 'Not saved';
    final text = password.toString().trim();
    return text.isEmpty ? 'Not saved' : text;
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.28), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: AppTextStyles.subtitle1)),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
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
    if (_statsLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Overview', style: AppTextStyles.headline2),
            const SizedBox(height: 4),
            Text(
              'Live snapshot of DermaAI activity',
              style: AppTextStyles.caption.copyWith(fontSize: 13.5),
            ),
            const SizedBox(height: AppSpacing.large),
            if (_statsError != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.normal),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppBorderRadius.normal),
                  border: Border.all(color: AppColors.errorRed.withOpacity(0.4)),
                ),
                child: Text(
                  _statsError!,
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.errorRed,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.large),
            ],
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
      ),
    );
  }

  // ============================================
  // USERS TAB (UC6)
  // ============================================
  Widget _buildUsersTab() {
    if (_usersLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
        ),
      );
    }

    if (_usersError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Text(
            _usersError!,
            style: AppTextStyles.bodyText,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Text('No users found', style: AppTextStyles.bodyText),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.normal),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.normal),
          child: _buildUserCard(user),
        );
      },
    );
  }

  // ============================================
  // USER CARD
  // ============================================
  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card.copyWith(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.isDark ? const Color(0xFF042F2E) : Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['email'] ?? 'Unknown',
                      style: AppTextStyles.subtitle1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined ${_formatDate(user['createdAt'])}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showUserDetailsDialog(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textLight,
                    side: BorderSide(color: AppColors.border, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Details',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showUserChatHistory(
                      user['uid'],
                      email: user['email'] ?? '',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.isDark
                        ? const Color(0xFF042F2E)
                        : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Chat history',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('User Details', style: AppTextStyles.headline2),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', user['email'] ?? 'N/A'),
              _buildDetailRow('Password', _passwordLabel(user['password'])),
              _buildDetailRow('UID', user['uid'] ?? 'N/A'),
              _buildDetailRow('Created At', _formatDate(user['createdAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
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
  void _showUserChatHistory(String uid, {String email = ''}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminChatHistoryScreen(uid: uid, email: email),
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
    context.watch<ThemeController>();
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBg,
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMini(),
            const SizedBox(width: 10),
            Text('Admin', style: AppTextStyles.headline2),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.secondaryBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  title: Text('Logout', style: AppTextStyles.headline2),
                  content: Text(
                    'Are you sure you want to logout?',
                    style: AppTextStyles.bodyText,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.accentTeal),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _authService.logout();
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                      child: Text(
                        'Logout',
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.logout, color: AppColors.errorRed),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: AppColors.secondaryBg,
              child: TabBar(
                labelColor: AppColors.accentTeal,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.accentTeal,
                indicatorWeight: 2.4,
                dividerColor: AppColors.border,
                tabs: const [
                  Tab(text: 'Statistics'),
                  Tab(text: 'Users'),
                ],
              ),
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
