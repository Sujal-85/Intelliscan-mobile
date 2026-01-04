import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/design_system.dart';
import '../../services/api_service.dart';

class DocumentSummarizerScreen extends StatefulWidget {
  const DocumentSummarizerScreen({super.key});

  @override
  State<DocumentSummarizerScreen> createState() =>
      _DocumentSummarizerScreenState();
}

class _DocumentSummarizerScreenState extends State<DocumentSummarizerScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _textController = TextEditingController();
  String? _summary;
  bool _isLoading = false;

  Future<void> _summarize() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _summary = null;
    });

    try {
      final result = await _apiService.summarizeDocument(text);
      if (mounted) {
        setState(() {
          _summary = result ?? 'Failed to summarize document.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summary = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _textController.text = data!.text!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Smart Summarizer',
          style: GoogleFonts.outfit(
            color: DesignSystem.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignSystem.charcoal,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paste your document text below:',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: DesignSystem.softWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Stack(
                children: [
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    style: GoogleFonts.outfit(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Enter text to summarize...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: IconButton(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(
                        Icons.paste_rounded,
                        color: DesignSystem.primaryPurple,
                      ),
                      tooltip: 'Paste from Clipboard',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _summarize,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _isLoading ? 'Summarizing...' : 'Summarize Text',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_summary != null)
              FadeInUp(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: DesignSystem.primaryPurple.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: DesignSystem.primaryPurple.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Summary',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: DesignSystem.primaryPurple,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: _summary!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Copied to clipboard!'),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.share_rounded,
                                  color: Colors.grey,
                                ),
                                onPressed: () => Share.share(_summary!),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      SelectableText(
                        _summary!,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          height: 1.6,
                          color: DesignSystem.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
