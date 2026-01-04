import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/design_system.dart';
import '../../services/api_service.dart';

class ObjectRecognitionScreen extends StatefulWidget {
  const ObjectRecognitionScreen({super.key});

  @override
  State<ObjectRecognitionScreen> createState() =>
      _ObjectRecognitionScreenState();
}

class _ObjectRecognitionScreenState extends State<ObjectRecognitionScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
      });
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await _apiService.recognizeObjects(_image!);
      setState(() {
        _result = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error analyzing image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'AI Vision',
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
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(
                Icons.share_rounded,
                color: DesignSystem.charcoal,
              ),
              onPressed: () {
                Share.share(
                  'I found these objects: ${_result!['objects'].toString()}',
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: DesignSystem.softWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to Add Image',
                            style: GoogleFonts.outfit(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_image!, fit: BoxFit.cover),
                            if (_isAnalyzing)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_isAnalyzing && _result != null) ...[
              Text(
                'Detected Objects',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DesignSystem.charcoal,
                ),
              ),
              const SizedBox(height: 16),
              _buildResultsList(),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickImage(ImageSource.camera),
        label: const Text('Camera'),
        icon: const Icon(Icons.camera_alt_rounded),
        backgroundColor: DesignSystem.primaryPurple,
      ),
    );
  }

  Widget _buildResultsList() {
    final objects = _result!['objects'] as List<dynamic>?;
    if (objects == null || objects.isEmpty) {
      return Center(
        child: Text(
          'No objects detected.',
          style: GoogleFonts.outfit(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: objects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final obj = objects[index];
        final name = obj['label'] ?? obj['name'] ?? 'Unknown';
        final confidence = ((obj['confidence'] ?? 0) * 100).toStringAsFixed(1);

        return FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$confidence%',
                    style: GoogleFonts.outfit(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
