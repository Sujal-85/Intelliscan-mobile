import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/design_system.dart';
import '../../services/auth_service.dart';
import '../../widgets/quick_action_popup.dart';
import '../../widgets/app_drawer.dart';
import '../features/social/feedback_screen.dart';
import '../features/social/referral_screen.dart';
import '../social/community_screen.dart';
import '../features/ocr_screen.dart';
import '../features/math_solver_screen.dart';
import '../features/sketch_svg_screen.dart';
import '../features/pdf_tools_screen.dart';
import '../features/ai_guide_screen.dart';
import '../features/speech_translation_screen.dart';
import '../features/security_screen.dart';
import '../features/smart_invoice_screen.dart';
import '../main_navigation.dart';

import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import '../../services/subscription_service.dart';
import '../subscription/subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();
  List<dynamic> _recentTasks =
      []; // Kept for compatibility if needed, but primarily using _allHistory now
  List<dynamic> _allHistory = [];
  bool _isLoadingHistory = false;

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _quickActionKey = GlobalKey();
  final GlobalKey _recentKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _creditsKey = GlobalKey();
  final GlobalKey _categoriesKey = GlobalKey();
  final GlobalKey _featuredKey = GlobalKey();

  int _selectedCategoryIndex = 0;

  int _availableCredits = 0;
  String _currentPlan = 'starter';
  bool _isLoadingSubscription = true;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _loadRecentHistory();
    _checkAndShowTutorial();
    _checkSubscriptionStatus();
  }

  int _getMaxCredits(String plan) {
    switch (plan.toLowerCase()) {
      case 'pro':
        return 3000;
      case 'premium':
        return 5000;
      default:
        return 100; // Starter/Free
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final status = await SubscriptionService().getSubscriptionStatus();
      if (mounted) {
        setState(() {
          _availableCredits = status['credits'] ?? 0;
          _currentPlan = status['plan'] ?? 'starter';
          _isExpired = status['isExpired'] ?? false;
          _isLoadingSubscription = false;
        });
      }

      final bool seenStarterPopup =
          prefs.getBool('seen_starter_popup') ?? false;

      if (!seenStarterPopup) {
        if (status['plan'] == 'starter') {
          if (mounted) {
            _showStarterPlanPopup(context);
            await prefs.setBool('seen_starter_popup', true);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSubscription = false);
    }
  }

  void _showStarterPlanPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          "Welcome to Starter Plan!",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You have unlocked a 14-day free trial with 100 free credits!",
              style: GoogleFonts.outfit(),
            ),
            SizedBox(height: 10),
            Text(
              "• 100 Credits added",
              style: GoogleFonts.outfit(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "• Access to basic features",
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
            SizedBox(height: 20),
            Text(
              "Upgrade anytime to Pro or Premium for more.",
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SubscriptionScreen()),
              );
            },
            child: Text(
              "View Plans",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: Text("Awesome!", style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool seenTutorial = prefs.getBool('seen_home_tutorial') ?? false;

    if (!seenTutorial) {
      // Delay to ensure widgets are built and rendered
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _showTutorial();
        }
      });
    }
  }

  void _showTutorial() {
    _initTargets();
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: DesignSystem.primaryPurple,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('seen_home_tutorial', true);
      },
      onClickTarget: (target) {},
      onSkip: () {
        _markTutorialSeen();
        return true;
      },
      onClickOverlay: (target) {},
    )..show(context: context);
  }

  Future<void> _markTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_home_tutorial', true);
  }

  void _initTargets() {
    targets.clear();

    // 1. Menu
    targets.add(
      TargetFocus(
        identify: "Menu",
        keyTarget: _menuKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Main Menu",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Access your profile, settings, and more from here.",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // 2. Credits
    targets.add(
      TargetFocus(
        identify: "Credits",
        keyTarget: _creditsKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Usage Tracking",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Keep track of your available credits here. Upgrade if you need more!",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // 3. Featured Tools
    targets.add(
      TargetFocus(
        identify: "FeaturedTools",
        keyTarget: _featuredKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Featured Tools",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Explore specialized tools like Translator and Redaction.",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // 4. Categories
    targets.add(
      TargetFocus(
        identify: "Categories",
        keyTarget: _categoriesKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Categories",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Tap a category to filter your recent scans and activities.",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // 5. Quick Actions (Existing)
    targets.add(
      TargetFocus(
        identify: "QuickActions",
        keyTarget: _quickActionKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.left,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quick Access",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Tap here to quickly access all smart features like Scan, Math Solver, and more.",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // 6. AI Guide (Existing)
    targets.add(
      TargetFocus(
        identify: "AIGuide",
        keyTarget: _fabKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.left,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Assistant",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Need help? Chat with our AI Guide for instant assistance.",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadRecentHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _apiService.getHistory();
      if (mounted) {
        setState(() {
          _allHistory = history;
          _recentTasks = history.take(5).toList(); // Initial view
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: DesignSystem.backgroundColor(context),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Quick Actions Button (Above AI Guide)
          FadeInRight(
            delay: const Duration(milliseconds: 1200),
            child: Container(
              key: _quickActionKey,
              margin: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton(
                heroTag: 'quick_actions_btn',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const QuickActionPopup(),
                  );
                },
                backgroundColor: DesignSystem.surfaceColor(context),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(0.1),
                        Colors.purpleAccent.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    color: DesignSystem.primaryPurple,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          // AI Guide Button
          FadeInRight(
            delay: const Duration(seconds: 1),
            child: Container(
              key: _fabKey,
              decoration: BoxDecoration(
                gradient: DesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: DesignSystem.primaryPurple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                heroTag: 'ai_guide_btn',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AiGuideScreen(),
                    ),
                  );
                },
                label: const Text(
                  'AI Guide',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(context, user),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  _loadRecentHistory(),
                  _checkSubscriptionStatus(),
                ]);
              },
              color: DesignSystem.primaryPurple, // Updated
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10, 20.0, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      _buildPremiumBanner(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Quick Actions'),
                      const SizedBox(height: 12),
                      _buildQuickActionGrid(context),
                      const SizedBox(height: 24),
                      _buildStorageStatus(),
                      const SizedBox(height: 24),
                      _buildDailyQuote(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Featured Tools'),
                      const SizedBox(height: 12),
                      _buildFeaturedTools(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Did You Know?'),
                      const SizedBox(height: 12),
                      _buildProTips(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Explore Categories'),
                      const SizedBox(height: 12),
                      _buildCategories(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Recent Scans', noPadding: true),
                          TextButton(
                            onPressed: () =>
                                MainNavigation.of(context)?.setIndex(1),
                            child: Text(
                              'View All',
                              style: GoogleFonts.outfit(
                                color: DesignSystem.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingHistory)
                        const Center(child: CircularProgressIndicator())
                      else if (_filteredTasks.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.builder(
                          key: _recentKey,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            return _buildRecentItem(task, index);
                          },
                        ),
                      const SizedBox(height: 32),
                      _buildSecurityBadge(),
                      const SizedBox(height: 24),
                      _buildCommunitySection(),
                      const SizedBox(height: 24),
                      _buildReferralCard(),
                      const SizedBox(height: 24),
                      _buildFeedbackWidget(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor(context), // Dynamic background
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DesignSystem.cardColor(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.history_edu_rounded,
              color: Colors.grey[400],
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No recent activity',
            style: GoogleFonts.outfit(
              color: DesignSystem.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning to see your history here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      decoration: const BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                key: _menuKey,
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              FadeInLeft(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(DesignSystem.logoPath, height: 32),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IntelliScan',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'PRO VERSION',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FadeInRight(
                child: GestureDetector(
                  onTap: () => MainNavigation.of(context)?.setIndex(2),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Colors.white70],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : const NetworkImage('https://i.pravatar.cc/100'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user?.displayName?.split(' ')[0] ?? 'Explorer'}! 👋',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What would you like to solve today?',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
    int index,
    Color accentColor, {
    VoidCallback? onTap,
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: 100 * index + 300),
      duration: const Duration(milliseconds: 600),
      child: Container(
        decoration: BoxDecoration(
          color: DesignSystem.surfaceColor(context),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () {},
            borderRadius: BorderRadius.circular(28),
            splashColor: accentColor.withOpacity(0.1),
            highlightColor: accentColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: DesignSystem.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(
                      color: DesignSystem.secondaryText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: DesignSystem.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: TextField(
          style: GoogleFonts.outfit(color: DesignSystem.textColor(context)),
          decoration: InputDecoration(
            hintText: 'Search documents, tools...',
            hintStyle: GoogleFonts.outfit(
              color: DesignSystem.secondaryText(context),
            ),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: DesignSystem.primaryPurple),
            suffixIcon: Icon(
              Icons.mic_none_rounded,
              color: DesignSystem.secondaryText(context),
            ),
          ),
        ),
      ),
    );
  }

  void _showHistoryDetail(dynamic item) {
    final type = item['taskType'] ?? 'Unknown';
    final input = item['inputData'] ?? item['input'] ?? '';
    final result = item['result'] ?? item['output'] ?? '';
    final timestamp = item['timestamp'] != null
        ? DateTime.parse(item['timestamp'])
        : DateTime.now();
    final formattedDate = DateFormat(
      'MMMM dd, yyyy • hh:mm a',
    ).format(timestamp);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DesignSystem.primaryPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: DesignSystem.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.toString().toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: GoogleFonts.outfit(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (input.isNotEmpty) ...[
                      _buildDetailSection('INPUT DATA', input),
                      const SizedBox(height: 24),
                    ],
                    _buildDetailSection(
                      'ANALYSIS RESULT',
                      result,
                      isMarkdown: true,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (result.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: result));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Text'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignSystem.softWhite,
                        foregroundColor: DesignSystem.charcoal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: DesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (result.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening share menu...'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          try {
                            await Share.share(
                              'Scan Result from IntelliScan ($type):\n\n$result',
                              subject: 'IntelliScan Result - $type',
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error sharing: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    String content, {
    bool isMarkdown = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: DesignSystem.primaryPurple,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DesignSystem.softWhite,
            borderRadius: BorderRadius.circular(20),
          ),
          child: isMarkdown
              ? MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.outfit(
                      fontSize: 15,
                      color: DesignSystem.textColor(context),
                      height: 1.5,
                    ),
                  ),
                )
              : Text(
                  content,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: DesignSystem.textColor(context),
                    height: 1.5,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentItem(dynamic task, int index) {
    final DateTime timestamp = DateTime.parse(task['timestamp']);
    final String dateStr = DateFormat('MMM d, h:mm a').format(timestamp);

    IconData getIcon() {
      switch (task['taskType'].toString().toLowerCase()) {
        case 'ocr':
          return Icons.document_scanner_rounded;
        case 'math':
          return Icons.calculate_rounded;
        case 'sketch':
          return Icons.draw_rounded;
        case 'pdf':
          return Icons.picture_as_pdf_rounded;
        case 'guide':
          return Icons.auto_awesome_rounded;
        default:
          return Icons.history_rounded;
      }
    }

    return FadeInUp(
      delay: Duration(milliseconds: 100 * index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showHistoryDetail(task),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignSystem.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DesignSystem.dividerColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DesignSystem.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getIcon(),
                      color: DesignSystem.primaryPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['taskType'].toString().toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                        Text(
                          dateStr,
                          style: GoogleFonts.outfit(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- New Helper Methods ---

  Widget _buildSectionTitle(String title, {bool noPadding = false}) {
    return FadeInLeft(
      child: Padding(
        padding: noPadding
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DesignSystem.charcoal,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return FadeInUp(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2575FC).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.diamond_rounded,
                color: Colors.amber,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Go Premium',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Unlock unlimited scans & AI tools.',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6A11CB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Upgrade'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _buildActionCard(
          context,
          'Scan & OCR',
          'Image to Text',
          Icons.document_scanner_rounded,
          0,
          DesignSystem.primaryPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OCRScreen()),
          ),
        ),
        _buildActionCard(
          context,
          'Math Solver',
          'Solve & Learn',
          Icons.calculate_rounded,
          1,
          DesignSystem.primaryOrange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MathSolverScreen()),
          ),
        ),
        _buildActionCard(
          context,
          'Sketch to SVG',
          'Vectorize Art',
          Icons.draw_rounded,
          2,
          Colors.blueAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SketchSvgScreen()),
          ),
        ),
        _buildActionCard(
          context,
          'PDF Tools',
          'Edit & Convert',
          Icons.picture_as_pdf_rounded,
          3,
          Colors.redAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PDFToolsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageStatus() {
    if (_isLoadingSubscription) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: DesignSystem.softShadow,
        ),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DesignSystem.primaryPurple,
            ),
          ),
        ),
      );
    }

    final int maxCredits = _getMaxCredits(_currentPlan);
    final bool isExpired = _isExpired;

    // Calculate progress (Available / Max)
    // If expired, treat as 0 available for visual purposes
    final int displayCredits = isExpired ? 0 : _availableCredits;
    final double progress = (displayCredits / maxCredits).clamp(0.0, 1.0);

    return FadeInUp(
      child: Container(
        key: _creditsKey,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: DesignSystem.softShadow,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isExpired
                          ? Icons.error_outline_rounded
                          : Icons.bolt_rounded,
                      color: isExpired ? Colors.red : Colors.amber[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isExpired ? 'Plan Expired' : 'Available Credits',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isExpired ? Colors.red : DesignSystem.charcoal,
                      ),
                    ),
                  ],
                ),
                Text(
                  isExpired ? '0 Remaining' : '$displayCredits Remaining',
                  style: GoogleFonts.outfit(
                    color: isExpired ? Colors.red : Colors.amber[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress > 0 ? progress : 0.01,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isExpired
                            ? [Colors.red.shade300, Colors.red]
                            : [Colors.amber.shade300, Colors.amber.shade700],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}% Available',
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  child: Text(
                    isExpired ? 'Renew Now' : 'Upgrade Plan',
                    style: GoogleFonts.outfit(
                      color: DesignSystem.primaryPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyQuote() {
    final List<Map<String, String>> quotes = [
      {
        'text': "The only way to do great work is to love what you do.",
        'author': "Steve Jobs",
      },
      {
        'text': "Believe you can and you're halfway there.",
        'author': "Theodore Roosevelt",
      },
      {
        'text': "It always seems impossible until it's done.",
        'author': "Nelson Mandela",
      },
      {
        'text':
            "Your time is limited, don't waste it living someone else's life.",
        'author': "Steve Jobs",
      },
      {
        'text': "The best way to predict the future is to create it.",
        'author': "Peter Drucker",
      },
      {
        'text': "Don't watch the clock; do what it does. Keep going.",
        'author': "Sam Levenson",
      },
      {
        'text':
            "Success is not final, failure is not fatal: It is the courage to continue that counts.",
        'author': "Winston Churchill",
      },
    ];

    // Seed with day of year to ensure daily rotation
    final int dayOfYear = int.parse(DateFormat('D').format(DateTime.now()));
    final random = Random(DateTime.now().year * 1000 + dayOfYear);
    final quote = quotes[random.nextInt(quotes.length)];

    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1519681393784-d120267933ba?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: DesignSystem.softShadow,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.format_quote_rounded,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(height: 12),
            Text(
              "\"${quote['text']}\"",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "- ${quote['author']}",
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTools() {
    final tools = [
      {
        'icon': FontAwesomeIcons.qrcode,
        'name': 'QR Gen',
        'color': Colors.pinkAccent,
      },
      {
        'icon': Icons.translate_rounded,
        'name': 'Translator',
        'color': Colors.cyan,
      },
      {'icon': Icons.security, 'name': 'Redact', 'color': Colors.black87},
      {
        'icon': Icons.table_chart_rounded,
        'name': 'Excel',
        'color': Colors.green,
      },
    ];

    return SizedBox(
      key: _featuredKey,
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tools.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return GestureDetector(
            onTap: () {
              if (tool['name'] == 'Translator') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SpeechTranslationScreen(),
                  ),
                );
              } else if (tool['name'] == 'Redact') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecurityScreen()),
                );
              } else if (tool['name'] == 'Excel') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SmartInvoiceScreen()),
                );
              } else if (tool['name'] == 'QR Gen') {
                // Placeholder for QR Gen if exists or reuse existing
              }
            },
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                color: DesignSystem.surfaceColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DesignSystem.dividerColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: (tool['color'] as Color).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (tool['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tool['icon'] as IconData,
                      color: tool['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tool['name'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: DesignSystem.textColor(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProTips() {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3E2723) // Darker orange/brown for dark mode
              : const Color(0xfffff8e1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.orange.withOpacity(0.1)
                : Colors.orange.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_rounded,
              color: Colors.orangeAccent,
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tip of the Day',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.orange[200]
                          : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can swipe left on recent items to delete them quickly.',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.orange[100]
                          : Colors.brown[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> get _filteredTasks {
    if (_selectedCategoryIndex == 0) return _allHistory.take(5).toList();

    final categoryTypes = ['all', 'ocr', 'math', 'sketch', 'pdf'];
    final selectedType = categoryTypes[_selectedCategoryIndex];

    // Filter by taskType containing the string (simple matching)
    return _allHistory
        .where(
          (task) =>
              task['taskType'].toString().toLowerCase().contains(selectedType),
        )
        .take(5)
        .toList();
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'All', 'icon': Icons.grid_view_rounded},
      {'name': 'OCR', 'icon': Icons.text_snippet_rounded},
      {'name': 'Math', 'icon': Icons.calculate_rounded},
      {'name': 'Sketch', 'icon': Icons.brush_rounded},
      {'name': 'PDF', 'icon': Icons.picture_as_pdf_rounded},
    ];

    return SizedBox(
      key: _categoriesKey,
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          final category = categories[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? DesignSystem.primaryPurple
                    : DesignSystem.surfaceColor(context),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? DesignSystem.primaryPurple
                      : DesignSystem.dividerColor(context),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: DesignSystem.primaryPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['name'] as String,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Colors.green,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank-Grade Security',
                  style: GoogleFonts.outfit(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your documents are encrypted locally.',
                  style: GoogleFonts.outfit(
                    color: Colors.green[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CommunityScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF5865F2),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x665865F2),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join Community',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect with other pro users.',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Icon(FontAwesomeIcons.discord, color: Colors.white, size: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReferralScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66DD2476),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Refer & Earn',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Get 1 month of Premium free!',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackWidget() {
    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FeedbackScreen()),
        ),
        icon: Icon(
          Icons.thumb_up_alt_outlined,
          color: Colors.grey[400],
          size: 20,
        ),
        label: Text(
          'Enjoying IntelliScan? Rate us!',
          style: GoogleFonts.outfit(color: Colors.grey[500]),
        ),
      ),
    );
  }
}
