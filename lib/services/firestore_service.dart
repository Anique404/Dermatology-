import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';
import '../utils/constants.dart';

// ============================================
// FIRESTORE SERVICE
// ============================================
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _userFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return {
      'uid': data['uid'] ?? doc.id,
      'email': data['email'] ?? 'Unknown',
      'password': data['password'],
      'createdAt': data['createdAt'],
      'isAdmin': data['isAdmin'] ?? false,
    };
  }

  Future<void> ensureUserDocumentExists(
    String userId, {
    String? email,
    String? password,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final snapshot = await userRef.get();
    final data = <String, dynamic>{
      'uid': userId,
    };
    if (email != null && email.isNotEmpty) {
      data['email'] = email;
    }
    if (password != null && password.isNotEmpty) {
      data['password'] = password;
    }
    if (!snapshot.exists) {
      data['email'] = email ?? 'Unknown';
      data['createdAt'] = FieldValue.serverTimestamp();
      data['isAdmin'] = AdminCredentials.isAdminEmail(email);
    }
    await userRef.set(data, SetOptions(merge: true));
  }

  Future<void> repairMissingUserDocs() async {
    try {
      final chatSnapshots = await _firestore.collectionGroup('chats').get();
      final userIds = <String>{};
      for (final chat in chatSnapshots.docs) {
        final parent = chat.reference.parent.parent;
        if (parent != null) userIds.add(parent.id);
        final data = chat.data();
        final fromField = data['userId']?.toString();
        if (fromField != null && fromField.isNotEmpty) {
          userIds.add(fromField);
        }
      }

      try {
        final topLevel = await _firestore.collection('chats').get();
        for (final chat in topLevel.docs) {
          final fromField = chat.data()['userId']?.toString();
          if (fromField != null && fromField.isNotEmpty) {
            userIds.add(fromField);
          }
        }
      } catch (_) {}

      for (final userId in userIds) {
        await ensureUserDocumentExists(userId);
      }
    } catch (e) {
      print('❌ Repair missing users error: $e');
    }
  }

  // Get all users (for admin)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      await repairMissingUserDocs();
      print('📂 Fetching users from Firestore...');
      final snapshot = await _firestore.collection('users').get();
      print('📄 Documents found: ${snapshot.docs.length}');
      return snapshot.docs.map(_userFromDoc).toList();
    } catch (e) {
      print('❌ Error getting users: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.exists && doc.data().isNotEmpty)
          .map(_userFromDoc)
          .toList();
    });
  }

  CollectionReference<Map<String, dynamic>> _userChatCollection(String userId) {
    return _firestore
        .collection(FirestorePaths.usersCollection)
        .doc(userId)
        .collection(FirestorePaths.chatsCollection);
  }

  DocumentReference<Map<String, dynamic>> _userChatDoc(
    String userId,
    String chatId,
  ) {
    return _userChatCollection(userId).doc(chatId);
  }

  DocumentReference<Map<String, dynamic>> _topLevelChatDoc(String chatId) {
    return _firestore.collection(FirestorePaths.chatsCollection).doc(chatId);
  }

  Map<String, dynamic> _chatWriteData(String userId, {String title = 'New Chat'}) {
    return {
      'userId': userId,
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'messages': [],
    };
  }

  Map<String, dynamic> _messageWriteMap(MessageModel message) {
    final map = Map<String, dynamic>.from(message.toMap());
    if (map['timestamp'] is DateTime) {
      map['timestamp'] = Timestamp.fromDate(map['timestamp'] as DateTime);
    }
    return map;
  }

  // Create new chat (user subcollection + top-level chats)
  Future<String> createChat(String userId, String initialMessage) async {
    try {
      await ensureUserDocumentExists(userId);
      final data = _chatWriteData(userId, title: 'New Chat');
      final userChatRef = _userChatCollection(userId).doc();
      final chatId = userChatRef.id;

      final batch = _firestore.batch();
      batch.set(userChatRef, data);
      batch.set(_topLevelChatDoc(chatId), data);
      await batch.commit();

      return chatId;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Get all chats for user
  Stream<List<ChatModel>> getUserChats(String userId) {
    try {
      return _userChatCollection(userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              data['userId'] = userId;
              return ChatModel.fromMap(data);
            }).toList();
          });
    } catch (e) {
      throw Exception('Failed to fetch chats: $e');
    }
  }

  Stream<List<MessageModel>> getChatMessagesStream(
    String userId,
    String chatId,
  ) {
    return _userChatDoc(userId, chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return MessageModel.fromMap(data);
          }).toList();
        });
  }

  Future<ChatModel?> getChat(String userId, String chatId) async {
    try {
      final doc = await _userChatDoc(userId, chatId).get();
      if (!doc.exists || doc.data() == null) {
        final topLevel = await _topLevelChatDoc(chatId).get();
        if (!topLevel.exists || topLevel.data() == null) return null;
        final data = topLevel.data()!;
        data['id'] = topLevel.id;
        data['userId'] = data['userId'] ?? userId;
        return ChatModel.fromMap(data);
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      data['userId'] = userId;
      return ChatModel.fromMap(data);
    } catch (e) {
      throw Exception('Failed to fetch chat: $e');
    }
  }

  Future<List<MessageModel>> getChatMessages(String userId, String chatId) async {
    try {
      final chat = await getChat(userId, chatId);
      if (chat != null && chat.messages.isNotEmpty) {
        return chat.messages;
      }

      final snapshot = await _userChatDoc(userId, chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return MessageModel.fromMap(data);
        }).toList();
      }

      return chat?.messages ?? [];
    } catch (e) {
      print('❌ Failed to fetch chat messages: $e');
      return [];
    }
  }

  // Add message to chat
  Future<void> addMessageToChat(
    String userId,
    String chatId,
    MessageModel message,
  ) async {
    try {
      final messageMap = _messageWriteMap(message);
      final chatRef = _userChatDoc(userId, chatId);
      final topLevelRef = _topLevelChatDoc(chatId);

      await chatRef.set({
        'userId': userId,
        'messages': FieldValue.arrayUnion([messageMap]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await topLevelRef.set({
        'userId': userId,
        'messages': FieldValue.arrayUnion([messageMap]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await chatRef.collection('messages').doc(message.id).set(messageMap);
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  Future<void> updateChatTitle(
    String userId,
    String chatId,
    String title,
  ) async {
    try {
      final payload = {
        'title': title,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _userChatDoc(userId, chatId).set(payload, SetOptions(merge: true));
      await _topLevelChatDoc(chatId).set({
        ...payload,
        'userId': userId,
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Update chat title error: $e');
    }
  }

  Future<void> savePrediction({
    required String userId,
    required String chatId,
    required String diseaseName,
    required double confidence,
    required String recommendation,
  }) async {
    try {
      await _firestore.collection(FirestorePaths.predictionsCollection).add({
        'userId': userId,
        'chatId': chatId,
        'diseaseName': diseaseName,
        'confidence': confidence,
        'recommendation': recommendation,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Save prediction error: $e');
    }
  }

  // Delete chat
  Future<void> deleteChat(String userId, String chatId) async {
    try {
      final chatRef = _userChatDoc(userId, chatId);
      final messages = await chatRef.collection('messages').get();
      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(chatRef);
      batch.delete(_topLevelChatDoc(chatId));
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  // Get total users count
  Future<int> getTotalUsersCount() async {
    await repairMissingUserDocs();
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .where((doc) => doc.exists && doc.data().isNotEmpty)
        .length;
  }

  Future<int> getTotalChatsCount() async {
    try {
      final chatIds = <String>{};

      final users = await _firestore.collection('users').get();
      for (final userDoc in users.docs) {
        final chats = await userDoc.reference.collection('chats').get();
        for (final chat in chats.docs) {
          chatIds.add(chat.id);
        }
      }

      try {
        final topLevel = await _firestore.collection('chats').get();
        for (final chat in topLevel.docs) {
          chatIds.add(chat.id);
        }
      } catch (e) {
        print('❌ Top-level chats count error: $e');
      }

      return chatIds.length;
    } catch (e) {
      print('❌ Failed to get chats count: $e');
      return 0;
    }
  }

  bool _messageHasPrediction(dynamic message) {
    if (message is! Map) return false;
    final prediction = message['prediction'];
    if (prediction != null) return true;
    final content = (message['content'] ?? '').toString();
    final sender = (message['sender'] ?? '').toString();
    return sender == 'ai' && content.contains('🔍');
  }

  Future<int> getTotalPredictionsCount() async {
    try {
      try {
        final predictions = await _firestore
            .collection(FirestorePaths.predictionsCollection)
            .get();
        if (predictions.docs.isNotEmpty) {
          return predictions.docs.length;
        }
      } catch (e) {
        print('❌ Predictions collection count error: $e');
      }

      int count = 0;
      final countedMessageIds = <String>{};

      final users = await _firestore.collection('users').get();
      for (final userDoc in users.docs) {
        final chats = await userDoc.reference.collection('chats').get();
        for (final chatDoc in chats.docs) {
          final messages = chatDoc.data()['messages'];
          if (messages is List) {
            for (final msg in messages) {
              if (_messageHasPrediction(msg)) {
                final id = msg is Map ? (msg['id'] ?? '').toString() : '';
                final key = id.isNotEmpty ? id : '${chatDoc.id}_$count';
                if (countedMessageIds.add(key)) count++;
              }
            }
          }

          try {
            final msgDocs =
                await chatDoc.reference.collection('messages').get();
            for (final msgDoc in msgDocs.docs) {
              if (_messageHasPrediction(msgDoc.data())) {
                if (countedMessageIds.add(msgDoc.id)) count++;
              }
            }
          } catch (_) {}
        }
      }

      return count;
    } catch (e) {
      print('❌ Failed to get predictions count: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getAdminStats() async {
    final users = await getTotalUsersCount();
    final chats = await getTotalChatsCount();
    final predictions = await getTotalPredictionsCount();
    return {
      'users': users,
      'chats': chats,
      'predictions': predictions,
    };
  }

  Stream<Map<String, int>> watchAdminStats() async* {
    yield await getAdminStats();

    await for (final _ in _firestore.collection('users').snapshots()) {
      yield await getAdminStats();
    }
  }

  Stream<int> watchUsersCount() {
    return _firestore.collection('users').snapshots().map((s) => s.docs.length);
  }

  Stream<int> watchChatsCount() async* {
    yield await getTotalChatsCount();
    await for (final _ in _firestore.collection('chats').snapshots()) {
      yield await getTotalChatsCount();
    }
  }

  Stream<int> watchPredictionsCount() {
    return _firestore
        .collection(FirestorePaths.predictionsCollection)
        .snapshots()
        .map((s) => s.docs.length);
  }

  DocumentReference<Map<String, dynamic>> get _currentModelRef {
    return _firestore
        .collection(FirestorePaths.modelsCollection)
        .doc(FirestorePaths.currentModelDoc);
  }

  Future<Map<String, dynamic>?> getCurrentModel() async {
    try {
      final snapshot = await _currentModelRef.get();
      if (!snapshot.exists) return null;
      return snapshot.data();
    } catch (e) {
      print('❌ Error getting current model: $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> watchCurrentModel() {
    return _currentModelRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return snapshot.data();
    });
  }

  bool isTfliteFileName(String fileName) {
    return fileName.trim().toLowerCase().endsWith('.tflite');
  }

  Future<Map<String, dynamic>> uploadCurrentModel({
    required File file,
    required String fileName,
    required String updatedBy,
    void Function(double progress)? onProgress,
  }) async {
    final cleanedName = fileName.trim();
    if (!isTfliteFileName(cleanedName)) {
      throw Exception('Only .tflite files are allowed');
    }
    if (!await file.exists()) {
      throw Exception('Selected file could not be read');
    }
    final size = await file.length();
    if (size <= 0) {
      throw Exception('The selected file is empty');
    }

    onProgress?.call(0.1);
    final url = await _uploadToCloudinary(
      file: file,
      fileName: cleanedName,
      onProgress: onProgress,
    );
    onProgress?.call(1);

    await _currentModelRef.set({
      'version': cleanedName,
      'url': url,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    });

    final saved = await _currentModelRef.get();
    return saved.data() ??
        {
          'version': cleanedName,
          'url': url,
          'updatedBy': updatedBy,
        };
  }

  Future<String> _uploadToCloudinary({
    required File file,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    Future<http.StreamedResponse> send(String endpoint) async {
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ),
      );
      return request.send();
    }

    onProgress?.call(0.35);
    var response = await send(CloudinaryConfig.rawUploadUrl);
    var body = await response.stream.bytesToString();

    if (response.statusCode >= 400) {
      onProgress?.call(0.55);
      response = await send(CloudinaryConfig.autoUploadUrl);
      body = await response.stream.bytesToString();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_cloudinaryError(body));
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map || decoded['secure_url'] == null) {
      throw Exception('Cloudinary did not return a file URL');
    }
    return decoded['secure_url'].toString();
  }

  String _cloudinaryError(String body) {
    try {
      final decoded = jsonDecode(body);
      final error = decoded is Map ? decoded['error'] : null;
      if (error is Map && error['message'] != null) {
        return error['message'].toString();
      }
    } catch (_) {}
    return 'Cloudinary upload failed';
  }

  // Get user's chat history (for admin panel)
  Future<List<ChatModel>> getUserChatHistory(String userId) async {
    try {
      final snapshot = await _userChatCollection(userId).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['userId'] = userId;
        return ChatModel.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch chat history: $e');
    }
  }
}
