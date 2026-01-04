import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../widgets/glass_card.dart';
import '../../../../core/config/api_config.dart';

class SmartRedactionScreen extends StatefulWidget {
  const SmartRedactionScreen({super.key});

  @override
  _SmartRedactionScreenState createState() => _SmartRedactionScreenState();
}

class _SmartRedactionScreenState extends State<SmartRedactionScreen> {
  static const String _apiBaseUrl = '${ApiConfig.baseUrl}/api/advanced';
  File? _selectedFile;
  File? _resultFile;
  bool _isLoading = false;

  // Options
  bool _redactEmail = true;
  bool _redactPhone = true;
  bool _redactCreditCard = true;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _resultFile = null;
      });
    }
  }

  Future<void> _processRedaction() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/smart-redaction'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      List<String> types = [];
      if (_redactEmail) types.add('email');
      if (_redactPhone) types.add('phone');
      if (_redactCreditCard) types.add('credit_card');

      request.fields['redact_types'] = types.join(',');

      var response = await request.send();

      if (response.statusCode == 200) {
        var bytes = await response.stream.toBytes();
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/redacted_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(bytes);

        setState(() {
          _resultFile = file;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to redact: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.softWhite,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select items to redact:',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: DesignSystem.charcoal,
                            ),
                          ),
                          CheckboxListTile(
                            title: Text(
                              'Email Addresses',
                              style: GoogleFonts.outfit(),
                            ),
                            value: _redactEmail,
                            onChanged: (v) => setState(() => _redactEmail = v!),
                          ),
                          CheckboxListTile(
                            title: Text(
                              'Phone Numbers',
                              style: GoogleFonts.outfit(),
                            ),
                            value: _redactPhone,
                            onChanged: (v) => setState(() => _redactPhone = v!),
                          ),
                          CheckboxListTile(
                            title: Text(
                              'Credit Cards',
                              style: GoogleFonts.outfit(),
                            ),
                            value: _redactCreditCard,
                            onChanged: (v) =>
                                setState(() => _redactCreditCard = v!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignSystem.primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Original:',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedFile!,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _processRedaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignSystem.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Redact PII'),
                    ),
                  ],
                  if (_resultFile != null) ...[
                    const SizedBox(height: 30),
                    Text(
                      'Redacted Result:',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _resultFile!,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Text(
            'Smart Redaction',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
