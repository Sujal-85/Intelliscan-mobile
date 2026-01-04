import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/glass_card.dart';
import '../../services/api_service.dart';
import '../../core/config/api_config.dart';
import 'package:file_picker/file_picker.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final ApiService _apiService = ApiService();

  Future<void> _handleSecurityAction(int index) async {
    if (index == 0 || index == 1) {
      if (index == 0) {
        // Protect with Password
        final password = await _showPasswordDialog();
        if (password == null || password.isEmpty) return; // User cancelled

        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null) {
          await _apiService.pdfAction(
            ApiConfig.pdfProtectEndpoint,
            [File(result.files.single.path!)],
            fields: {'password': password},
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF Protected successfully!')),
            );
          }
        }
      } else {
        // Redact
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null) {
          await _apiService.pdfAction(ApiConfig.pdfRedactEndpoint, [
            File(result.files.single.path!),
          ]);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF Redacted successfully!')),
            );
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This feature is coming soon!')),
      );
    }
  }

  Future<String?> _showPasswordDialog() async {
    String? password;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Set PDF Password',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter password',
            hintStyle: GoogleFonts.outfit(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) => password = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, password),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Protect',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32,
              ),
              children: [
                _buildSecurityHealthDashboard(),
                const SizedBox(height: 32),
                _buildMetricGrid(),
                const SizedBox(height: 48),
                Text(
                  'PROTECTION SUITE',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: DesignSystem.primaryPurple,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSecurityCard(
                  'Password Protect PDF',
                  'Add enterprise-grade encryption to your documents.',
                  Icons.lock_person_rounded,
                  0,
                ),
                const SizedBox(height: 16),
                _buildSecurityCard(
                  'Redact Sensitive Text',
                  'Automatically hide PII, emails, and phone numbers.',
                  Icons.visibility_off_rounded,
                  1,
                ),
                const SizedBox(height: 32),
                _buildAuditLog(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 30),
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.primaryPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CYBER',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Security Shield',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityHealthDashboard() {
    return FadeInDown(
      child: GlassCard(
        borderRadius: 32,
        color: DesignSystem.primaryPurple.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: CircularProgressIndicator(
                      value: 0.85,
                      strokeWidth: 8,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DesignSystem.primaryPurple,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '85%',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.primaryPurple,
                        ),
                      ),
                      Text(
                        'Safe',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shield Health: Excellent',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your personal documents are encrypted and shielded against threats.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricGrid() {
    return Row(
      children: [
        _buildMetricCard('Files Scanned', '124', Icons.document_scanner),
        const SizedBox(width: 16),
        _buildMetricCard('Threats Blocked', '0', Icons.gpp_good),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Expanded(
      child: GlassCard(
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: DesignSystem.primaryPurple, size: 28),
              const SizedBox(height: 16),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SECURITY AUDIT LOG',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: DesignSystem.primaryPurple,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 24,
          child: Column(
            children: [
              _buildAuditItem(
                'PDF Redacted',
                '2 mins ago',
                Icons.visibility_off,
              ),
              _buildAuditItem(
                'AES-256 Encryption',
                '1 hour ago',
                Icons.enhanced_encryption,
              ),
              _buildAuditItem('Malware Scan', '3 hours ago', Icons.bug_report),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditItem(String title, String time, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: DesignSystem.primaryPurple, size: 20),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      trailing: Text(
        time,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget _buildSecurityCard(
    String title,
    String desc,
    IconData icon,
    int index,
  ) {
    return FadeInLeft(
      delay: Duration(milliseconds: 100 * index),
      child: GestureDetector(
        onTap: () => _handleSecurityAction(index),
        child: GlassCard(
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignSystem.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: DesignSystem.primaryPurple,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: GoogleFonts.outfit(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
