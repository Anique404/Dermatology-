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
    try {
      final userId = _authService.currentUser!.uid;
      final chatId = await _firestoreService.createChat(userId, 'New Chat');
      setState(() {
        _currentChatId = chatId;
        _currentMessages = [];
      });
      _addWelcomeMessage();
    } catch (e) {
      print('❌ Create chat error: $e');
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _currentMessages.add(
        MessageModel(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          content:
              '👋 Hello! I\'m DermaAI.\n\n'
              '📸 Upload an image to analyze your skin condition.\n'
              '📋 Select a disease from the list.\n'
              '💬 Describe your symptoms.',
          sender: 'ai',
          timestamp: DateTime.now(),
        ),
      );
    });
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
      // Add user message with image
      final userMessage = MessageModel(
        id: 'user_img_${DateTime.now().millisecondsSinceEpoch}',
        content: '📸 Image uploaded',
        sender: 'user',
        timestamp: DateTime.now(),
        imagePath: imageFile.path,
      );
      setState(() => _currentMessages.add(userMessage));

      // Read image bytes
      final bytes = await imageFile.readAsBytes();

      // Predict
      final result = await _modelService.predictDisease(bytes);

      final diseaseName = result['diseaseName'] ?? 'Unknown';
      final confidence = result['confidence'] ?? 0.0;
      final recommendation =
          result['recommendation'] ?? 'Consult a dermatologist.';

      // Add AI response
      final aiMessage = MessageModel(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content:
            '🔍 $diseaseName\n\n'
            '📊 Confidence: ${(confidence * 100).toStringAsFixed(2)}%\n\n'
            '💊 Recommendation:\n$recommendation',
        sender: 'ai',
        timestamp: DateTime.now(),
      );
      setState(() => _currentMessages.add(aiMessage));

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
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
            const Text(
              'Common Skin Diseases',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: DiseaseList.diseases.length,
                itemBuilder: (context, index) {
                  final disease = DiseaseList.diseases[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.1),
                      child: const Icon(
                        Icons.medical_services,
                        color: Colors.teal,
                      ),
                    ),
                    title: Text(disease),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _handleDiseaseSelected(disease);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDiseaseSelected(String disease) {
    // User message
    final userMessage = MessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: '📋 Selected: $disease',
      sender: 'user',
      timestamp: DateTime.now(),
    );
    setState(() => _currentMessages.add(userMessage));

    // Get recommendation
    final info = _modelService.getDiseaseInfo(disease);
    final recommendation =
        info?['recommendation'] ?? 'Consult a dermatologist.';

    // AI message
    final aiMessage = MessageModel(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      content: '🔍 $disease\n\n💊 Recommendation:\n$recommendation',
      sender: 'ai',
      timestamp: DateTime.now(),
    );
    setState(() => _currentMessages.add(aiMessage));

    _scrollToBottom();
  }

  // ============================================
  // TEXT MESSAGE
  // ============================================
  void _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Check if this is the first message (chat is empty)
    final bool isFirstMessage = _currentMessages.isEmpty;

    // Create user message
    final userMessage = MessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: text,
      sender: 'user',
      timestamp: DateTime.now(),
    );

    setState(() => _currentMessages.add(userMessage));
    _messageController.clear();

    // If this is the first message, update chat title
    if (isFirstMessage) {
      try {
        // Create title from first message (max 30 chars)
        String title = text;
        if (title.length > 30) {
          title = title.substring(0, 30) + '...';
        }

        await _firestoreService.updateChatTitle(
          _authService.currentUser!.uid,
          _currentChatId!,
          title,
        );
      } catch (e) {
        print('❌ Failed to update chat title: $e');
      }
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================
  // BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.spa, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'DermaAI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        // SIRF RIGHT SIDE MARGIN 80
        actions: const [SizedBox(width: 80)], // <-- SIRF RIGHT SIDE
      ),
      drawer: StreamBuilder<List<ChatModel>>(
        stream: _firestoreService.getUserChats(_authService.currentUser!.uid),
        builder: (context, snapshot) {
          final chats = snapshot.data ?? [];
          return SideMenu(
            chats: chats,
            currentChatId: _currentChatId ?? '',
            onNewChat: _createNewChat,
            onSelectChat: (chatId) {
              setState(() => _currentChatId = chatId);
            },
            onDeleteChat: (chatId) async {
              await _firestoreService.deleteChat(
                _authService.currentUser!.uid,
                chatId,
              );
              if (_currentChatId == chatId) {
                _createNewChat();
              }
            },
            onLogout: () => _authService.logout(),
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
          // Messages
          Expanded(
            child: _currentMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.teal.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Start chatting with DermaAI...',
                          style: TextStyle(color: Colors.teal, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
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

          // Processing indicator
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Analyzing...'),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(top: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Column(
              children: [
                // Buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.image, size: 18),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showDiseaseList,
                      icon: const Icon(Icons.list, size: 18),
                      label: const Text('Diseases'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Text input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: const Color(0xFF2D2D2D),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendTextMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _isProcessing ? null : _sendTextMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
