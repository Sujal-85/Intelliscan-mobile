import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../widgets/glass_card.dart';

class SignatureExtractionScreen extends StatefulWidget {
  const SignatureExtractionScreen({super.key});

  @override
  _SignatureExtractionScreenState createState() =>
      _SignatureExtractionScreenState();
}

class _SignatureExtractionScreenState extends State<SignatureExtractionScreen> {
  File? _selectedFile;
  File? _resultFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _resultFile = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  Future<void> _extractSignature() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.signatureExtractionEndpoint),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        var bytes = await response.stream.toBytes();
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(bytes);

        setState(() {
          _resultFile = file;
        });
        _showSuccessDialog(file);
      } else {
        _showSnackBar(
          'Failed to extract: ${response.statusCode}',
          isError: true,
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

  void _showSuccessDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Success!',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Signature extracted successfully!',
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
              ], text: 'Here is my extracted signature!');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.softWhite,
      appBar: AppBar(
        title: Text(
          'Signature Extractor',
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
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            FadeInDown(
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.draw_rounded,
                        size: 48,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Upload a document containing a signature. We will extract it with a transparent background.',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: DesignSystem.charcoal,
                        ),
                        textAlign: TextAlign.center,
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
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
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
                              color: DesignSystem.primaryPurple.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Select Document',
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: DesignSystem.softShadow,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.image_rounded,
                                size: 40,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _selectedFile!.path.split('/').last,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => _selectedFile = null),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedFile!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            if (_selectedFile != null) ...[
              const SizedBox(height: 30),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _extractSignature,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.primaryBlue,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Extract Signature',
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

            if (_resultFile != null) ...[
              const SizedBox(height: 30),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    Text(
                      'Extracted Signature:',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/images/transparent_bg.png',
                          ), // Placeholder or checkerboard
                          repeat: ImageRepeat.repeat,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Image.file(_resultFile!, height: 100),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
