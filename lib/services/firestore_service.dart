import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../utils/constants.dart';

// ============================================
// FIRESTORE SERVICE
// ============================================
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users (for admin)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('📂 Fetching users from Firestore...');
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      print('📄 Documents found: ${snapshot.docs.length}');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'email': data['email'] ?? 'Unknown',
          'createdAt': data['createdAt'],
          'isAdmin': data['isAdmin'] ?? false,
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting users: $e');
      return [];
    }
  }

  // Create new chat
  Future<String> createChat(String userId, String initialMessage) async {
    try {
      final docRef = await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(userId)
          .collection(FirestorePaths.chatsCollection)
          .add({
            'title': 'New Chat',
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
            'messages': [],
          });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Get all chats for user
  Stream<List<ChatModel>> getUserChats(String userId) {
    try {
      return _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(userId)
          .collection(FirestorePaths.chatsCollection)
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
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return MessageModel(
              id: doc.id,
              content: data['content'] ?? '',
              sender: data['sender'] ?? 'user',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              imagePath: data['imagePath'],
            );
          }).toList();
        });
  }

  Future<ChatModel?> getChat(String userId, String chatId) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(userId)
          .collection(FirestorePaths.chatsCollection)
          .doc(chatId)
          .get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      data['userId'] = userId;
      return ChatModel.fromMap(data);
    } catch (e) {
      throw Exception('Failed to fetch chat: $e');
    }
  }

  // Add message to chat
  Future<void> addMessageToChat(
    String userId,
    String chatId,
    MessageModel message,
  ) async {
    try {
      final chatRef = _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(userId)
          .collection(FirestorePaths.chatsCollection)
          .doc(chatId);

      await chatRef.update({
        'messages': FieldValue.arrayUnion([message.toMap()]),
        'updatedAt': DateTime.now(),
      });
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
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .update({'title': title});
    } catch (e) {
      print('❌ Update chat title error: $e');
    }
  }

  // Delete chat
  Future<void> deleteChat(String userId, String chatId) async {
    try {
      await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(userId)
          .collection(FirestorePaths.chatsCollection)
          .doc(chatId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  // Get total users count
  Future<int> getTotalUsersCount() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.usersCollection)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get users count: $e');
    }
  }

  // Get user's chat history (for admin panel)
  Future<List<ChatModel>> getUserChatHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.usersCollection)
          .doc(userId)
          .collection(FirestorePaths.chatsCollection)
          .get();

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
