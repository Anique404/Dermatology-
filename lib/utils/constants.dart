import 'package:flutter/material.dart';

// ============================================
// APP COLORS
// ============================================
class AppColors {
  static const Color primaryColor = Color(0xFF0A7E8C);
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color secondaryBg = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFFE0E0E0);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color accentTeal = Color(0xFF00B4CC);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
}

// ============================================
// APP TEXT STYLES
// ============================================
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textLight,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFF9CA3AF),
  );
}

// ============================================
// FIRESTORE PATHS
// ============================================
class FirestorePaths {
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String predictionsCollection = 'predictions';
}

// ============================================
// ADMIN CREDENTIALS
// ============================================
class AdminCredentials {
  static const String adminEmail = 'admin@dermai.com';
  static const String adminPassword = 'Admin@123';
}

// ============================================
// DISEASE LIST
// ============================================
class DiseaseList {
  static const List<String> diseases = [
    'Acne',
    'Contact Dermatitis',
    'Eczema',
    'Fungal Infection',
    'Herpes',
    'Insect Bite Dermatitis',
    'Lichen Planus',
    'Miliaria',
    'Palmoplantar Keratoderma',
    'Papular Urticaria',
    'Psoriasis',
    'Purpura',
    'Rosacea',
    'Seborrheic Dermatitis',
    'Urticaria',
  ];
}

// ============================================
// MODEL CONFIG
// ============================================
class ModelConfig {
  static const String modelPath = 'assets/skin_care_model_densenet121.tflite';
  static const String classNamesPath = 'assets/class_names_densenet121.json';
  static const String recommendationsPath = 'assets/recommendations.json';
  static const int imageSize = 224;
  static const double confidenceThreshold = 0.5;
}

// ============================================
// PADDING & SPACING
// ============================================
class AppSpacing {
  static const double tiny = 4.0;
  static const double small = 8.0;
  static const double normal = 16.0;
  static const double medium = 20.0;
  static const double large = 24.0;
  static const double xlarge = 32.0;
}

// ============================================
// BORDER RADIUS
// ============================================
class AppBorderRadius {
  static const double small = 8.0;
  static const double normal = 12.0;
  static const double medium = 16.0;
  static const double large = 24.0;
}
