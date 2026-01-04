import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../../services/notification_service.dart';
import '../../core/config/api_config.dart';

import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/glass_card.dart';

// New Feature Imports
import 'tools/pdf_merger_screen.dart';
import 'tools/pdf_splitter_screen.dart';
import 'tools/pdf_compressor_screen.dart';
import 'tools/image_to_pdf_screen.dart';
import 'tools/pdf_protector_screen.dart';
import 'tools/pdf_unlocker_screen.dart';
import 'tools/pdf_rotator_screen.dart';
import 'tools/pdf_converter_screen.dart';
import 'tools/smart_redaction_screen.dart';
import 'tools/audio_transcriber_screen.dart';
import 'tools/text_to_speech_screen.dart';
import 'tools/translator_screen.dart';
import 'tools/digital_signature_screen.dart';
import 'tools/document_classification_screen.dart';
import 'tools/multi_language_ocr_screen.dart';
import 'tools/image_enhancement_screen.dart';
import 'tools/document_summarization_screen.dart';
import 'tools/invoice_extraction_screen.dart';
import 'tools/table_extraction_screen.dart';
import 'tools/barcode_detection_screen.dart';
import 'tools/qr_generator_screen.dart';

class AdvancedFeaturesScreen extends StatefulWidget {
  const AdvancedFeaturesScreen({super.key});

  @override
  _AdvancedFeaturesScreenState createState() => _AdvancedFeaturesScreenState();
}

class _AdvancedFeaturesScreenState extends State<AdvancedFeaturesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Feature Data Model
  final List<Map<String, dynamic>> _allFeatures = [
    // PDF Tools
    {
      'title': 'Merge PDFs',
      'description': 'Combine multiple PDFs into one.',
      'icon': Icons.merge_type_rounded,
      'color': Colors.blueAccent,
      'category': 'PDF Tools',
      'screen': const PDFMergerScreen(),
    },
    {
      'title': 'Split PDF',
      'description': 'Extract pages from a PDF document.',
      'icon': Icons.call_split_rounded,
      'color': Colors.orangeAccent,
      'category': 'PDF Tools',
      'screen': const PDFSplitterScreen(),
    },
    {
      'title': 'Compress PDF',
      'description': 'Reduce file size while maintaining quality.',
      'icon': Icons.compress_rounded,
      'color': Colors.greenAccent,
      'category': 'PDF Tools',
      'screen': const PDFCompressorScreen(),
    },
    {
      'title': 'Image to PDF',
      'description': 'Convert images to a single PDF.',
      'icon': Icons.image_rounded,
      'color': Colors.purpleAccent,
      'category': 'PDF Tools',
      'screen': const ImageToPDFScreen(),
    },
    {
      'title': 'Protect PDF',
      'description': 'Add password protection to your PDF.',
      'icon': Icons.lock_outline_rounded,
      'color': Colors.redAccent,
      'category': 'PDF Tools',
      'screen': const PDFProtectorScreen(),
    },
    {
      'title': 'Unlock PDF',
      'description': 'Remove password security from PDF.',
      'icon': Icons.lock_open_rounded,
      'color': Colors.tealAccent,
      'category': 'PDF Tools',
      'screen': const PDFUnlockerScreen(),
    },
    {
      'title': 'Rotate PDF',
      'description': 'Rotate PDF pages permanently.',
      'icon': Icons.rotate_right_rounded,
      'color': Colors.indigoAccent,
      'category': 'PDF Tools',
      'screen': const PDFRotatorScreen(),
    },
    {
      'title': 'Convert PDF',
      'description': 'Convert PDF to Word, Excel, PowerPoint.',
      'icon': Icons.transform_rounded,
      'color': Colors.deepOrange,
      'category': 'PDF Tools',
      'screen': const PDFConverterScreen(),
    },
    {
      'title': 'Smart Redaction',
      'description': 'Auto-redact sensitive info like emails.',
      'icon': Icons.visibility_off_rounded,
      'color': Colors.black87,
      'category': 'PDF Tools',
      'screen': const SmartRedactionScreen(),
    },

    // Audio & Speech
    {
      'title': 'Audio Transcriber',
      'description': 'Convert audio files to text.',
      'icon': Icons.graphic_eq_rounded,
      'color': Colors.pinkAccent,
      'category': 'Audio & Speech',
      'screen': const AudioTranscriberScreen(),
    },
    {
      'title': 'Text to Speech',
      'description': 'Generate lifelike speech from text.',
      'icon': Icons.record_voice_over_rounded,
      'color': Colors.deepPurpleAccent,
      'category': 'Audio & Speech',
      'screen': const TextToSpeechScreen(),
    },
    {
      'title': 'Translator',
      'description': 'Translate text between languages.',
      'icon': Icons.translate_rounded,
      'color': Colors.cyanAccent,
      'category': 'Audio & Speech',
      'screen': const TranslatorScreen(),
    },

    // Creative Tools
    {
      'title': 'Digital Signature',
      'description': 'Create and save digital signatures.',
      'icon': Icons.gesture_rounded,
      'color': Colors.brown,
      'category': 'Creative Tools',
      'screen': const DigitalSignatureScreen(),
    },

    // AI Utilities
    {
      'title': 'Document Classification',
      'description': 'Classify documents as invoice, receipt, etc.',
      'icon': Icons.category_rounded,
      'color': Colors.blue,
      'category': 'AI Utilities',
      'screen': const DocumentClassificationScreen(),
    },
    {
      'title': 'Multi-language OCR',
      'description': 'OCR in multiple languages.',
      'icon': Icons.text_fields_rounded,
      'color': Colors.orange,
      'category': 'AI Utilities',
      'screen': const MultiLanguageOCRScreen(),
    },
    {
      'title': 'Image Enhancement',
      'description': 'Enhance images for better clarity.',
      'icon': Icons.auto_fix_high_rounded,
      'color': Colors.purple,
      'category': 'AI Utilities',
      'screen': const ImageEnhancementScreen(),
    },
    {
      'title': 'Document Summarization',
      'description': 'Summarize long documents.',
      'icon': Icons.summarize_rounded,
      'color': Colors.teal,
      'category': 'AI Utilities',
      'screen': const DocumentSummarizationScreen(),
    },
    {
      'title': 'Invoice Extraction',
      'description': 'Extract data from invoices.',
      'icon': Icons.receipt_long_rounded,
      'color': Colors.green,
      'category': 'AI Utilities',
      'screen': const InvoiceExtractionScreen(),
    },
    {
      'title': 'Table Extraction',
      'description': 'Extract tables to CSV/Excel.',
      'icon': Icons.table_chart_rounded,
      'color': Colors.redAccent,
      'category': 'AI Utilities',
      'screen': const TableExtractionScreen(),
    },
    {
      'title': 'Barcode Detection',
      'description': 'Detect and decode barcodes.',
      'icon': Icons.qr_code_scanner_rounded,
      'color': Colors.amber,
      'category': 'AI Utilities',
      'screen': const BarcodeDetectionScreen(),
    },
    {
      'title': 'QR Generator',
      'description': 'Generate custom QR codes.',
      'icon': Icons.qr_code_2_rounded,
      'color': Colors.blue,
      'category': 'AI Utilities',
      'screen': const QrGeneratorScreen(),
    },
  ];

  List<Map<String, dynamic>> get _filteredFeatures {
    if (_searchQuery.isEmpty) return _allFeatures;
    return _allFeatures.where((feature) {
      final title = feature['title'].toString().toLowerCase();
      final description = feature['description'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedFeatures {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var feature in _filteredFeatures) {
      final category = feature['category'] as String;
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(feature);
    }
    return grouped;
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _groupedFeatures.entries.expand((entry) {
                  return [
                    _buildSectionTitle(entry.key),
                    ...entry.value.asMap().entries.map((featureEntry) {
                      final index = featureEntry.key;
                      final feature = featureEntry.value;
                      return _buildFeatureCard(
                        title: feature['title'],
                        description: feature['description'],
                        icon: feature['icon'],
                        color: feature['color'],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => feature['screen']),
                        ),
                        index: index,
                      );
                    }),
                    const SizedBox(height: 10),
                  ];
                }).toList()..add(const SizedBox(height: 80)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 16),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: DesignSystem.secondaryText(context),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: Text(
                      'Advanced',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Features',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              FadeInDown(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_motion_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search tools...',
                hintStyle: GoogleFonts.outfit(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required int index,
    Color color = DesignSystem.primaryPurple,
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: 100 * (index % 5)), // Limit delay stacking
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          borderRadius: 20,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            title: Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: DesignSystem.textColor(context),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                description,
                style: GoogleFonts.outfit(
                  color: DesignSystem.secondaryText(context),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class DocumentComparisonScreen extends StatefulWidget {
  const DocumentComparisonScreen({super.key});

  @override
  _DocumentComparisonScreenState createState() =>
      _DocumentComparisonScreenState();
}

class _DocumentComparisonScreenState extends State<DocumentComparisonScreen> {
  static const String _apiBaseUrl = '${ApiConfig.baseUrl}/api/advanced';
  final TextEditingController _text1Controller = TextEditingController();
  final TextEditingController _text2Controller = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _comparisonResult;

  Future<void> _compareDocuments() async {
    if (_text1Controller.text.isEmpty || _text2Controller.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse('$_apiBaseUrl/compare-documents'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text1': _text1Controller.text,
          'text2': _text2Controller.text,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _comparisonResult = data;
        });

        // Notify User
        await NotificationService().showTaskCompleteNotification(
          "Document Comparison",
          "Similarity: ${(data['similarity'] * 100).toStringAsFixed(1)}%",
        );
      } else {
        throw Exception(
          'Failed to compare documents: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Document Comparison',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: DesignSystem.primaryGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Document 1:',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: DesignSystem.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _text1Controller,
              minLines: 3,
              maxLines: 5,
              style: GoogleFonts.outfit(color: DesignSystem.textColor(context)),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignSystem.outlineColor(context),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignSystem.outlineColor(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignSystem.primaryPurple),
                ),
                filled: true,
                fillColor: DesignSystem.surfaceColor(context),
              ),
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
            Text(
              'Document 2:',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: DesignSystem.textColor(context),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _text2Controller,
              minLines: 3,
              maxLines: 5,
              style: GoogleFonts.outfit(color: DesignSystem.textColor(context)),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignSystem.outlineColor(context),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignSystem.outlineColor(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignSystem.primaryPurple),
                ),
                filled: true,
                fillColor: DesignSystem.surfaceColor(context),
              ),
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _compareDocuments,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Compare Documents',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            if (_comparisonResult != null) ...[
              const SizedBox(height: 24),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparison Results:',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Similarity: ${(_comparisonResult!['similarity'] * 100).toStringAsFixed(2)}%',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: DesignSystem.textColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Summary:',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.textColor(context),
                        ),
                      ),
                      Text(
                        _comparisonResult!['summary'],
                        style: GoogleFonts.outfit(
                          color: DesignSystem.secondaryText(context),
                        ),
                      ),
                      if (_comparisonResult!['semantic_analysis'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Semantic Analysis:',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                        Text(
                          _comparisonResult!['semantic_analysis'],
                          style: GoogleFonts.outfit(
                            color: DesignSystem.secondaryText(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HandwritingAnalysisScreen extends StatefulWidget {
  const HandwritingAnalysisScreen({super.key});

  @override
  _HandwritingAnalysisScreenState createState() =>
      _HandwritingAnalysisScreenState();
}

class _HandwritingAnalysisScreenState extends State<HandwritingAnalysisScreen> {
  static const String _apiBaseUrl = 'http://localhost:8000/api/advanced';
  File? _selectedFile;
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _analyzeHandwriting() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/analyze-handwriting'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        setState(() {
          _analysisResult = data['analysis'];
        });

        // Notify User
        await NotificationService().showTaskCompleteNotification(
          "Handwriting Analysis",
          "Score: ${data['analysis']['legibility_score']}/10",
        );
      } else {
        throw Exception(
          'Failed to analyze handwriting: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Handwriting Analysis',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: DesignSystem.primaryGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Handwriting Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: DesignSystem.outlineColor(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedFile!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _analyzeHandwriting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Analyze Handwriting'),
              ),
            ],
            if (_analysisResult != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analysis Results:',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAnalysisField(
                        'Legibility Score',
                        '${_analysisResult!['legibility_score']}/10',
                      ),
                      _buildAnalysisField(
                        'Writing Style',
                        _analysisResult!['writing_style'],
                      ),
                      _buildAnalysisField(
                        'Slant Direction',
                        _analysisResult!['slant_direction'],
                      ),
                      _buildAnalysisField(
                        'Letter Size Consistency',
                        _analysisResult!['letter_size_consistency'],
                      ),
                      _buildAnalysisField(
                        'Line Spacing Regular',
                        _analysisResult!['line_spacing_regular'].toString(),
                      ),
                      if (_analysisResult!['characteristics'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Characteristics:',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                        ..._analysisResult!['characteristics']
                            .map<Widget>(
                              (char) => Text(
                                '• $char',
                                style: GoogleFonts.outfit(
                                  color: DesignSystem.textColor(context),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                      if (_analysisResult!['estimated_traits'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Estimated Traits:',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                        ..._analysisResult!['estimated_traits']
                            .map<Widget>(
                              (trait) => Text(
                                '• $trait',
                                style: GoogleFonts.outfit(
                                  color: DesignSystem.textColor(context),
                                ),
                              ),
                            )
                            .toList(),
                      ],
                      if (_analysisResult!['recognized_text'] != null &&
                          _analysisResult!['recognized_text'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Recognized Text:',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                        SelectableText(
                          _analysisResult!['recognized_text'],
                          style: GoogleFonts.outfit(
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                      ],
                      if (_analysisResult!['analysis_notes'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Notes:',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                        Text(
                          _analysisResult!['analysis_notes'],
                          style: GoogleFonts.outfit(
                            color: DesignSystem.secondaryText(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisField(String label, String value) {
    if (value.isEmpty || value == 'null') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label: ',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: DesignSystem.textColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(color: DesignSystem.textColor(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class AudioEnhancementScreen extends StatefulWidget {
  const AudioEnhancementScreen({super.key});

  @override
  _AudioEnhancementScreenState createState() => _AudioEnhancementScreenState();
}

class _AudioEnhancementScreenState extends State<AudioEnhancementScreen> {
  static const String _apiBaseUrl = 'http://localhost:8000/api/advanced';
  File? _selectedFile;
  bool _isLoading = false;
  File? _enhancedAudioFile;
  String _enhancementType = 'denoise';

  final Map<String, String> _enhancementOptions = {
    'denoise': 'Noise Reduction',
    'amplify': 'Amplification',
    'normalize': 'Normalization',
  };

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _enhanceAudio() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/enhance-audio'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      request.fields['enhancement_type'] = _enhancementType;

      var response = await request.send();

      if (response.statusCode == 200) {
        // Save the enhanced audio to a temporary file
        var bytes = await response.stream.toBytes();
        String tempPath =
            '${Directory.systemTemp.path}/enhanced_${path.basename(_selectedFile!.path)}';
        File tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes);

        setState(() {
          _enhancedAudioFile = tempFile;
        });
      } else {
        throw Exception('Failed to enhance audio: ${response.reasonPhrase}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Audio Enhancement',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: DesignSystem.primaryGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Audio File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _enhancementType,
              style: GoogleFonts.outfit(color: DesignSystem.textColor(context)),
              dropdownColor: DesignSystem.surfaceColor(context),
              decoration: InputDecoration(
                labelText: 'Enhancement Type',
                labelStyle: GoogleFonts.outfit(
                  color: DesignSystem.secondaryText(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignSystem.outlineColor(context),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignSystem.outlineColor(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignSystem.primaryPurple),
                ),
                filled: true,
                fillColor: DesignSystem.surfaceColor(context),
              ),
              items: _enhancementOptions.entries
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
                  _enhancementType = value!;
                });
              },
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 16),
              Text(
                'Original Audio: ${path.basename(_selectedFile!.path)}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: DesignSystem.textColor(context),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _enhanceAudio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enhance Audio'),
              ),
            ],
            if (_enhancedAudioFile != null) ...[
              const SizedBox(height: 16),
              Text(
                'Enhanced Audio:',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.textColor(context),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  // Save the enhanced audio
                  String? outputPath = await FilePicker.platform.saveFile(
                    fileName: 'enhanced_${path.basename(_selectedFile!.path)}',
                  );

                  if (outputPath != null) {
                    await File(
                      outputPath,
                    ).writeAsBytes(await _enhancedAudioFile!.readAsBytes());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Audio saved successfully!',
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Enhanced Audio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WatermarkingScreen extends StatefulWidget {
  const WatermarkingScreen({super.key});

  @override
  _WatermarkingScreenState createState() => _WatermarkingScreenState();
}

class _WatermarkingScreenState extends State<WatermarkingScreen> {
  static const String _apiBaseUrl = 'http://localhost:8000/api/advanced';
  File? _selectedFile;
  final TextEditingController _watermarkTextController =
      TextEditingController();
  bool _isLoading = false;
  File? _watermarkedImageFile;
  bool _isVisible = true;
  String _position = 'bottom-right';

  final Map<String, String> _positionOptions = {
    'top-left': 'Top Left',
    'top-right': 'Top Right',
    'center': 'Center',
    'bottom-left': 'Bottom Left',
    'bottom-right': 'Bottom Right',
  };

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _addWatermark() async {
    if (_selectedFile == null || _watermarkTextController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse('$_apiBaseUrl/add-watermark'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _watermarkTextController.text,
          'visible': _isVisible,
          'position': _position,
        }),
      );

      if (response.statusCode == 200) {
        // Handle file response
        var bytes = response.bodyBytes;
        String tempPath =
            '\${Directory.systemTemp.path}/watermarked_\${path.basename(_selectedFile!.path)}';
        File tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes);

        setState(() {
          _watermarkedImageFile = tempFile;
        });
      } else {
        throw Exception('Failed to add watermark: ${response.reasonPhrase}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Document Watermarking',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: DesignSystem.primaryGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _watermarkTextController,
              style: GoogleFonts.outfit(color: DesignSystem.textColor(context)),
              decoration: InputDecoration(
                labelText: 'Watermark Text',
                labelStyle: GoogleFonts.outfit(
                  color: DesignSystem.secondaryText(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignSystem.outlineColor(context),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignSystem.outlineColor(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignSystem.primaryPurple),
                ),
                filled: true,
                fillColor: DesignSystem.surfaceColor(context),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Visible Watermark',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.textColor(context),
                ),
              ),
              value: _isVisible,
              activeThumbColor: DesignSystem.primaryPurple,
              onChanged: (value) {
                setState(() {
                  _isVisible = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _position,
              style: GoogleFonts.outfit(color: DesignSystem.textColor(context)),
              dropdownColor: DesignSystem.surfaceColor(context),
              decoration: InputDecoration(
                labelText: 'Watermark Position',
                labelStyle: GoogleFonts.outfit(
                  color: DesignSystem.secondaryText(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignSystem.outlineColor(context),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: DesignSystem.outlineColor(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DesignSystem.primaryPurple),
                ),
                filled: true,
                fillColor: DesignSystem.surfaceColor(context),
              ),
              items: _positionOptions.entries
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
                  _position = value!;
                });
              },
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 16),
              Text(
                'Original Image:',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.textColor(context),
                ),
              ),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: DesignSystem.outlineColor(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedFile!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addWatermark,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Watermark'),
              ),
            ],
            if (_watermarkedImageFile != null) ...[
              const SizedBox(height: 16),
              Text(
                'Watermarked Image:',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.textColor(context),
                ),
              ),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: DesignSystem.outlineColor(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _watermarkedImageFile!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  // Save the watermarked image
                  String? outputPath = await FilePicker.platform.saveFile(
                    fileName:
                        'watermarked_${path.basename(_selectedFile!.path)}',
                  );

                  if (outputPath != null) {
                    await File(
                      outputPath,
                    ).writeAsBytes(await _watermarkedImageFile!.readAsBytes());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Image saved successfully!',
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Watermarked Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BatchProcessingScreen extends StatefulWidget {
  const BatchProcessingScreen({super.key});

  @override
  _BatchProcessingScreenState createState() => _BatchProcessingScreenState();
}

class _BatchProcessingScreenState extends State<BatchProcessingScreen> {
  static const String _apiBaseUrl = 'http://localhost:8000/api/advanced';
  List<File> _selectedFiles = [];
  bool _isLoading = false;
  List<Map<String, dynamic>>? _results;
  final List<String> _selectedFeatures = [];

  final List<Map<String, String>> _availableFeatures = [
    {'id': 'document_classification', 'name': 'Document Classification'},
    {'id': 'multi_language_ocr', 'name': 'Multi-language OCR'},
    {'id': 'image_enhancement', 'name': 'Image Enhancement'},
    {'id': 'document_summarization', 'name': 'Document Summarization'},
    {'id': 'invoice_extraction', 'name': 'Invoice Extraction'},
    {'id': 'table_extraction', 'name': 'Table Extraction'},
    {'id': 'barcode_detection', 'name': 'Barcode Detection'},
    {'id': 'handwriting_analysis', 'name': 'Handwriting Analysis'},
    {'id': 'watermark_addition', 'name': 'Watermark Addition'},
  ];

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      List<File> files = result.files.map((file) => File(file.path!)).toList();
      setState(() {
        _selectedFiles = files;
      });
    }
  }

  Future<void> _processBatch() async {
    if (_selectedFiles.isEmpty || _selectedFeatures.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/batch-process'),
      );

      // Add files
      for (File file in _selectedFiles) {
        request.files.add(
          await http.MultipartFile.fromPath('files', file.path),
        );
      }

      // Add features as JSON
      request.fields['features'] = jsonEncode(_selectedFeatures);

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        setState(() {
          _results = List<Map<String, dynamic>>.from(data['results']);
        });
      } else {
        throw Exception('Failed to process batch: ${response.reasonPhrase}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Batch Processing',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: DesignSystem.primaryGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Multiple Files'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignSystem.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Selected ${_selectedFiles.length} files',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: DesignSystem.textColor(context),
              ),
            ),
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: DesignSystem.outlineColor(context),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedFiles[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Select Features to Apply:',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DesignSystem.textColor(context),
              ),
            ),
            ..._availableFeatures.map(
              (feature) => CheckboxListTile(
                title: Text(
                  feature['name']!,
                  style: GoogleFonts.outfit(
                    color: DesignSystem.textColor(context),
                  ),
                ),
                value: _selectedFeatures.contains(feature['id']),
                activeColor: DesignSystem.primaryPurple,
                checkColor: Colors.white,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedFeatures.add(feature['id']!);
                    } else {
                      _selectedFeatures.remove(feature['id']);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedFeatures.isEmpty ? null : _processBatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedFeatures.isEmpty
                    ? Colors.grey
                    : DesignSystem.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Process Batch'),
            ),
            if (_results != null) ...[
              const SizedBox(height: 16),
              Text(
                'Processing Results:',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.textColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _results!.length,
                  itemBuilder: (context, index) {
                    var result = _results![index];
                    return GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'File: ${result['filename']}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: DesignSystem.textColor(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Features applied: ${result['features_applied'].join(', ')}',
                              style: GoogleFonts.outfit(
                                color: DesignSystem.secondaryText(context),
                              ),
                            ),
                            if (result['results'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Results:',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w500,
                                  color: DesignSystem.textColor(context),
                                ),
                              ),
                              ...result['results'].entries.map<Widget>((entry) {
                                String key = entry.key;
                                dynamic value = entry.value;

                                if (value is Map &&
                                    value.containsKey('error')) {
                                  return Text(
                                    '  $key: ERROR - ${value['error']}',
                                    style: GoogleFonts.outfit(
                                      color: Colors.red,
                                    ),
                                  );
                                }

                                return Text(
                                  '  $key: Processed successfully',
                                  style: GoogleFonts.outfit(
                                    color: Colors.green,
                                  ),
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
