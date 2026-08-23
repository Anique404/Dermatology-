import 'package:flutter/material.dart';

// ============================================
// APP COLORS — high contrast, light + dark
// ============================================
class AppColors {
  static bool isDark = false;

  static Color primaryColor = const Color(0xFF0F766E);
  static Color primaryDeep = const Color(0xFF115E59);
  static Color darkBg = const Color(0xFFE2E8F0);
  static Color secondaryBg = const Color(0xFFFFFFFF);
  static Color surface = const Color(0xFFD7E0EA);
  static Color surfaceHigh = const Color(0xFFC5D0DC);
  static Color textLight = const Color(0xFF0B1220);
  static Color textDark = const Color(0xFF0B1220);
  static Color accentTeal = const Color(0xFF0D9488);
  static Color mint = const Color(0xFF14B8A6);
  static Color errorRed = const Color(0xFFB42318);
  static Color successGreen = const Color(0xFF047857);
  static Color warningAmber = const Color(0xFFB45309);
  static Color muted = const Color(0xFF334155);
  static Color border = const Color(0xFF94A3B8);
  static Color userBubble = const Color(0xFF0F766E);
  static Color aiBubble = const Color(0xFFFFFFFF);
  static Color peach = const Color(0xFF475569);

  static void apply({required bool dark}) {
    isDark = dark;
    if (dark) {
      primaryColor = const Color(0xFF2DD4BF);
      primaryDeep = const Color(0xFF14B8A6);
      darkBg = const Color(0xFF0B1220);
      secondaryBg = const Color(0xFF151C2C);
      surface = const Color(0xFF1C2538);
      surfaceHigh = const Color(0xFF243044);
      textLight = const Color(0xFFF1F5F9);
      textDark = const Color(0xFFF1F5F9);
      accentTeal = const Color(0xFF5EEAD4);
      mint = const Color(0xFF2DD4BF);
      errorRed = const Color(0xFFF87171);
      successGreen = const Color(0xFF34D399);
      warningAmber = const Color(0xFFFBBF24);
      muted = const Color(0xFF94A3B8);
      border = const Color(0xFF334155);
      userBubble = const Color(0xFF0F766E);
      aiBubble = const Color(0xFF1C2538);
      peach = const Color(0xFF94A3B8);
    } else {
      primaryColor = const Color(0xFF0F766E);
      primaryDeep = const Color(0xFF115E59);
      darkBg = const Color(0xFFE2E8F0);
      secondaryBg = const Color(0xFFFFFFFF);
      surface = const Color(0xFFD7E0EA);
      surfaceHigh = const Color(0xFFC5D0DC);
      textLight = const Color(0xFF0B1220);
      textDark = const Color(0xFF0B1220);
      accentTeal = const Color(0xFF0D9488);
      mint = const Color(0xFF14B8A6);
      errorRed = const Color(0xFFB42318);
      successGreen = const Color(0xFF047857);
      warningAmber = const Color(0xFFB45309);
      muted = const Color(0xFF334155);
      border = const Color(0xFF94A3B8);
      userBubble = const Color(0xFF0F766E);
      aiBubble = const Color(0xFFFFFFFF);
      peach = const Color(0xFF475569);
    }
  }
}

class AppGradients {
  static LinearGradient get brand => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.accentTeal, AppColors.primaryColor],
      );

  static LinearGradient get background => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.darkBg, AppColors.darkBg],
      );

  static LinearGradient get userBubble => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.accentTeal, AppColors.primaryDeep],
      );

  static LinearGradient get cardGlow => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryColor.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      );
}

// ============================================
// APP TEXT STYLES
// ============================================
class AppTextStyles {
  static TextStyle get headline1 => TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textLight,
        letterSpacing: -0.7,
        height: 1.15,
      );

  static TextStyle get headline2 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textLight,
        letterSpacing: -0.3,
      );

  static TextStyle get subtitle1 => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
        letterSpacing: -0.1,
      );

  static TextStyle get bodyText => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textLight,
        height: 1.5,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
        height: 1.4,
      );
}

// ============================================
// SHARED DECORATIONS
// ============================================
class AppDecorations {
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration get surface => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      );

  static InputDecoration input({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.caption.copyWith(fontSize: 15),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.errorRed),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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
  static const String modelsCollection = 'models';
  static const String currentModelDoc = 'current';
}

// ============================================
// ADMIN CREDENTIALS
// ============================================
class AdminCredentials {
  static const String adminEmail = 'admin@dermai.com';
  static const String adminPassword = 'Admin@123';
  static const String legacyAdminEmail = 'admin@gmail.com';
  static const String legacyAdminPassword = 'admin123';

  static bool isAdminEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final normalized = email.trim().toLowerCase();
    return normalized == adminEmail.toLowerCase() ||
        normalized == legacyAdminEmail.toLowerCase();
  }

  static bool matches(String email, String password) {
    final normalized = email.trim().toLowerCase();
    if (normalized == adminEmail.toLowerCase() &&
        password == adminPassword) {
      return true;
    }
    if (normalized == legacyAdminEmail.toLowerCase() &&
        password == legacyAdminPassword) {
      return true;
    }
    return false;
  }
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
  static const int maxUploadBytes = 50 * 1024 * 1024;
}

class CloudinaryConfig {
  static const String cloudName = 'deu35cqde';
  static const String uploadPreset = 'epictour_uploads';
  static const String rawUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';
  static const String autoUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';
  static const String imageUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  static const int unsignedMaxBytes = 10 * 1024 * 1024;
  static const int uploadChunkBytes = 9 * 1024 * 1024;
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
  static const double xlarge = 32.0;
}
