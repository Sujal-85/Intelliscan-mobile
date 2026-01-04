import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class DocumentClassificationScreen extends StatefulWidget {
  const DocumentClassificationScreen({super.key});

  @override
  _DocumentClassificationScreenState createState() =>
      _DocumentClassificationScreenState();
}

class _DocumentClassificationScreenState
    extends State<DocumentClassificationScreen> {
  File? _selectedFile;
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _result = null; // Reset result on new file pick
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  Future<void> _classifyDocument() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select an image first.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.classifyEndpoint),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        setState(() {
          _result = data;
        });
      } else {
        throw Exception(
          'Failed to classify document: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          'Document Classification',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeInDown(
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.category_rounded,
                        size: 48,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Identify document types (Invoice, Receipt, ID Card) automatically using AI.',
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
            ),
            const SizedBox(height: 30),
            if (_selectedFile == null)
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: DesignSystem.surfaceColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: DesignSystem.dividerColor(context),
                        width: 2,
                      ),
                      boxShadow: DesignSystem.softShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 60,
                          color: DesignSystem.primaryPurple.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select Document Image',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: DesignSystem.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: DesignSystem.softShadow,
                        image: DecorationImage(
                          image: FileImage(_selectedFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('Change Image', style: GoogleFonts.outfit()),
                      style: TextButton.styleFrom(
                        foregroundColor: DesignSystem.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedFile == null
                      ? null
                      : _classifyDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.blueAccent.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Classify Document',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 30),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: Colors.green,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Analysis Result',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: DesignSystem.textColor(context),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        _buildResultRow(
                          'Category',
                          _result!['classification']['category'],
                          Icons.category_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildResultRow(
                          'Confidence',
                          '${(_result!['classification']['confidence'] * 100).toStringAsFixed(1)}%',
                          Icons.analytics_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildResultRow(
                          'Description',
                          _result!['classification']['description'],
                          Icons.description_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: DesignSystem.secondaryText(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: DesignSystem.textColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
