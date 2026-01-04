import '../../../core/config/api_config.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class PDFMergerScreen extends StatefulWidget {
  const PDFMergerScreen({super.key});

  @override
  State<PDFMergerScreen> createState() => _PDFMergerScreenState();
}

class _PDFMergerScreenState extends State<PDFMergerScreen> {
  final List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking files: $e', isError: true);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _mergePDFs() async {
    if (_selectedFiles.length < 2) {
      _showSnackBar(
        'Please select at least 2 PDF files to merge.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.pdfMergeEndpoint),
      );

      for (var file in _selectedFiles) {
        if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath('files', file.path!),
          );
        }
      }

      // Add userId if available (mocked for now, or retrieve from context/auth)
      // request.fields['userId'] = 'user_123';

      var response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/merged_document.pdf');
        await file.writeAsBytes(bytes);

        setState(() => _isLoading = false);
        _showSuccessDialog(file);
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Failed to merge PDFs. Status: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error merging PDFs: $e', isError: true);
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
          'Your PDFs have been merged successfully.',
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
              ], text: 'Here is my merged PDF!');
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
          'Merge PDFs',
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
      body: Padding(
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
                      Icons.merge_type_rounded,
                      size: 48,
                      color: DesignSystem.primaryPurple,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Combine multiple PDF files into one single document.',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Files (${_selectedFiles.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DesignSystem.textColor(context),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Add Files'),
                  style: TextButton.styleFrom(
                    foregroundColor: DesignSystem.primaryPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _selectedFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 64,
                            color: DesignSystem.secondaryText(
                              context,
                            ).withOpacity(0.3),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No files selected',
                            style: GoogleFonts.outfit(
                              color: DesignSystem.secondaryText(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          delay: Duration(milliseconds: index * 100),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            color: DesignSystem.surfaceColor(context),
                            child: ListTile(
                              leading: const Icon(
                                Icons.picture_as_pdf_rounded,
                                color: Colors.redAccent,
                              ),
                              title: Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w500,
                                  color: DesignSystem.textColor(context),
                                ),
                              ),
                              subtitle: Text(
                                '${(file.size / 1024).toStringAsFixed(1)} KB',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: DesignSystem.secondaryText(context),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _removeFile(index),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _mergePDFs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Merge Files',
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
