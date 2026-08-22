import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/admin_screen.dart';
import 'services/auth_service.dart';
import 'utils/constants.dart';
import 'widgets/app_chrome.dart';
import 'theme/theme_controller.dart';

// ============================================
// MAIN
// ============================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  final themeController = ThemeController();
  await themeController.load();
  runApp(
    ChangeNotifierProvider.value(
      value: themeController,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return MaterialApp(
      title: 'DermaAI - Skin Care Assistant',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: theme.mode,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const AuthScreen(),
        '/admin': (context) => const AdminScreen(),
        '/chat': (context) => const ChatScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController(
    text: AdminCredentials.adminEmail,
  );
  final _passwordController = TextEditingController(
    text: AdminCredentials.adminPassword,
  );
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _handleAdminLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email == AdminCredentials.adminEmail &&
          password == AdminCredentials.adminPassword) {
        await _authService.login(email, password);
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/admin',
            (route) => false,
          );
        }
        return;
      }

      throw Exception('Invalid admin credentials');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Admin Login'),
        actions: const [ThemeToggleButton()],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandMark(size: 72, iconSize: 34),
                const SizedBox(height: AppSpacing.large),
                TextField(
                  controller: _emailController,
                  style: AppTextStyles.bodyText,
                  decoration: AppDecorations.input(
                    hint: 'Admin Email',
                    prefixIcon: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.accentTeal,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.normal),
                TextField(
                  controller: _passwordController,
                  style: AppTextStyles.bodyText,
                  obscureText: _obscurePassword,
                  decoration: AppDecorations.input(
                    hint: 'Password',
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.accentTeal,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.muted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.normal),
                  ErrorBanner(message: _errorMessage!),
                ],
                const SizedBox(height: AppSpacing.large),
                GradientButton(
                  label: 'Login as Admin',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleAdminLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// AUTH WRAPPER
// ============================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;

        if (snapshot.connectionState == ConnectionState.waiting &&
            user == null) {
          return Scaffold(
            backgroundColor: AppColors.darkBg,
            body: AppBackground(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BrandMark(size: 72, iconSize: 34),
                    const SizedBox(height: 28),
                    CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (user == null) {
          return const AuthScreen();
        }

        if (AdminCredentials.isAdminEmail(user.email)) {
          return const AdminScreen();
        }

        return const ChatScreen();
      },
    );
  }
}

// ============================================
// AUTH SCREEN
// ============================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return _showLogin
        ? LoginScreen(
            onSwitchToRegister: () {
              setState(() {
                _showLogin = false;
              });
            },
          )
        : RegisterScreen(
            onSwitchToLogin: () {
              setState(() {
                _showLogin = true;
              });
            },
          );
  }
}
