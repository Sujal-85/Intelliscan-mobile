import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/design_system.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/vault/secure_vault_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/profile/help_screen.dart';
import '../screens/profile/about_screen.dart';
import '../screens/subscription/subscription_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Drawer(
      backgroundColor: DesignSystem.surfaceColor(context),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: DesignSystem.primaryGradient,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        color: DesignSystem.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            accountName: Text(
              user?.displayName ?? 'User',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.lock_outline_rounded,
                  title: 'My Files (Vault)',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SecureVaultScreen(),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.diamond_rounded,
                  title: 'Subscription',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                // const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDrawerItem(
              context,
              icon: Icons.logout_rounded,
              title: 'Log Out',
              color: Colors.redAccent,
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? DesignSystem.primaryPurple),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: color ?? DesignSystem.textColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }
}
