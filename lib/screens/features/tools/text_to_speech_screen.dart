import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/api_config.dart';

import 'dart:convert';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class TextToSpeechScreen extends StatefulWidget {
  const TextToSpeechScreen({super.key});

  @override
  State<TextToSpeechScreen> createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String _selectedVoice = 'en-US-ChristopherNeural'; // Default

  // Hardcoding a few good voices for now, ideally fetch from /voices endpoint
  final Map<String, String> _voiceOptions = {
    'en-US-ChristopherNeural': 'US English (Male)',
    'en-US-AriaNeural': 'US English (Female)',
    'en-GB-RyanNeural': 'UK English (Male)',
    'en-GB-SoniaNeural': 'UK English (Female)',
    'hi-IN-MadhurNeural': 'Hindi (Male)',
    'hi-IN-SwaraNeural': 'Hindi (Female)',
  };

  Future<void> _generateSpeech() async {
    if (_textController.text.isEmpty) {
      _showSnackBar('Please enter some text.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.ttsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _textController.text,
          'voice_id': _selectedVoice,
        }),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/speech_output.mp3');
        await file.writeAsBytes(bytes);

        setState(() => _isLoading = false);
        _showSuccessDialog(file);
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Failed to generate speech. Status: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error generating speech: $e', isError: true);
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
          'Audio generated successfully.',
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
              ], text: 'Here is the generated audio!');
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
          'Text to Speech',
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
      body: SingleChildScrollView(
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
                      Icons.record_voice_over_rounded,
                      size: 48,
                      color: Colors.deepPurpleAccent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Turn your text into lifelike spoken audio.',
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
            const SizedBox(height: 20),

            // Voice Selection
            Text(
              'Select Voice',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DesignSystem.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: DesignSystem.surfaceColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DesignSystem.dividerColor(context)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedVoice,
                  isExpanded: true,
                  items: _voiceOptions.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: GoogleFonts.outfit(
                              color: DesignSystem.textColor(context),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedVoice = value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Enter Text',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DesignSystem.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 6,
              style: GoogleFonts.outfit(color: DesignSystem.textColor(context)),
              decoration: InputDecoration(
                hintText: 'Type something to say...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: DesignSystem.surfaceColor(context),
                hintStyle: GoogleFonts.outfit(
                  color: DesignSystem.secondaryText(context),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateSpeech,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Generate Audio',
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
