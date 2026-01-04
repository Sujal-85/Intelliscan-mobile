import '../../../core/config/api_config.dart';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:convert';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class AudioTranscriberScreen extends StatefulWidget {
  const AudioTranscriberScreen({super.key});

  @override
  State<AudioTranscriberScreen> createState() => _AudioTranscriberScreenState();
}

class _AudioTranscriberScreenState extends State<AudioTranscriberScreen> {
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  String? _transcriptionResult;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _transcriptionResult = null; // Reset result on new file
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _transcriptionResult = null;
    });
  }

  Future<void> _transcribeAudio() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select an audio file.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.transcribeEndpoint),
      );

      if (_selectedFile!.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _selectedFile!.path!),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        setState(() {
          _isLoading = false;
          _transcriptionResult = data['text'] ?? 'No text transcribed.';
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Failed to transcribe. Status: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error transcribing audio: $e', isError: true);
    }
  }

  void _copyToClipboard() {
    if (_transcriptionResult != null) {
      // Clipboard is handled by flutter/services usually, assuming imports are fine or user doesn't strictly need it via tool call here.
      // But let's use Share for simplicity and to match other screens pattern of "exporting"
      Share.share(_transcriptionResult!, subject: 'Audio Transcription');
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
          'Audio Transcriber',
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
                        Icons.graphic_eq_rounded,
                        size: 48,
                        color: Colors.pinkAccent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Convert speech in audio files to text automatically.',
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

            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _selectedFile == null
                  ? GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        height: 150,
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
                              Icons.audio_file_rounded,
                              size: 50,
                              color: DesignSystem.primaryPurple.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Select Audio File',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DesignSystem.surfaceColor(context),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: DesignSystem.softShadow,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.audiotrack_rounded,
                            size: 40,
                            color: Colors.pinkAccent,
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

            const SizedBox(height: 30),

            if (_transcriptionResult != null) ...[
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Transcription Result',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: 150,
                        maxHeight: 400,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DesignSystem.surfaceColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: DesignSystem.dividerColor(context),
                        ),
                        boxShadow: DesignSystem.softShadow,
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _transcriptionResult!,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            height: 1.6,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                      ),
                      label: const Text('Share Transcription'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: Colors.pinkAccent.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedFile != null)
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _transcribeAudio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: Colors.pinkAccent.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Transcribe Audio',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
