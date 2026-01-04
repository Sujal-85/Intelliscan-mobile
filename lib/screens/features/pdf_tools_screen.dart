import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/design_system.dart';
import '../../core/config/api_config.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class PDFToolsScreen extends StatefulWidget {
  const PDFToolsScreen({super.key});

  @override
  State<PDFToolsScreen> createState() => _PDFToolsScreenState();
}

class _PDFToolsScreenState extends State<PDFToolsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: DesignSystem.backgroundColor(context),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: TabBarView(
                children: [
                  PDFToolPanel(
                    title: 'Merge PDFs',
                    icon: Icons.merge_type_rounded,
                    desc: 'Combine multiple PDF files into one.',
                    endpoint: ApiConfig.pdfMergeEndpoint,
                    allowMultiple: true,
                  ),
                  PDFToolPanel(
                    title: 'Split PDF',
                    icon: Icons.content_cut_rounded,
                    desc: 'Extract pages from your PDF file.',
                    endpoint: ApiConfig.pdfSplitEndpoint,
                  ),
                  PDFToolPanel(
                    title: 'Compress PDF',
                    icon: Icons.compress_rounded,
                    desc: 'Reduce file size without losing quality.',
                    endpoint: ApiConfig.pdfCompressEndpoint,
                  ),
                  PDFToolPanel(
                    title: 'Image to PDF',
                    icon: Icons.image_outlined,
                    desc: 'Convert JPG/PNG images to PDF document.',
                    endpoint: ApiConfig.pdfImageToPdfEndpoint,
                    allowMultiple: true,
                    allowedExtensions: const ['jpg', 'jpeg', 'png'],
                  ),
                  PDFToolPanel(
                    title: 'PDF to Word',
                    icon: Icons.description_outlined,
                    desc: 'Convert PDF document to editable Word file.',
                    endpoint: ApiConfig.pdfConvertEndpoint,
                    fields: const {'task': 'pdfword'},
                  ),
                  PDFToolPanel(
                    title: 'Word to PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    desc: 'Convert Word document to professional PDF.',
                    endpoint: ApiConfig.pdfConvertEndpoint,
                    fields: const {'task': 'wordpdf'},
                    allowedExtensions: const ['doc', 'docx'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'PDF Tools',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Premium Document Suite',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Spacer to balance back button
              ],
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelPadding: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.only(
              left: 16,
            ), // Move tabs slightly right
            labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'Merge'),
              Tab(text: 'Split'),
              Tab(text: 'Compress'),
              Tab(text: 'Image to PDF'),
              Tab(text: 'To Word'),
              Tab(text: 'To PDF'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class PDFToolPanel extends StatefulWidget {
  final String title;
  final IconData icon;
  final String desc;
  final String endpoint;
  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final Map<String, String>? fields;

  const PDFToolPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.desc,
    required this.endpoint,
    this.allowMultiple = false,
    this.allowedExtensions,
    this.fields,
  });

  @override
  State<PDFToolPanel> createState() => _PDFToolPanelState();
}

class _PDFToolPanelState extends State<PDFToolPanel> {
  bool _isLoading = false;
  List<File> _selectedFiles = [];
  final ApiService _apiService = ApiService();

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: widget.allowMultiple,
      type: widget.allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: widget.allowedExtensions,
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  void _handleAction() async {
    if (_selectedFiles.isEmpty) {
      _showSnackbar('Please select files first', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    _showSnackbar('Processing started...', isInfo: true);

    final result = await _apiService.pdfAction(
      widget.endpoint,
      _selectedFiles,
      fields: widget.fields,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result != null) {
        // _showSnackbar('Task completed! Result saved to History.');
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DesignSystem.surfaceColor(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignSystem.secondaryText(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Processing Complete!',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DesignSystem.textColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your file is ready.',
                  style: GoogleFonts.outfit(
                    color: DesignSystem.secondaryText(context),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Share.shareXFiles([XFile(result.path)]);
                        },
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share File'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      } else {
        _showSnackbar(
          'Action queued successfully! Check History later.',
          isInfo: true,
        );
      }
    }
  }

  void _showSnackbar(
    String message, {
    bool isError = false,
    bool isInfo = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError
            ? Colors.redAccent
            : (isInfo ? DesignSystem.primaryPurple : Colors.green),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          FadeInDown(
            child: Center(
              child: GestureDetector(
                onTap: _pickFiles,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: DesignSystem.surfaceColor(context),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        _selectedFiles.isNotEmpty
                            ? Icons.task_alt_rounded
                            : widget.icon,
                        size: 72,
                        color: _selectedFiles.isNotEmpty
                            ? Colors.green
                            : DesignSystem.primaryPurple,
                      ),
                      if (_isLoading)
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DesignSystem.primaryOrange.withOpacity(0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: Text(
              _selectedFiles.isNotEmpty
                  ? '${_selectedFiles.length} File(s) Selected'
                  : widget.title,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: DesignSystem.textColor(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInDown(
            delay: const Duration(milliseconds: 300),
            child: Text(
              _selectedFiles.isNotEmpty
                  ? _selectedFiles.map((f) => f.path.split('/').last).join(', ')
                  : widget.desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: DesignSystem.secondaryText(context),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 100), // Middle spacing
          FadeInUp(
            child: Column(
              children: [
                if (_selectedFiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextButton.icon(
                      onPressed: () => setState(() => _selectedFiles = []),
                      icon: const Icon(Icons.close_rounded, color: Colors.red),
                      label: Text(
                        'Clear Selection',
                        style: GoogleFonts.outfit(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                CustomGradientButton(
                  text: _isLoading
                      ? 'Processing...'
                      : (_selectedFiles.isEmpty
                            ? 'Select Files'
                            : 'Process Now'),
                  isLoading: _isLoading,
                  onPressed: _selectedFiles.isEmpty
                      ? _pickFiles
                      : _handleAction,
                  icon: _selectedFiles.isEmpty
                      ? Icons.folder_open_rounded
                      : Icons.auto_awesome_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
