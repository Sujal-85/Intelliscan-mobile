import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class MultiLanguageOCRScreen extends StatefulWidget {
  const MultiLanguageOCRScreen({super.key});

  @override
  _MultiLanguageOCRScreenState createState() => _MultiLanguageOCRScreenState();
}

class _MultiLanguageOCRScreenState extends State<MultiLanguageOCRScreen> {
  File? _selectedFile;
  bool _isLoading = false;
  String? _resultText;
  String _selectedLanguage = 'eng';
  bool _detectLanguage = true;

  final Map<String, String> _languageOptions = {
    'eng': 'English',
    'ara': 'Arabic',
    'ben': 'Bengali',
    'chi_sim': 'Chinese (Simplified)',
    'chi_tra': 'Chinese (Traditional)',
    'hin': 'Hindi',
    'spa': 'Spanish',
    'fra': 'French',
    'deu': 'German',
    'jpn': 'Japanese',
    'kor': 'Korean',
    'rus': 'Russian',
    'por': 'Portuguese',
  };

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _resultText = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  Future<void> _performOCR() async {
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
        Uri.parse(ApiConfig.multiOcrEndpoint),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      request.fields['target_language'] = _selectedLanguage;
      request.fields['detect_language'] = _detectLanguage.toString();

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        setState(() {
          _resultText = data['text'];
        });
      } else {
        throw Exception('Failed to perform OCR: ${response.reasonPhrase}');
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
          'Multi-language OCR',
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
                        Icons.translate_rounded,
                        size: 48,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Extract text from images in over 10 languages including Hindi, Chinese, and Arabic.',
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
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText: 'Target Language',
                      labelStyle: GoogleFonts.outfit(
                        color: DesignSystem.secondaryText(context),
                      ),
                      filled: true,
                      fillColor: DesignSystem.surfaceColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.language_rounded),
                    ),
                    items: _languageOptions.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: GoogleFonts.outfit(
                                color: DesignSystem.textColor(context),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: DesignSystem.surfaceColor(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: DesignSystem.softShadow,
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Auto-detect Language',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w500,
                          color: DesignSystem.textColor(context),
                        ),
                      ),
                      value: _detectLanguage,
                      activeThumbColor: DesignSystem.primaryPurple,
                      onChanged: (value) {
                        setState(() {
                          _detectLanguage = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    height: 180,
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
                          Icons.add_a_photo_rounded,
                          size: 50,
                          color: Colors.orange.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Upload Image',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
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
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          height: 220,
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black87,
                              ),
                              onPressed: () =>
                                  setState(() => _selectedFile = null),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedFile == null
                      ? null
                      : _performOCR,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.orange.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Extract Text',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            if (_resultText != null) ...[
              const SizedBox(height: 30),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extracted Content',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SelectableText(
                          _resultText!,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            height: 1.6,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _resultText!),
                              );
                              _showSnackBar('Copied to clipboard');
                            },
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Share.share(_resultText!);
                            },
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Share'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
