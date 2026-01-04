import '../../../core/config/api_config.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class PDFProtectorScreen extends StatefulWidget {
  const PDFProtectorScreen({super.key});

  @override
  State<PDFProtectorScreen> createState() => _PDFProtectorScreenState();
}

class _PDFProtectorScreenState extends State<PDFProtectorScreen> {
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _protectPDF() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select a PDF file.', isError: true);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Please enter a password.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.pdfProtectEndpoint),
      );

      if (_selectedFile!.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _selectedFile!.path!),
        );
      }
      request.fields['password'] = _passwordController.text;

      var response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/protected_${_selectedFile!.name}');
        await file.writeAsBytes(bytes);

        setState(() => _isLoading = false);
        _showSuccessDialog(file);
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Failed to protect PDF. Status: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error protecting PDF: $e', isError: true);
    }
  }

  void _showSuccessDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Success!',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your PDF has been password protected.',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Share.shareXFiles([
                XFile(file.path),
              ], text: 'Here is my protected PDF!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Share / Save'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: isError
            ? Colors.redAccent
            : DesignSystem.primaryPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Protect PDF',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: DesignSystem.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 48,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Encrypt your PDF with a password to prevent unauthorized access.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: DesignSystem.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_selectedFile == null)
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: DesignSystem.surfaceColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: DesignSystem.outlineColor(context),
                      width: 2,
                    ),
                    boxShadow: DesignSystem.softShadow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        size: 50,
                        color: DesignSystem.primaryPurple.withOpacity(0.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Select PDF',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: DesignSystem.textColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              FadeInUp(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignSystem.surfaceColor(context),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: DesignSystem.softShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 40,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textColor(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: _removeFile,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Password Field
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Set Password',
                labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: DesignSystem.primaryPurple,
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(Icons.vpn_key_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _selectedFile == null
                    ? null
                    : _protectPDF,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Encrypt PDF',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
