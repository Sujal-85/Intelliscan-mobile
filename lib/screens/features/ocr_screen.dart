import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';
import '../../services/api_service.dart';
import '../../services/ai_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  bool _isAnalyzing = false;
  String? _extractedText;
  List<File> _imageFiles = []; // Changed from single File?
  final ApiService _apiService = ApiService();
  final AiService _aiService = AiService();
  final ImagePicker _picker = ImagePicker();
  String _mode = 'standard';
  String? _summary;
  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker
        .pickMultiImage(); // Changed to multi-picker
    if (images.isNotEmpty) {
      setState(() {
        _imageFiles = images.map((x) => File(x.path)).toList();
        _extractedText = null;
        _summary = null;
      });
    }
  }

  void _startAnalysis() async {
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _extractedText = null;
      _summary = null;
    });
    _laserController.repeat(reverse: true);

    StringBuffer combinedText = StringBuffer();
    bool anySuccess = false;

    // Process all files
    for (int i = 0; i < _imageFiles.length; i++) {
      final result = await _apiService.extractText(_imageFiles[i], mode: _mode);
      if (result != null) {
        if (_imageFiles.length > 1) {
          combinedText.writeln("--- Page ${i + 1} ---");
        }
        combinedText.writeln(result);
        combinedText.writeln();
        anySuccess = true;
      }
    }

    setState(() {
      _isAnalyzing = false;
      _laserController.stop();
      if (anySuccess) {
        _extractedText = combinedText.toString();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to extract text. Please try again.'),
          ),
        );
      }
    });
  }

  Future<void> _generateSummary() async {
    if (_extractedText == null) return;
    setState(() => _isSummarizing = true);

    // Using the AI Guide service context for summarization logic
    final result = await _aiService.askGuide([
      ChatMessage(
        role: 'user',
        content:
            "Please summarize this extracted text concisely: \n\n$_extractedText",
      ),
    ]);

    setState(() {
      _isSummarizing = false;
      _summary = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32,
              ),
              child: Column(
                children: [
                  _buildUploadSection(),
                  const SizedBox(height: 32),
                  _buildTypeSelector(),
                  const SizedBox(height: 40),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: CustomGradientButton(
                      text: _isAnalyzing
                          ? 'Analyzing ${_imageFiles.length} Documents...'
                          : 'Start Intelligence Scan',
                      isLoading: _isAnalyzing,
                      onPressed: _startAnalysis,
                      icon: Icons.document_scanner_rounded,
                    ),
                  ),
                  if (_extractedText != null) ...[
                    const SizedBox(height: 40),
                    _buildSmartActions(),
                    const SizedBox(height: 24),
                    _buildResultSection(),
                    if (_summary != null) ...[
                      const SizedBox(height: 24),
                      _buildSummarySection(),
                    ],
                  ],
                  const SizedBox(height: 40),
                ],
              ),
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
                  'DOCUMENT',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Intelligence Scan',
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
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return FadeInDown(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: DesignSystem.surfaceColor(context),
                borderRadius: DesignSystem.radius24,
                // Display first image or placeholder
                image: _imageFiles.isNotEmpty && _imageFiles.length == 1
                    ? DecorationImage(
                        image: FileImage(_imageFiles.first),
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(
                  color: DesignSystem.primaryPurple.withOpacity(0.1),
                  width: 2,
                ),
                boxShadow: DesignSystem.softShadow,
              ),
              child: _imageFiles.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: DesignSystem.primaryPurple.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: DesignSystem.primaryPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select Document Images',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          'Tap to browse gallery (Multi-select supported)',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    )
                  : _imageFiles.length > 1
                  ? GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _imageFiles.length + 1, // +1 for add more
                      itemBuilder: (context, index) {
                        if (index == _imageFiles.length) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add, color: Colors.grey),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imageFiles[index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    )
                  : null, // Single image handles by decoration
            ),
          ),
          if (_isAnalyzing)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _laserController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ScannerLaserPainter(_laserController.value),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mode = 'standard'),
              child: _buildTypeItem(
                'Printed',
                Icons.print,
                _mode == 'standard',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mode = 'high_accuracy'),
              child: _buildTypeItem(
                'Handwritten',
                Icons.edit_note_rounded,
                _mode == 'high_accuracy',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeItem(String label, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isSelected
            ? DesignSystem.primaryPurple.withOpacity(0.05)
            : DesignSystem.surfaceColor(context),
        borderRadius: DesignSystem.radius24,
        border: Border.all(
          color: isSelected ? DesignSystem.primaryPurple : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? DesignSystem.primaryPurple : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? DesignSystem.primaryPurple : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartActions() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SMART ACTIONS',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: DesignSystem.primaryPurple,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(
                'Auto Summarize',
                Icons.summarize_rounded,
                _generateSummary,
                isLoading: _isSummarizing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: GlassCard(
          borderRadius: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(icon, color: DesignSystem.primaryPurple),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI SUMMARY',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            borderRadius: 24,
            color: Colors.green[50]?.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: MarkdownBody(
                data: _summary!,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.outfit(height: 1.6, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadText() async {
    if (_extractedText == null || _extractedText!.isEmpty) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/ocr_result_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await file.writeAsString(_extractedText!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      }
    }
  }

  Widget _buildResultSection() {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extracted Text',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GlassCard(
            borderRadius: 24,
            color: DesignSystem.surfaceColor(context),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SelectableText(
                _extractedText!,
                style: GoogleFonts.outfit(
                  height: 1.6,
                  fontSize: 16,
                  color: DesignSystem.textColor(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (_extractedText != null) {
                      Clipboard.setData(ClipboardData(text: _extractedText!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: DesignSystem.radius16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadText,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Save'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: DesignSystem.radius16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (_extractedText != null && _extractedText!.isNotEmpty) {
                      await Share.share(
                        'Extracted Text from IntelliScan:\n\n$_extractedText',
                        subject: 'IntelliScan OCR Result',
                      );
                    }
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: DesignSystem.radius16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScannerLaserPainter extends CustomPainter {
  final double value;
  _ScannerLaserPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignSystem.primaryPurple
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 10);

    final y = size.height * value;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          DesignSystem.primaryPurple.withOpacity(0.0),
          DesignSystem.primaryPurple.withOpacity(0.2),
          DesignSystem.primaryPurple.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 40, size.width, 80));

    canvas.drawRect(Rect.fromLTWH(0, y - 40, size.width, 80), gradientPaint);
  }

  @override
  bool shouldRepaint(_ScannerLaserPainter oldDelegate) =>
      oldDelegate.value != value;
}
