import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
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

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late final TabController _tabController;
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
  StreamSubscription<Map<String, dynamic>?>? _modelSub;
  Map<String, dynamic>? _currentModel;
  bool _modelLoading = true;
  String? _modelError;
  bool _uploadingModel = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) return;
      setState(() {});
    });
    _ensureAuthAndStart();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usersSub?.cancel();
    _chatsSub?.cancel();
    _predictionsSub?.cancel();
    _modelSub?.cancel();
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
    _modelSub = _firestoreService.watchCurrentModel().listen((data) {
      if (!mounted) return;
      setState(() {
        _currentModel = data;
        _modelLoading = false;
        _modelError = null;
      });
    }, onError: (e) {
      if (!mounted) return;
      setState(() {
        _modelError = _friendlyModelError(e);
        _modelLoading = false;
      });
    });
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

  String _friendlyModelError(Object e) {
    final text = e.toString().replaceAll('Exception: ', '');
    if (text.contains('PERMISSION_DENIED') ||
        text.contains('unauthorized') ||
        text.contains('403')) {
      return 'Upload or Firestore permission denied. Check Cloudinary unsigned preset and Firestore rules.';
    }
    if (text.contains('object-not-found')) {
      return 'The uploaded model file was not found in Storage.';
    }
    return text;
  }

  String _bundledModelName() {
    final path = ModelConfig.modelPath;
    final slash = path.lastIndexOf('/');
    return slash >= 0 ? path.substring(slash + 1) : path;
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
            const SizedBox(height: AppSpacing.large),
            _buildModelCard(),
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
  // UC7: ADMIN UPDATE MODEL
  // ============================================
  Future<void> _uploadNewModel() async {
    if (_uploadingModel) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        dialogTitle: 'Select a .tflite model file',
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      final fileName = (picked.name).trim();
      final path = picked.path;
      final looksLikeTflite =
          _firestoreService.isTfliteFileName(fileName) ||
          (path != null && _firestoreService.isTfliteFileName(path));
      if (!looksLikeTflite) {
        _showModelMessage(
          'Only .tflite model files are allowed. Please pick a file ending in .tflite.',
          isError: true,
        );
        return;
      }
      if (path == null || path.isEmpty) {
        _showModelMessage(
          'Could not access the selected file.',
          isError: true,
        );
        return;
      }

      final file = File(path);
      final resolvedName = _firestoreService.isTfliteFileName(fileName)
          ? fileName
          : path.split(RegExp(r'[/\\]')).last;
      if (!await file.exists() || await file.length() <= 0) {
        _showModelMessage(
          'The selected file is empty or unreadable.',
          isError: true,
        );
        return;
      }

      final adminEmail = FirebaseAuth.instance.currentUser?.email?.trim();
      if (adminEmail == null || adminEmail.isEmpty) {
        _showModelMessage(
          'Admin email is missing. Please log in again.',
          isError: true,
        );
        return;
      }

      setState(() {
        _uploadingModel = true;
        _uploadProgress = 0;
        _modelError = null;
      });

      await _firestoreService.uploadCurrentModel(
        file: file,
        fileName: resolvedName,
        updatedBy: adminEmail,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _uploadProgress = progress);
        },
      );

      if (!mounted) return;
      _showModelMessage('Model updated successfully: $resolvedName');
    } catch (e) {
      if (!mounted) return;
      setState(() => _modelError = _friendlyModelError(e));
      _showModelMessage(_friendlyModelError(e), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _uploadingModel = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  void _showModelMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
      ),
    );
  }

  Widget _buildModelTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _modelLoading = true);
        try {
          final data = await _firestoreService.getCurrentModel();
          if (!mounted) return;
          setState(() {
            _currentModel = data;
            _modelLoading = false;
            _modelError = null;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _modelError = _friendlyModelError(e);
            _modelLoading = false;
          });
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.large),
        children: [
          Text('Current model', style: AppTextStyles.headline2),
          const SizedBox(height: 4),
          Text(
            'Upload a .tflite file to replace the model used for predictions.',
            style: AppTextStyles.caption.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: AppSpacing.large),
          _buildModelCard(),
        ],
      ),
    );
  }

  Widget _buildModelCard() {
    final version = (_currentModel?['version']?.toString().isNotEmpty ?? false)
        ? _currentModel!['version'].toString()
        : _bundledModelName();
    final updatedBy = _currentModel?['updatedBy']?.toString();
    final updatedAt = _formatDate(_currentModel?['updatedAt']);
    final hasRemote = _currentModel?['url']?.toString().isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.memory_rounded,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active model', style: AppTextStyles.subtitle1),
                    Text(
                      hasRemote ? 'Cloudinary' : 'Bundled with app',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          if (_modelLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              ),
            )
          else ...[
            _buildDetailRow('Version / file', version),
            _buildDetailRow(
              'Last updated',
              hasRemote ? updatedAt : 'Not updated yet',
            ),
            _buildDetailRow(
              'Updated by',
              (updatedBy != null && updatedBy.isNotEmpty)
                  ? updatedBy
                  : 'N/A',
            ),
          ],
          if (_modelError != null) ...[
            Text(
              _modelError!,
              style: AppTextStyles.caption.copyWith(color: AppColors.errorRed),
            ),
            const SizedBox(height: AppSpacing.normal),
          ],
          if (_uploadingModel) ...[
            Text(
              'Uploading ${( _uploadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _uploadProgress <= 0 ? null : _uploadProgress,
              color: AppColors.primaryColor,
              backgroundColor: AppColors.surface,
            ),
            const SizedBox(height: AppSpacing.normal),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _uploadingModel ? null : _uploadNewModel,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor:
                    AppColors.isDark ? const Color(0xFF042F2E) : Colors.white,
                disabledBackgroundColor: AppColors.surfaceHigh,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                _uploadingModel
                    ? Icons.cloud_upload_outlined
                    : Icons.upload_file_rounded,
                size: 20,
              ),
              label: Text(
                _uploadingModel ? 'Uploading…' : 'Upload New Model',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
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

  Widget _buildSegmentedTabs() {
    final onSelected =
        AppColors.isDark ? const Color(0xFF042F2E) : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.secondaryBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark ? 0.28 : 0.06,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildTabItem(
              index: 0,
              icon: Icons.insights_rounded,
              label: 'Stats',
              onSelected: onSelected,
            ),
            _buildTabItem(
              index: 1,
              icon: Icons.group_rounded,
              label: 'Users',
              onSelected: onSelected,
            ),
            _buildTabItem(
              index: 2,
              icon: Icons.memory_rounded,
              label: 'Model',
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
    required Color onSelected,
  }) {
    final selected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? onSelected : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? onSelected : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
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
      body: Column(
        children: [
          _buildSegmentedTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatisticsTab(),
                _buildUsersTab(),
                _buildModelTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
