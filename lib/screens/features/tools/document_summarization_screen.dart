import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class DocumentSummarizationScreen extends StatefulWidget {
  const DocumentSummarizationScreen({super.key});

  @override
  _DocumentSummarizationScreenState createState() =>
      _DocumentSummarizationScreenState();
}

class _DocumentSummarizationScreenState
    extends State<DocumentSummarizationScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String? _summary;
  int _maxSentences = 3;

  Future<void> _summarizeText() async {
    if (_textController.text.isEmpty) {
      _showSnackBar('Please enter detailed text to summarize.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse(ApiConfig.summarizeDocumentEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _textController.text,
          'max_sentences': _maxSentences,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _summary = data['summary'];
        });
      } else {
        throw Exception(
          'Failed to summarize document: ${response.reasonPhrase}',
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
          'Summarizer',
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
                        Icons.summarize_rounded,
                        size: 48,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Condense long documents or articles into a few key sentences automatically.',
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
              child: TextField(
                controller: _textController,
                style: GoogleFonts.outfit(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Enter text to summarize',
                  labelStyle: GoogleFonts.outfit(
                    color: DesignSystem.secondaryText(context),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: DesignSystem.surfaceColor(context),
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(20),
                ),
                keyboardType: TextInputType.multiline,
                minLines: 6,
                maxLines: null,
              ),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignSystem.surfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: DesignSystem.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary Length: $_maxSentences Sentences',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.textColor(context),
                      ),
                    ),
                    Slider(
                      value: _maxSentences.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: Colors.teal,
                      label: _maxSentences.toString(),
                      onChanged: (value) {
                        setState(() {
                          _maxSentences = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _summarizeText,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.teal.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Summarize Text',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            if (_summary != null) ...[
              const SizedBox(height: 30),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: GlassCard(
                  color: Colors.teal.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.teal,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Summary',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: DesignSystem.textColor(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          _summary!,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            height: 1.6,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}
