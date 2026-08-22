import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/theme_controller.dart';
import '../utils/constants.dart';
import '../widgets/app_chrome.dart';

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

      if (AdminCredentials.matches(email, password)) {
        await _signInAdmin(email, password);
      } else {
        await _authService.login(email, password);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        unawaited(
          _authService.ensureUserDocument(user, password: password),
        );
      }

      if (!mounted) return;

      if (user == null) {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
          _isLoading = false;
        });
        return;
      }

      final goToAdmin = AdminCredentials.isAdminEmail(user.email) ||
          AdminCredentials.isAdminEmail(email) ||
          AdminCredentials.matches(email, password);

      Navigator.of(context).pushNamedAndRemoveUntil(
        goToAdmin ? '/admin' : '/chat',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AdminCredentials.isAdminEmail(user.email) ? '/admin' : '/chat',
          (route) => false,
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = _getAuthErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (e) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AdminCredentials.isAdminEmail(user.email) ? '/admin' : '/chat',
          (route) => false,
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInAdmin(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      final canCreate = e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password';
      if (!canCreate) rethrow;

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (createError) {
        if (createError.code == 'email-already-in-use') {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: const ThemeToggleButton(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                      const Center(child: BrandMark(size: 92, iconSize: 40)),
                      const SizedBox(height: 18),
                      Text(
                        'DermaAI',
                        style: AppTextStyles.headline1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Clinical skin analysis, made simple',
                        style: AppTextStyles.caption.copyWith(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                        decoration: AppDecorations.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Welcome back',
                              style: AppTextStyles.headline2,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to continue your consultation',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _emailController,
                              style: AppTextStyles.bodyText,
                              decoration: AppDecorations.input(
                                hint: 'Email',
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              style: AppTextStyles.bodyText,
                              obscureText: _obscurePassword,
                              decoration: AppDecorations.input(
                                hint: 'Password',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.primaryColor,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.muted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              ErrorBanner(message: _errorMessage!),
                            ],
                            const SizedBox(height: 18),
                            GradientButton(
                              label: 'Continue',
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _handleLogin,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onSwitchToRegister,
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
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
        ),
      ),
    );
  }
}
