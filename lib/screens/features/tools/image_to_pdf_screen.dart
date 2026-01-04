import '../../../core/config/api_config.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class ImageToPDFScreen extends StatefulWidget {
  const ImageToPDFScreen({super.key});

  @override
  State<ImageToPDFScreen> createState() => _ImageToPDFScreenState();
}

class _ImageToPDFScreenState extends State<ImageToPDFScreen> {
  final List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
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

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _selectedFiles.removeAt(index);
        _selectedFiles.insert(index - 1, item);
      });
    }
  }

  void _moveDown(int index) {
    if (index < _selectedFiles.length - 1) {
      setState(() {
        final item = _selectedFiles.removeAt(index);
        _selectedFiles.insert(index + 1, item);
      });
    }
  }

  Future<void> _convertToPDF() async {
    if (_selectedFiles.isEmpty) {
      _showSnackBar('Please select at least one image.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.pdfImageToPdfEndpoint),
      );

      for (var file in _selectedFiles) {
        if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath('files', file.path!),
          );
        }
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/images_converted.pdf');
        await file.writeAsBytes(bytes);

        setState(() => _isLoading = false);
        _showSuccessDialog(file);
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Failed to convert images. Status: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error converting images: $e', isError: true);
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
          'Your images have been converted to PDF.',
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
              ], text: 'Here is my new PDF!');
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
          'Image to PDF',
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
                      Icons.image_rounded,
                      size: 48,
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Convert ID cards, receipts, or photos into a PDF.',
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
                  'Images (${_selectedFiles.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DesignSystem.textColor(context),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: const Text('Add Images'),
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
                            Icons.photo_library_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No images selected',
                            style: GoogleFonts.outfit(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: _selectedFiles.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = _selectedFiles.removeAt(oldIndex);
                          _selectedFiles.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return Card(
                          key: ValueKey(file.path),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          color: DesignSystem.surfaceColor(
                            context,
                          ), // Added this line
                          child: ListTile(
                            leading: file.path != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(file.path!),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.image,
                                    color: DesignSystem.secondaryText(context),
                                  ), // Changed this line
                            title: Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w500,
                                color: DesignSystem.textColor(context),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  onPressed: index > 0
                                      ? () => _moveUp(index)
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  onPressed: index < _selectedFiles.length - 1
                                      ? () => _moveDown(index)
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _removeFile(index),
                                ),
                              ],
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
                onPressed: _isLoading || _selectedFiles.isEmpty
                    ? null
                    : _convertToPDF,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Convert to PDF',
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
