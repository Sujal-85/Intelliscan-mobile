import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path; // Added for basename
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class ImageEnhancementScreen extends StatefulWidget {
  const ImageEnhancementScreen({super.key});

  @override
  _ImageEnhancementScreenState createState() => _ImageEnhancementScreenState();
}

class _ImageEnhancementScreenState extends State<ImageEnhancementScreen> {
  File? _selectedFile;
  bool _isLoading = false;
  File? _enhancedImageFile;
  String _enhancementType = 'default';

  final Map<String, String> _enhancementOptions = {
    'default': 'Default (Contrast + Sharpness)',
    'sharpness': 'Sharpness',
    'contrast': 'Contrast',
    'brightness': 'Brightness',
    'noise_reduction': 'Noise Reduction',
    'binarization': 'Binarization',
    'deskew': 'Deskew',
    'auto_enhance': 'Auto Enhance',
  };

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _enhancedImageFile = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  Future<void> _enhanceImage() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.enhanceImageEndpoint),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      request.fields['enhancement_type'] = _enhancementType;

      var response = await request.send();

      if (response.statusCode == 200) {
        // Save the enhanced image to a temporary file
        var bytes = await response.stream.toBytes();
        String tempPath =
            '${Directory.systemTemp.path}/enhanced_${path.basename(_selectedFile!.path)}';
        File tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes);

        setState(() {
          _enhancedImageFile = tempFile;
        });
        _showSnackBar('Image enhanced successfully!');
      } else {
        throw Exception('Failed to enhance image: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveImage() async {
    if (_enhancedImageFile == null) return;
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        fileName: 'enhanced_${path.basename(_selectedFile!.path)}',
      );

      if (outputPath != null) {
        await File(
          outputPath,
        ).writeAsBytes(await _enhancedImageFile!.readAsBytes());
        _showSnackBar('Image saved to $outputPath');
      }
    } catch (e) {
      _showSnackBar('Error saving file: $e', isError: true);
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
          'Image Enhancement',
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
                        Icons.auto_fix_high_rounded,
                        size: 48,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Improve image quality, remove noise, and correct perspective automatically.',
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
              child: DropdownButtonFormField<String>(
                initialValue: _enhancementType,
                decoration: InputDecoration(
                  labelText: 'Enhancement Type',
                  labelStyle: GoogleFonts.outfit(
                    color: DesignSystem.secondaryText(context),
                  ),
                  filled: true,
                  fillColor: DesignSystem.surfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.tune_rounded),
                ),
                items: _enhancementOptions.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: DesignSystem.textColor(context),
                          ),
                          overflow: TextOverflow.ellipsis,
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
            ),
            const SizedBox(height: 24),
            if (_selectedFile == null)
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    height: 200,
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
                          Icons.add_photo_alternate_rounded,
                          size: 60,
                          color: Colors.purple.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select Image to Enhance',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: DesignSystem.secondaryText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.secondaryText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: FileImage(_selectedFile!),
                          fit: BoxFit.contain,
                        ),
                        color: Colors.black12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Change Image'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedFile == null
                      ? null
                      : _enhanceImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.purple.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Enhance Image',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            if (_enhancedImageFile != null) ...[
              const SizedBox(height: 30),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Enhanced Result',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.5),
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: FileImage(_enhancedImageFile!),
                          fit: BoxFit.contain,
                        ),
                        color: Colors.black12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _saveImage,
                        icon: const Icon(Icons.save_alt_rounded),
                        label: Text(
                          'Save Enhanced Image',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
