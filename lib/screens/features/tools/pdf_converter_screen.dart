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

class PDFConverterScreen extends StatefulWidget {
  const PDFConverterScreen({super.key});

  @override
  State<PDFConverterScreen> createState() => _PDFConverterScreenState();
}

class _PDFConverterScreenState extends State<PDFConverterScreen> {
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  String _selectedFormat = 'pdfword'; // Default: PDF to Word

  final Map<String, String> _conversionOptions = {
    'pdfword': 'PDF to Word',
    'pdfexcel': 'PDF to Excel',
    'pdfpowerpoint': 'PDF to PowerPoint',
    'pdfjpg': 'PDF to JPG',
    'wordpdf': 'Word to PDF',
    'excelpdf': 'Excel to PDF',
    'powerpointpdf': 'PowerPoint to PDF',
    'jpgpdf': 'JPG to PDF',
  };

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType
            .any, // Allow all for now, validated by backend or user choice
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _convertFile() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select a file to convert.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.pdfConvertEndpoint),
      );

      if (_selectedFile!.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('files', _selectedFile!.path!),
        );
      }
      request.fields['task'] = _selectedFormat;

      var response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final dir = await getTemporaryDirectory();

        // Determine extension
        String ext = 'docx';
        if (_selectedFormat.contains('excel')) ext = 'xlsx';
        if (_selectedFormat.contains('powerpoint')) ext = 'pptx';
        if (_selectedFormat.contains('jpg')) {
          ext = 'zip'; // Usually returns a zip of images or single image
        }
        if (_selectedFormat.endsWith('pdf')) ext = 'pdf';

        final file = File('${dir.path}/converted_document.$ext');
        await file.writeAsBytes(bytes);

        setState(() => _isLoading = false);
        _showSuccessDialog(file);
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Failed to convert file. Status: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error converting file: $e', isError: true);
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
          'Your file has been converted successfully.',
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
              ], text: 'Here is my converted file!');
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
          'Convert File',
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
                      Icons.transform_rounded,
                      size: 48,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Convert files between PDF and other formats (Word, Excel, JPG).',
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

            DropdownButtonFormField<String>(
              initialValue: _selectedFormat,
              decoration: InputDecoration(
                labelText: 'Conversion Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: DesignSystem.surfaceColor(context),
              ),
              items: _conversionOptions.entries
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
                if (value != null) setState(() => _selectedFormat = value);
              },
            ),

            const SizedBox(height: 20),

            if (_selectedFile == null)
              GestureDetector(
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
                        Icons.upload_file_rounded,
                        size: 50,
                        color: DesignSystem.primaryPurple.withOpacity(0.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Select File',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: DesignSystem.textColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              FadeInUp(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignSystem.surfaceColor(context),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: DesignSystem.softShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file_rounded,
                        size: 40,
                        color: Colors.blueAccent,
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

            const Spacer(),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _selectedFile == null
                    ? null
                    : _convertFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Convert File',
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
