import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/admin_screen.dart';
import 'services/auth_service.dart';
import 'utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';

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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DermaAI - Skin Care Assistant',
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: AppColors.darkBg,
        fontFamily: GoogleFonts.inter().fontFamily,
        useMaterial3: true,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppColors.secondaryBg,
          foregroundColor: AppColors.textLight,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const AuthWrapper(),
      routes: {'/admin-login': (context) => const AdminLoginScreen()},
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminScreen()),
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
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.secondaryBg,
                hintText: 'Admin Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.normal),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.normal),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.secondaryBg,
                hintText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.normal),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.normal),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.errorRed),
              ),
            ],
            const SizedBox(height: AppSpacing.normal),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleAdminLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login as Admin'),
            ),
          ],
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
    return StreamBuilder<dynamic>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.darkBg,
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is logged in
          final user = snapshot.data;

          // Check if admin
          return FutureBuilder<bool>(
            future: AuthService().isUserAdmin(user.uid),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.hasData && adminSnapshot.data == true) {
                return const AdminScreen();
              }
              return const ChatScreen();
            },
          );
        }

        // User is not logged in
        return const AuthScreen();
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
