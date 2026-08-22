import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/model_service.dart';
import '../utils/constants.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/side_menu.dart';
import '../widgets/app_chrome.dart';
import '../theme/theme_controller.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final ModelService _modelService = ModelService();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final ScrollController _scrollController = ScrollController();
  String? _currentChatId;
  List<MessageModel> _currentMessages = [];
  bool _isProcessing = false;
  bool _isModelReady = false;
  bool _titleHasBeenSet = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _createNewChat();
  }

  Future<void> _initializeModel() async {
    try {
      await _modelService.initializeModel();
      if (mounted) setState(() => _isModelReady = true);
      print('✅ Model loaded!');
    } catch (e) {
      print('❌ Model error: $e');
      if (mounted) setState(() => _isModelReady = false);
    }
  }

  Future<void> _createNewChat() async {
    if (!mounted) return;

    _messageController.clear();
    setState(() {
      _currentChatId = null;
      _currentMessages = [];
      _isProcessing = false;
      _titleHasBeenSet = false;
    });

    try {
      final userId = _authService.currentUser!.uid;
      final chatId = await _firestoreService.createChat(userId, 'New Chat');
      await _firestoreService.ensureUserDocumentExists(
        userId,
        email: _authService.currentUser?.email,
      );
      if (!mounted) return;
      setState(() => _currentChatId = chatId);
    } catch (e) {
      print('❌ Create chat error: $e');
    }
  }

  bool get _hasUserMessages =>
      _currentMessages.any((message) => message.sender == 'user');

  String _titleFromText(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 30) return trimmed;
    return '${trimmed.substring(0, 30)}...';
  }

  Future<void> _maybeUpdateChatTitle(String title) async {
    if (_titleHasBeenSet || _currentChatId == null) return;
    _titleHasBeenSet = true;
    try {
      await _firestoreService.updateChatTitle(
        _authService.currentUser!.uid,
        _currentChatId!,
        title,
      );
    } catch (e) {
      print('❌ Failed to update chat title: $e');
      _titleHasBeenSet = false;
    }
  }

  Future<void> _persistMessage(MessageModel message) async {
    if (_currentChatId == null) return;
    try {
      await _firestoreService.addMessageToChat(
        _authService.currentUser!.uid,
        _currentChatId!,
        message,
      );
    } catch (e) {
      print('❌ Persist message error: $e');
    }
  }

  Future<void> _savePrediction(PredictionModel prediction) async {
    if (_currentChatId == null) return;
    try {
      await _firestoreService.savePrediction(
        userId: _authService.currentUser!.uid,
        chatId: _currentChatId!,
        diseaseName: prediction.diseaseName,
        confidence: prediction.confidence,
        recommendation: prediction.recommendation,
      );
    } catch (e) {
      print('❌ Save prediction error: $e');
    }
  }

  Future<void> _selectChat(String chatId) async {
    if (!mounted) return;

    _messageController.clear();
    setState(() {
      _currentChatId = chatId;
      _currentMessages = [];
      _isProcessing = false;
      _titleHasBeenSet = false;
    });

    try {
      final messages = await _firestoreService.getChatMessages(
        _authService.currentUser!.uid,
        chatId,
      );
      final chat = await _firestoreService.getChat(
        _authService.currentUser!.uid,
        chatId,
      );
      if (!mounted) return;

      final loaded = messages
          .where((message) => !message.id.startsWith('welcome_'))
          .toList();

      setState(() {
        _currentChatId = chatId;
        _currentMessages = loaded;
        _titleHasBeenSet = chat != null &&
            chat.title.isNotEmpty &&
            chat.title != 'New Chat';
      });

      if (_currentMessages.isNotEmpty) {
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Load chat error: $e');
    }
  }

  // ============================================
  // IMAGE UPLOAD - GALLERY
  // ============================================
  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        await _processImage(File(pickedFile.path));
      }
    } catch (e) {
      _showSnackbar('Error picking image: $e');
    }
  }

  // ============================================
  // IMAGE UPLOAD - CAMERA
  // ============================================
  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        await _processImage(File(pickedFile.path));
      }
    } catch (e) {
      _showSnackbar('Error capturing image: $e');
    }
  }

  // ============================================
  // PROCESS IMAGE
  // ============================================
  Future<void> _processImage(File imageFile) async {
    if (!_isModelReady) {
      _showSnackbar('Model is loading. Please wait.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final isFirstUserMessage = !_hasUserMessages;

      // Add user message with image
      final userMessage = MessageModel(
        id: 'user_img_${DateTime.now().millisecondsSinceEpoch}',
        content: '📸 Image uploaded',
        sender: 'user',
        timestamp: DateTime.now(),
        imagePath: imageFile.path,
      );
      setState(() => _currentMessages.add(userMessage));
      await _persistMessage(userMessage);

      if (isFirstUserMessage) {
        await _maybeUpdateChatTitle('📸 Image uploaded');
      }

      // Read image bytes
      final bytes = await imageFile.readAsBytes();

      // Predict
      final result = await _modelService.predictDisease(bytes);

      final diseaseName = result['diseaseName'] ?? 'Unknown';
      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
      final recommendation =
          result['recommendation'] ?? 'Consult a dermatologist.';
      final prediction = PredictionModel(
        diseaseName: diseaseName,
        confidence: confidence,
        recommendation: recommendation,
      );

      // Add AI response
      final aiMessage = MessageModel(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content:
            '🔍 $diseaseName\n\n'
            '📊 Confidence: ${(confidence * 100).toStringAsFixed(2)}%\n\n'
            '💊 Recommendation:\n$recommendation',
        sender: 'ai',
        timestamp: DateTime.now(),
        prediction: prediction,
      );
      setState(() => _currentMessages.add(aiMessage));
      await _persistMessage(aiMessage);
      await _savePrediction(prediction);

      _scrollToBottom();
    } catch (e) {
      print('❌ Image processing error: $e');
      _showSnackbar('Error: ${e.toString()}');
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  // ============================================
  // DISEASE SELECT
  // ============================================
  void _showDiseaseList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryBg,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Skin conditions',
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 4),
            Text(
              'Choose one to see a recommendation',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: DiseaseList.diseases.length,
                itemBuilder: (context, index) {
                  final disease = DiseaseList.diseases[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(context);
                          _handleDiseaseSelected(disease);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.spa_outlined,
                                  color: AppColors.primaryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  disease,
                                  style: AppTextStyles.subtitle1,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textLight,
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDiseaseSelected(String disease) async {
    final isFirstUserMessage = !_hasUserMessages;

    // User message
    final userMessage = MessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: '📋 Selected: $disease',
      sender: 'user',
      timestamp: DateTime.now(),
    );
    setState(() => _currentMessages.add(userMessage));
    await _persistMessage(userMessage);

    if (isFirstUserMessage) {
      await _maybeUpdateChatTitle('📋 $disease');
    }

    // Get recommendation
    final info = _modelService.getDiseaseInfo(disease);
    final recommendation =
        info?['recommendation'] ?? 'Consult a dermatologist.';
    final prediction = PredictionModel(
      diseaseName: disease,
      confidence: 1.0,
      recommendation: recommendation,
    );

    // AI message
    final aiMessage = MessageModel(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      content: '🔍 $disease\n\n💊 Recommendation:\n$recommendation',
      sender: 'ai',
      timestamp: DateTime.now(),
      prediction: prediction,
    );
    setState(() => _currentMessages.add(aiMessage));
    await _persistMessage(aiMessage);
    await _savePrediction(prediction);

    _scrollToBottom();
  }

  // ============================================
  // TEXT MESSAGE
  // ============================================
  void _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final bool isFirstUserMessage = !_hasUserMessages;

    // Create user message
    final userMessage = MessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: text,
      sender: 'user',
      timestamp: DateTime.now(),
    );

    setState(() => _currentMessages.add(userMessage));
    _messageController.clear();
    await _persistMessage(userMessage);

    if (isFirstUserMessage) {
      await _maybeUpdateChatTitle(_titleFromText(text));
    }

    // Simple AI response
    final aiMessage = MessageModel(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      content:
          'I received your message: "$text"\n\n'
          'Please upload an image or select a disease from the list for a proper diagnosis.',
      sender: 'ai',
      timestamp: DateTime.now(),
    );

    setState(() => _currentMessages.add(aiMessage));
    await _persistMessage(aiMessage);
    _scrollToBottom();
  }

  // ============================================
  // HELPERS
  // ============================================
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _composerIcon({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 22, color: AppColors.textLight),
    );
  }

  // ============================================
  // BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBg,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMini(),
            const SizedBox(width: 10),
            Text(
              'DermaAI',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        actions: const [ThemeToggleButton()],
      ),
      drawer: StreamBuilder<List<ChatModel>>(
        stream: _firestoreService.getUserChats(_authService.currentUser!.uid),
        builder: (context, snapshot) {
          final chats = snapshot.data ?? [];
          return SideMenu(
            chats: chats,
            currentChatId: _currentChatId ?? '',
            onNewChat: _createNewChat,
            onSelectChat: _selectChat,
            onDeleteChat: (chatId) async {
              await _firestoreService.deleteChat(
                _authService.currentUser!.uid,
                chatId,
              );
              if (_currentChatId == chatId) {
                _createNewChat();
              }
            },
            onLogout: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            onProfile: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('')));
            },
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentMessages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const BrandMark(size: 72, iconSize: 32),
                          const SizedBox(height: 20),
                          Text(
                            'How can I help today?',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headline2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Send a photo or ask about a skin condition.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    key: ValueKey(_currentChatId),
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    itemCount: _currentMessages.length,
                    itemBuilder: (context, index) {
                      final message = _currentMessages[index];
                      return ChatBubble(
                        message: message,
                        isCurrentUser: message.sender == 'user',
                      );
                    },
                  ),
          ),
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Analyzing…',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              decoration: BoxDecoration(
                color: AppColors.secondaryBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _messageController,
                    style: AppTextStyles.bodyText,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Message DermaAI',
                      hintStyle: TextStyle(color: AppColors.muted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(14, 10, 14, 6),
                    ),
                    onSubmitted: (_) => _sendTextMessage(),
                  ),
                  Row(
                    children: [
                      _composerIcon(
                        icon: Icons.photo_outlined,
                        onPressed: _isProcessing ? null : _pickImageFromGallery,
                      ),
                      _composerIcon(
                        icon: Icons.menu_outlined,
                        onPressed: _showDiseaseList,
                      ),
                      _composerIcon(
                        icon: Icons.photo_camera_outlined,
                        onPressed: _isProcessing ? null : _pickImageFromCamera,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _isProcessing ? null : _sendTextMessage,
                        icon: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
