import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../core/theme/design_system.dart';
import '../../services/api_service.dart';

class SmartInvoiceScreen extends StatefulWidget {
  const SmartInvoiceScreen({super.key});

  @override
  State<SmartInvoiceScreen> createState() => _SmartInvoiceScreenState();
}

class _SmartInvoiceScreenState extends State<SmartInvoiceScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _data;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _data = null;
      });
      _analyzeInvoice();
    }
  }

  Future<void> _analyzeInvoice() async {
    if (_image == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await _apiService.extractInvoiceData(_image!);
      setState(() {
        _data = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error analyzing invoice: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Financial Scanner',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                height: 250,
                width: double.infinity,
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
                            Icons.receipt_long_rounded,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Scan Receipt / Invoice',
                            style: GoogleFonts.outfit(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isAnalyzing)
              const Center(child: CircularProgressIndicator())
            else if (_data != null)
              _buildDataList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickImage(ImageSource.camera),
        label: const Text('New Scan'),
        icon: const Icon(Icons.camera_alt_rounded),
        backgroundColor: DesignSystem.primaryPurple,
      ),
    );
  }

  Widget _buildDataList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Extracted Details',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DesignSystem.charcoal,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: _data!.entries
                .map((e) => _buildRow(e.key, e.value.toString()))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    // Capitalize label
    String displayLabel = label
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            displayLabel,
            style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
          ),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: DesignSystem.charcoal,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied!'),
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                },
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
