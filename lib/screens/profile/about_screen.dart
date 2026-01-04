import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/design_system.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

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
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: DesignSystem.surfaceColor(context),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: DesignSystem.primaryPurple.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        DesignSystem.logoPath,
                        height: 80,
                        width: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        Text(
                          'IntelliScan',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                        Text(
                          'Version $_version (Build $_buildNumber)',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: DesignSystem.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildInfoTile(
                    'Terms of Service',
                    Icons.description_outlined,
                    0,
                  ),
                  _buildInfoTile('Open Source Licenses', Icons.code_rounded, 1),
                  _buildInfoTile('Rate Us', Icons.star_outline_rounded, 2),
                  const SizedBox(height: 48),
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: Text(
                      '© 2024 IntelliScan AI. All rights reserved.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
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
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'About App',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, IconData icon, int index) {
    return FadeInUp(
      delay: Duration(milliseconds: 100 * index + 400),
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
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DesignSystem.primaryPurple.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: DesignSystem.primaryPurple, size: 22),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: DesignSystem.textColor(context),
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          onTap: () {},
        ),
      ),
    );
  }
}
