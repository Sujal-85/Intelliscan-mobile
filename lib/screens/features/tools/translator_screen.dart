import '../../../core/config/api_config.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import 'dart:convert';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String? _translatedText;
  String _targetLang = 'es'; // Default Spanish

  final Map<String, String> _langOptions = {
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'hi': 'Hindi',
    'zh-CN': 'Chinese (Simplified)',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ru': 'Russian',
    'ar': 'Arabic',
    'en': 'English',
  };

  Future<void> _translate() async {
    if (_textController.text.isEmpty) {
      _showSnackBar('Please enter text to translate.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.translateEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _textController.text,
          'target_lang': _targetLang,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _translatedText = data['translated_text'];
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Failed to translate. Status: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error: $e', isError: true);
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
          'Translator',
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
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Translate text instantly between languages using AI.',
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

            // Language Selection
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Language',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DesignSystem.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: DesignSystem.surfaceColor(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: DesignSystem.softShadow,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _targetLang,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: DesignSystem.primaryPurple,
                        ),
                        items: _langOptions.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  e.value,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: DesignSystem.textColor(context),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _targetLang = value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Input
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: TextField(
                controller: _textController,
                maxLines: 5,
                style: GoogleFonts.outfit(
                  color: DesignSystem.textColor(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Enter text to translate...',
                  hintStyle: GoogleFonts.outfit(
                    color: DesignSystem.secondaryText(context),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: DesignSystem.surfaceColor(context),
                  contentPadding: const EdgeInsets.all(20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: DesignSystem.dividerColor(context),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.cyanAccent,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _translate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.cyanAccent.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Translate',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            if (_translatedText != null) ...[
              const SizedBox(height: 30),
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Translation',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Share.share(_translatedText!),
                          icon: const Icon(
                            Icons.share_rounded,
                            color: Colors.cyan,
                          ),
                          tooltip: 'Share',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.cyan.withOpacity(0.1)
                            : Colors.cyan.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.cyan.withOpacity(0.3)
                              : Colors.cyan.shade200,
                        ),
                      ),
                      child: SelectableText(
                        _translatedText!,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: DesignSystem.textColor(context),
                          height: 1.5,
                        ),
                      ),
                    ),
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
