import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class InvoiceExtractionScreen extends StatefulWidget {
  const InvoiceExtractionScreen({super.key});

  @override
  _InvoiceExtractionScreenState createState() =>
      _InvoiceExtractionScreenState();
}

class _InvoiceExtractionScreenState extends State<InvoiceExtractionScreen> {
  File? _selectedFile;
  bool _isLoading = false;
  Map<String, dynamic>? _extractedData;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _extractedData = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  Future<void> _extractInvoiceData() async {
    if (_selectedFile == null) {
      _showSnackBar('Please select an invoice image.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.invoiceExtractionEndpoint),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        setState(() {
          _extractedData = data['extracted_data'];
        });
      } else {
        throw Exception(
          'Failed to extract invoice data: ${response.reasonPhrase}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Invoice Scanner',
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
                        Icons.receipt_long_rounded,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Automatically extract vendor, date, total, and tax info from invoice images.',
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
                          Icons.camera_alt_rounded,
                          size: 50,
                          color: Colors.green.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scan Invoice Image',
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
                      label: const Text('Retake Photo'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
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
                      : _extractInvoiceData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.green.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Extract Data',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            if (_extractedData != null) ...[
              const SizedBox(height: 30),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extracted Details',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.textColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Vendor',
                              _extractedData!['vendor_name'],
                              Icons.store_rounded,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Invoice #',
                              _extractedData!['invoice_number'],
                              Icons.tag_rounded,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Date',
                              _extractedData!['date'],
                              Icons.calendar_today_rounded,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Due Date',
                              _extractedData!['due_date'],
                              Icons.event_rounded,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Total Amount',
                              _extractedData!['total'] != null
                                  ? '\$${_extractedData!['total']}'
                                  : 'N/A',
                              Icons.attach_money_rounded,
                              isHighlight: true,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Tax',
                              _extractedData!['tax'] != null
                                  ? '\$${_extractedData!['tax']}'
                                  : 'N/A',
                              Icons.percent_rounded,
                            ),
                          ],
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

  Widget _buildDetailRow(
    String label,
    dynamic value,
    IconData icon, {
    bool isHighlight = false,
  }) {
    final displayValue = (value == null || value.toString().isEmpty)
        ? 'Not detected'
        : value.toString();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHighlight
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isHighlight
                ? Colors.green
                : DesignSystem.secondaryText(context),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: DesignSystem.secondaryText(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayValue,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isHighlight
                      ? Colors.green[800]
                      : DesignSystem.textColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
