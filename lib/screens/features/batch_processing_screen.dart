import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/design_system.dart';
import '../../services/api_service.dart';

class BatchProcessingScreen extends StatefulWidget {
  const BatchProcessingScreen({super.key});

  @override
  State<BatchProcessingScreen> createState() => _BatchProcessingScreenState();
}

class _BatchProcessingScreenState extends State<BatchProcessingScreen> {
  final ApiService _apiService = ApiService();
  List<PlatformFile> _files = [];
  final Map<String, String> _results = {};
  final Map<String, bool> _processing = {};
  final Map<String, bool> _completed = {};
  String _selectedAction = 'OCR'; // OCR, Invoice, Enhance

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _files = result.files;
        _results.clear();
        _processing.clear();
        _completed.clear();
      });
    }
  }

  Future<void> _processAll() async {
    if (_files.isEmpty) return;

    setState(() {
      for (var file in _files) {
        _processing[file.name] = true;
        _completed[file.name] = false;
      }
    });

    // Parallel processing
    await Future.wait(_files.map((file) => _processFile(file)));
  }

  Future<void> _processFile(PlatformFile file) async {
    try {
      if (file.path == null) return;
      final File imageFile = File(file.path!);
      String? result;

      if (_selectedAction == 'OCR') {
        result = await _apiService.extractText(imageFile);
      } else if (_selectedAction == 'Invoice') {
        final data = await _apiService.extractInvoiceData(imageFile);
        if (data != null) result = data.toString();
      } else if (_selectedAction == 'Objects') {
        final data = await _apiService.recognizeObjects(imageFile);
        if (data != null) result = data['objects'].toString();
      }

      if (mounted) {
        setState(() {
          _results[file.name] = result ?? 'Failed';
          _processing[file.name] = false;
          _completed[file.name] = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results[file.name] = 'Error: $e';
          _processing[file.name] = false;
          _completed[file.name] = true;
        });
      }
    }
  }

  void _showResult(String fileName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Result: $fileName',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _results[fileName] ?? 'No result',
                  style: GoogleFonts.outfit(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Share.share(_results[fileName] ?? '');
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Result'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Batch Studio',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildActionSelector(),
                const SizedBox(height: 20),
                if (_files.isEmpty) _buildEmptyState() else _buildFileList(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _files.isNotEmpty ? _buildBottomBar() : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: DesignSystem.softWhite,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.copy_all_rounded,
              size: 60,
              color: DesignSystem.primaryPurple.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Batch Processing',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DesignSystem.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Select multiple images to process them all at once.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.add_photo_alternate_rounded),
            label: const Text('Select Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildOption('OCR', 'Scan Text'),
          _buildOption('Invoice', 'Invoices'),
          _buildOption('Objects', 'AI Vision'),
        ],
      ),
    );
  }

  Widget _buildOption(String id, String label) {
    final isSelected = _selectedAction == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedAction = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? DesignSystem.primaryPurple
                    : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileList() {
    return Expanded(
      child: ListView.separated(
        itemCount: _files.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final file = _files[index];
          final isProcessing = _processing[file.name] ?? false;
          final isCompleted = _completed[file.name] ?? false;

          return FadeInUp(
            delay: Duration(milliseconds: index * 100),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: DesignSystem.softWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: file.path != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(file.path!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCompleted)
                          Text(
                            'Completed',
                            style: GoogleFonts.outfit(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          )
                        else if (isProcessing)
                          Text(
                            'Processing...',
                            style: GoogleFonts.outfit(
                              color: DesignSystem.primaryPurple,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    IconButton(
                      icon: const Icon(
                        Icons.visibility_rounded,
                        color: DesignSystem.primaryPurple,
                      ),
                      onPressed: () => _showResult(file.name),
                    )
                  else if (isProcessing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _files.removeAt(index);
                          _results.remove(file.name);
                        });
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    final isProcessing = _processing.containsValue(true);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isProcessing ? null : _processAll,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignSystem.primaryPurple,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: isProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Process ${_files.length} Files',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
