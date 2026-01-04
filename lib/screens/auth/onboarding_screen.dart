import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/custom_button.dart';
import 'login_screen.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Convert Handwriting',
      subtitle:
          'Transform your physical notes into digital intelligence instantly with our AI engine.',
      lottie: 'assets/lottie/Sign digital document.json',
    ),
    OnboardingData(
      title: 'Unified Multimodal',
      subtitle:
          'Handle math, sketches, PDFs, and speech all in one powerful workspace.',
      lottie: 'assets/lottie/Omnichannel CRM.json',
    ),
    OnboardingData(
      title: 'Secure & Private',
      subtitle:
          'Your data stays yours. Offline-ready and enterprise-grade security for your peace of mind.',
      lottie: 'assets/lottie/security.json',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(data: _pages[index]);
            },
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? DesignSystem.primaryPurple
                            : DesignSystem.primaryPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  child: CustomGradientButton(
                    text: _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInScale(
            child: Lottie.asset(data.lottie, height: 300, fit: BoxFit.contain),
          ),
          const SizedBox(height: 48),
          FadeInDown(
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            child: Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FadeInScale extends StatelessWidget {
  final Widget child;
  const FadeInScale({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 800),
      child: ZoomIn(duration: const Duration(milliseconds: 800), child: child),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String lottie;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.lottie,
  });
}
