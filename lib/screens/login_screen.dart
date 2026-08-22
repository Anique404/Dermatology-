import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../screens/admin_screen.dart';
import '../screens/chat_screen.dart'; // <-- ADD THIS

// ============================================
// LOGIN SCREEN
// ============================================
class LoginScreen extends StatefulWidget {
  final VoidCallback onSwitchToRegister;

  const LoginScreen({Key? key, required this.onSwitchToRegister})
    : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================
  // ERROR MESSAGE HANDLER
  // ============================================
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return '❌ No account found with this email. Please sign up.';
      case 'wrong-password':
        return '❌ Incorrect password. Please try again.';
      case 'invalid-email':
        return '❌ Invalid email address. Please check your email.';
      case 'user-disabled':
        return '❌ This account has been disabled. Contact support.';
      case 'too-many-requests':
        return '❌ Too many attempts. Please try again later.';
      case 'invalid-credential':
        return '❌ Invalid email or password. Please try again.';
      default:
        return '❌ An error occurred. Please try again.';
    }
  }

  // ============================================
  // LOGIN LOGIC - FIXED
  // ============================================
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter email and password';
          _isLoading = false;
        });
        return;
      }

      // ✅ Admin Check
      if (email == 'admin@gmail.com' && password == 'admin123') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminScreen()),
        );
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Normal Login - Firebase Authentication
      final user = await _authService.login(email, password);

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getAuthErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                // App Logo & Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.spa,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      const Text(
                        'DermaAI',
                        style: AppTextStyles.headline1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.tiny),
                      const Text(
                        'Skin Care Assistant',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                // Email Field
                TextField(
                  controller: _emailController,
                  style: AppTextStyles.bodyText,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: AppTextStyles.caption,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.accentTeal,
                    ),
                    filled: true,
                    fillColor: AppColors.secondaryBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.normal,
                      ),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.normal),
                // Password Field
                TextField(
                  controller: _passwordController,
                  style: AppTextStyles.bodyText,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: AppTextStyles.caption,
                    prefixIcon: const Icon(
                      Icons.lock_outlined,
                      color: AppColors.accentTeal,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.accentTeal,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.secondaryBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.normal,
                      ),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.normal),
                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.normal),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.small,
                      ),
                      border: Border.all(
                        color: AppColors.errorRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.errorRed,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.errorRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.normal),
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.normal,
                      ),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.normal),
                // Switch to Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyText,
                    ),
                    GestureDetector(
                      onTap: widget.onSwitchToRegister,
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppColors.accentTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
