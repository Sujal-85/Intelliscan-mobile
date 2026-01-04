import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../main_navigation.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleEmailSignUp() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        // Here you might want to save the display name as well
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialSignIn(
    Future<dynamic> Function() signInMethod,
  ) async {
    setState(() => _isLoading = true);
    try {
      final user = await signInMethod();
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Social login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Background Blobs
            Positioned(
              top: -50,
              left: -50,
              child: FadeIn(
                duration: const Duration(seconds: 2),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignSystem.primaryPurple.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: DesignSystem.textColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInDown(
                      duration: const Duration(seconds: 1),
                      child: Image.asset(DesignSystem.logoPath, height: 70),
                    ),
                    const SizedBox(height: 18),
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.textColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInDown(
                      delay: const Duration(milliseconds: 400),
                      child: Text(
                        'Join us and start scanning smarter',
                        style: TextStyle(
                          fontSize: 16,
                          color: DesignSystem.secondaryText(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: TextField(
                        controller: _nameController,
                        style: TextStyle(
                          color: DesignSystem.textColor(context),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Full Name',
                          hintStyle: TextStyle(
                            color: DesignSystem.secondaryText(context),
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: DesignSystem.secondaryText(context),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: DesignSystem.glassBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: DesignSystem.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 700),
                      child: TextField(
                        controller: _emailController,
                        style: TextStyle(
                          color: DesignSystem.textColor(context),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Email Address',
                          hintStyle: TextStyle(
                            color: DesignSystem.secondaryText(context),
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: DesignSystem.secondaryText(context),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: DesignSystem.glassBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: DesignSystem.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 800),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(
                          color: DesignSystem.textColor(context),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(
                            color: DesignSystem.secondaryText(context),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: DesignSystem.secondaryText(context),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: DesignSystem.glassBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: DesignSystem.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      delay: const Duration(milliseconds: 900),
                      child: CustomGradientButton(
                        text: 'Create Account',
                        isLoading: _isLoading,
                        onPressed: _handleEmailSignUp,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      delay: const Duration(milliseconds: 1000),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: DesignSystem.outlineColor(context),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR SIGN UP WITH',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: DesignSystem.secondaryText(context),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: DesignSystem.outlineColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      delay: const Duration(milliseconds: 1100),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialButton(
                            icon: FontAwesomeIcons.google,
                            color: const Color(0xFFDB4437),
                            onTap: () => _handleSocialSignIn(
                              _authService.signInWithGoogle,
                            ),
                          ),
                          const SizedBox(width: 20),
                          _SocialButton(
                            icon: FontAwesomeIcons.github,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF333333),
                            onTap: () => _handleSocialSignIn(
                              _authService.signInWithGitHub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      delay: const Duration(milliseconds: 1200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              color: DesignSystem.secondaryText(context),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: DesignSystem.primaryPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignSystem.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: DesignSystem.glassBorder),
        ),
        child: FaIcon(icon, color: color, size: 24),
      ),
    );
  }
}
