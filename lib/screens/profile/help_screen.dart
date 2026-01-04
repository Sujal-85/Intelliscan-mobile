import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/design_system.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'FAQs'),
                  _buildFaqItem(
                    context,
                    'How to use OCR?',
                    'Go to OCR screen, upload an image, and wait for text extraction.',
                  ),
                  _buildFaqItem(
                    context,
                    'Is my data safe?',
                    'Yes, we use secure Firebase authentication and encrypted storage.',
                  ),
                  _buildFaqItem(
                    context,
                    'Can I export history?',
                    'History export features will be coming in the next major update.',
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Contact Support'),
                  _buildSupportCard(
                    context,
                    'Email Support',
                    'support@intelliscan.ai',
                    Icons.email_outlined,
                    Colors.blue,
                  ),
                  _buildSupportCard(
                    context,
                    'Chat with Us',
                    'Typical response under 2h',
                    Icons.chat_bubble_outline_rounded,
                    Colors.green,
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
            'Help & Support',
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: DesignSystem.secondaryText(context),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
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
        child: ExpansionTile(
          iconColor: DesignSystem.textColor(context),
          collapsedIconColor: DesignSystem.secondaryText(context),
          title: Text(
            question,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: DesignSystem.textColor(context),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          expandedAlignment: Alignment.topLeft,
          children: [
            Text(
              answer,
              style: GoogleFonts.outfit(
                color: DesignSystem.secondaryText(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: DesignSystem.textColor(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: DesignSystem.secondaryText(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
