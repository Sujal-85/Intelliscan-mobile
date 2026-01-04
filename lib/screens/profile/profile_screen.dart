import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/design_system.dart';
import '../../widgets/glass_card.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'personal_info_screen.dart';
import 'privacy_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import '../features/social/feedback_screen.dart';
import '../features/social/referral_screen.dart';
import '../auth/login_screen.dart';
import 'my_files_screen.dart';
import '../subscription/subscription_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  File? _imageFile;
  bool _isLoadingImage = false;

  bool _isPicking = false;

  Future<void> _pickAndCropImage() async {
    if (_isPicking) return;

    setState(() => _isPicking = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Edit Profile Picture',
              toolbarColor: DesignSystem.primaryPurple,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Edit Profile Picture'),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _imageFile = File(croppedFile.path);
            _isLoadingImage = true;
          });

          // Upload logic here
          await _apiService.updateAvatar(_imageFile!);

          setState(() => _isLoadingImage = false);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _openCommunity() async {
    const discordUrl = 'https://discord.gg/3yeMGkmY';
    await _launchURL(discordUrl);
  }

  Future<void> _handleProtectedAccess(
    BuildContext context,
    String key,
    VoidCallback onSuccess,
  ) async {
    final prefs = await SharedPreferences.getInstance(); // Ensure import
    final storedPin = prefs.getString(key);

    if (storedPin == null) {
      // Set PIN
      if (!mounted) return;
      _showPinDialog(context, 'Set New PIN', (pin) async {
        await prefs.setString(key, pin);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('PIN secured!')));
          onSuccess();
        }
      });
    } else {
      // Verify PIN
      if (!mounted) return;
      _showPinDialog(context, 'Enter PIN', (pin) {
        if (pin == storedPin) {
          onSuccess();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
        }
      });
    }
  }

  void _showPinDialog(
    BuildContext context,
    String title,
    Function(String) onSubmit,
  ) {
    String pin = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          onChanged: (value) => pin = value,
          decoration: const InputDecoration(
            hintText: '****',
            counterText: '',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pin.length == 4) {
                Navigator.pop(context);
                onSubmit(pin);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current User Data (Reloading where possible)
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      body: Column(
        children: [
          _buildProfileHeader(user), // Fixed Header
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Section 1: Account
                    _buildSectionTitle('Account'),
                    _buildSettingItem(
                      'Edit Profile',
                      Icons.edit_rounded,
                      0,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      ),
                    ),
                    _buildSettingItem(
                      'Personal Info',
                      Icons.person_outline_rounded,
                      1,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PersonalInfoScreen(),
                        ),
                      ),
                    ),
                    _buildSettingItem(
                      'Privacy & Security',
                      Icons.security_rounded,
                      2,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Section 2: Social & Community
                    _buildSectionTitle('Community & Rewards'),
                    _buildSettingItem(
                      'Refer & Earn',
                      Icons.card_giftcard_rounded,
                      3,
                      iconColor: Colors.pink,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReferralScreen(),
                        ),
                      ),
                    ),
                    _buildSettingItem(
                      'Join Community',
                      FontAwesomeIcons.discord,
                      4,
                      iconColor: const Color(0xFF5865F2),
                      onTap: _openCommunity,
                    ),
                    _buildSettingItem(
                      'Feedback',
                      Icons.thumb_up_alt_outlined,
                      5,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Section 3: App Info users asked for
                    _buildSectionTitle('More'),
                    _buildSettingItem(
                      'My Files',
                      Icons.folder_open_rounded,
                      6,
                      onTap: () => _handleProtectedAccess(
                        context,
                        'my_files_pin',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyFilesScreen(),
                          ),
                        ),
                      ),
                    ),
                    _buildSettingItem(
                      'Subscriptions',
                      Icons.subscriptions_outlined,
                      7,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      ),
                    ),
                    _buildSettingItem(
                      'Settings',
                      Icons.settings_outlined,
                      8,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ),
                    ),
                    _buildSettingItem(
                      'Help & Support',
                      Icons.help_outline_rounded,
                      9,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpScreen(),
                        ),
                      ),
                    ),
                    _buildSettingItem(
                      'About App',
                      Icons.info_outline_rounded,
                      10,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: TextButton.icon(
                        onPressed: () async {
                          await _authService.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: DesignSystem.secondaryText(context),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      decoration: const BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          FadeInScale(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _pickAndCropImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: DesignSystem.surfaceColor(context),
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (user?.photoURL != null
                                    ? NetworkImage(user!.photoURL!)
                                    : const NetworkImage(
                                        'https://i.pravatar.cc/300',
                                      ))
                                as ImageProvider,
                      child: _isLoadingImage
                          ? const CircularProgressIndicator()
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAndCropImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: DesignSystem.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeInDown(
            child: Text(
              user?.displayName ?? 'User',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: Text(
              user?.email ?? 'No email',
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon,
    int index, {
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return FadeInUp(
      delay: Duration(
        milliseconds: 50 * index + 100,
      ), // Slightly faster staggered animation
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          borderRadius: 16,
          child: ListTile(
            leading: Icon(icon, color: iconColor ?? DesignSystem.primaryPurple),
            title: Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: DesignSystem.textColor(context),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
            ),
            onTap: onTap,
          ),
        ),
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
