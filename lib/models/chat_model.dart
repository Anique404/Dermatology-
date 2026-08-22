import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================
// USER MODEL
// ============================================
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt,
      'isAdmin': isAdmin,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAdmin: map['isAdmin'] ?? false,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    bool? isAdmin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

// ============================================
// CHAT MODEL
// ============================================
class ChatModel {
  final String id;
  final String userId;
  final String title;
  final List<MessageModel> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'messages': messages.map((m) => m.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Chat',
      messages:
          (map['messages'] as List<dynamic>?)
              ?.map((m) => MessageModel.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ChatModel copyWith({
    String? id,
    String? userId,
    String? title,
    List<MessageModel>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============================================
// MESSAGE MODEL
// ============================================
class MessageModel {
  final String id;
  final String content;
  final String sender; // 'user' or 'ai'
  final DateTime timestamp;
  final String? imagePath;
  final PredictionModel? prediction;

  MessageModel({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.imagePath,
    this.prediction,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'sender': sender,
      'timestamp': timestamp,
      'imagePath': imagePath,
      'prediction': prediction?.toMap(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      sender: map['sender'] ?? 'user',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imagePath: map['imagePath'],
      prediction: map['prediction'] != null
          ? PredictionModel.fromMap(map['prediction'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ============================================
// PREDICTION MODEL
// ============================================
class PredictionModel {
  final String diseaseName;
  final double confidence;
  final String recommendation;

  PredictionModel({
    required this.diseaseName,
    required this.confidence,
    required this.recommendation,
  });

  Map<String, dynamic> toMap() {
    return {
      'diseaseName': diseaseName,
      'confidence': confidence,
      'recommendation': recommendation,
    };
  }

  factory PredictionModel.fromMap(Map<String, dynamic> map) {
    return PredictionModel(
      diseaseName: map['diseaseName'] ?? 'Unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      recommendation: map['recommendation'] ?? 'No recommendation available',
    );
  }
}
