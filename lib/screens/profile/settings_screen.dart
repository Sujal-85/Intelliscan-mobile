import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/design_system.dart';
// import '../../widgets/glass_card.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: DesignSystem.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Settings',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    _buildSection('Preferences', [
                      _buildSwitchTile(
                        'Push Notifications',
                        'Receive updates and alerts',
                        _notificationsEnabled,
                        (val) => setState(() => _notificationsEnabled = val),
                        Icons.notifications_active_rounded,
                      ),
                      _buildSwitchTile(
                        'Dark Mode',
                        'Switch to dark theme',
                        _darkModeEnabled,
                        (val) {
                          setState(() => _darkModeEnabled = val);
                          ThemeService().toggleTheme(val);
                        },
                        Icons.dark_mode_rounded,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Account', [
                      _buildActionTile(
                        'Change Password',
                        Icons.lock_reset_rounded,
                        () {},
                      ),
                      _buildActionTile(
                        'Delete Account',
                        Icons.delete_forever_rounded,
                        () => _handleDeleteAccount(),
                        isDestructive: true,
                      ),
                      _buildActionTile(
                        'Log Out',
                        Icons.logout_rounded,
                        () => _handleLogout(),
                        isDestructive: true,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
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
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: DesignSystem.textColor(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: DesignSystem.secondaryText(context),
        ),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: DesignSystem.primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: DesignSystem.primaryPurple),
      ),
      activeThumbColor: DesignSystem.primaryPurple,
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : DesignSystem.primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : DesignSystem.primaryPurple,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : DesignSystem.textColor(context),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  Future<void> _handleDeleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                // Show loading
                if (!mounted) return;
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                await _apiService.deleteAccount();
                await _authService.signOut();

                if (!mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete account: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
