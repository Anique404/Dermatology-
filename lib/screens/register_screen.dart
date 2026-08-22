import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';
import '../utils/constants.dart';
import '../widgets/app_chrome.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterScreen({Key? key, required this.onSwitchToLogin})
      : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 🔥 2. SAVE USER TO FIRESTORE (YEH IMPORTANT HAI)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'uid': userCredential.user!.uid,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
        'isAdmin': false,
      });

      // 3. Success
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSwitchToLogin();
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

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return '❌ This email is already registered.';
      case 'invalid-email':
        return '❌ Invalid email address.';
      case 'weak-password':
        return '❌ Password is too weak.';
      default:
        return '❌ An error occurred. Please try again.';
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
                      const Center(child: BrandMark(size: 84, iconSize: 36)),
                      const SizedBox(height: 16),
                      Text(
                        'Create account',
                        style: AppTextStyles.headline1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join DermaAI for personal skin guidance',
                        style: AppTextStyles.caption.copyWith(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                        decoration: AppDecorations.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _emailController,
                              style: AppTextStyles.bodyText,
                              keyboardType: TextInputType.emailAddress,
                              decoration: AppDecorations.input(
                                hint: 'Email',
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.primaryColor,
                                ),
                              ),
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
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPasswordController,
                              style: AppTextStyles.bodyText,
                              obscureText: _obscureConfirmPassword,
                              decoration: AppDecorations.input(
                                hint: 'Confirm password',
                                prefixIcon: Icon(
                                  Icons.lock_person_outlined,
                                  color: AppColors.primaryColor,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.muted,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                ),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              ErrorBanner(message: _errorMessage!),
                            ],
                            const SizedBox(height: 18),
                            GradientButton(
                              label: 'Sign up',
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _register,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onSwitchToLogin,
                            child: Text(
                              'Log in',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w700,
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
