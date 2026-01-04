import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class BarcodeDetectionScreen extends StatefulWidget {
  const BarcodeDetectionScreen({super.key});

  @override
  _BarcodeDetectionScreenState createState() => _BarcodeDetectionScreenState();
}

class _BarcodeDetectionScreenState extends State<BarcodeDetectionScreen> {
  File? _selectedFile;
  bool _isLoading = false;
  List<dynamic>? _barcodes;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _barcodes = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  Future<void> _detectBarcodes() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select an image first.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.barcodeDetectionEndpoint),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        setState(() {
          _barcodes = data['barcodes'];
        });
      } else {
        throw Exception('Failed to detect barcodes: ${response.reasonPhrase}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Barcode Scanner',
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
                        Icons.qr_code_scanner_rounded,
                        size: 48,
                        color: Colors.pinkAccent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Detect and decode QR codes and Barcodes from images.',
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
            const SizedBox(height: 30),
            if (_selectedFile == null)
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    height: 180,
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
                          Icons.add_a_photo_rounded,
                          size: 50,
                          color: Colors.pinkAccent.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Upload Barcode Image',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
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
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: DesignSystem.softShadow,
                        image: DecorationImage(
                          image: FileImage(_selectedFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Change Image'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.pinkAccent,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedFile == null
                      ? null
                      : _detectBarcodes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.pinkAccent.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Scan Codes',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            if (_barcodes != null) ...[
              const SizedBox(height: 30),
              Column(
                children: List.generate(_barcodes!.length, (index) {
                  var barcode = _barcodes![index];
                  return FadeInUp(
                    delay: Duration(milliseconds: 400 + (index * 100)),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassCard(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.qr_code_rounded,
                              color: Colors.pinkAccent,
                            ),
                          ),
                          title: Text(
                            barcode['type'] ?? 'Unknown Type',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: DesignSystem.textColor(context),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              barcode['data'] ?? 'No Data',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: DesignSystem.secondaryText(context),
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: barcode['data'] ?? ''),
                              );
                              _showSnackBar('Copied to clipboard');
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
