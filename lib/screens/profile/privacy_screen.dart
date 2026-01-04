import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/design_system.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _biometricEnabled = true;
  bool _historyEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildToggleItem(
                    'Biometric Login',
                    'Use FaceID or Fingerprint',
                    Icons.fingerprint_rounded,
                    _biometricEnabled,
                    (value) => setState(() => _biometricEnabled = value),
                  ),
                  _buildToggleItem(
                    'Usage History',
                    'Save your scan history',
                    Icons.history_rounded,
                    _historyEnabled,
                    (value) => setState(() => _historyEnabled = value),
                  ),
                  const SizedBox(height: 24),
                  _buildActionItem(
                    'Change Password',
                    'Update account security',
                    Icons.lock_outline_rounded,
                  ),
                  _buildActionItem(
                    'Two-Factor Auth',
                    'Add extra security layer',
                    Icons.security_rounded,
                  ),
                  _buildActionItem(
                    'Data Management',
                    'Export or delete data',
                    Icons.data_usage_rounded,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: const BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.privacy_tip_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy & Security',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Control your data',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: DesignSystem.surfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          activeThumbColor: DesignSystem.primaryPurple,
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: DesignSystem.textColor(context),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(
              color: DesignSystem.secondaryText(context),
              fontSize: 13,
            ),
          ),
          secondary: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DesignSystem.primaryPurple.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: DesignSystem.primaryPurple, size: 22),
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionItem(String title, String subtitle, IconData icon) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: DesignSystem.surfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: DesignSystem.textColor(context),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(
              color: DesignSystem.secondaryText(context),
              fontSize: 13,
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DesignSystem.primaryPurple.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: DesignSystem.primaryPurple, size: 22),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          onTap: () {},
        ),
      ),
    );
  }
}
