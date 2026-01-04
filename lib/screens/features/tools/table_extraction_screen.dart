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

class TableExtractionScreen extends StatefulWidget {
  const TableExtractionScreen({super.key});

  @override
  _TableExtractionScreenState createState() => _TableExtractionScreenState();
}

class _TableExtractionScreenState extends State<TableExtractionScreen> {
  File? _selectedFile;
  bool _isLoading = false;
  List<dynamic>? _tables;
  String _format = 'csv';

  final Map<String, String> _formatOptions = {
    'csv': 'CSV',
    'excel': 'Excel (JSON)',
    'json': 'JSON',
  };

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _tables = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  Future<void> _extractTables() async {
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
        Uri.parse(ApiConfig.tableExtractionEndpoint),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      request.fields['format'] = _format;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);
        setState(() {
          _tables = data['tables'];
        });
      } else {
        throw Exception('Failed to extract tables: ${response.reasonPhrase}');
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
          'Table Extractor',
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
                        Icons.table_chart_rounded,
                        size: 48,
                        color: Colors.indigoAccent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Digitize tables from images and export them as CSV, Excel, or JSON.',
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
                initialValue: _format,
                decoration: InputDecoration(
                  labelText: 'Output Format',
                  labelStyle: GoogleFonts.outfit(
                    color: DesignSystem.secondaryText(context),
                  ),
                  filled: true,
                  fillColor: DesignSystem.surfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.output_rounded),
                ),
                items: _formatOptions.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          style: GoogleFonts.outfit(
                            color: DesignSystem.textColor(context),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _format = value!;
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
                    height: 180,
                    decoration: BoxDecoration(
                      color: DesignSystem.surfaceColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: DesignSystem.outlineColor(context),
                        width: 2,
                      ),
                      boxShadow: DesignSystem.softShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 50,
                          color: Colors.indigoAccent.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Upload Table Image',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: DesignSystem.textColor(context),
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
                        foregroundColor: Colors.indigoAccent,
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
                      : _extractTables,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.indigoAccent.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Extract Tables',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            if (_tables != null) ...[
              const SizedBox(height: 30),
              Column(
                children: List.generate(_tables!.length, (index) {
                  var table = _tables![index];
                  return FadeInUp(
                    delay: Duration(milliseconds: 400 + (index * 100)),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Table ${index + 1}: ${table['description'] ?? "Detected Table"}',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: DesignSystem.textColor(context),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (table['headers'] != null &&
                                  table['rows'] != null)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: (table['headers'] as List)
                                        .map<DataColumn>(
                                          (header) => DataColumn(
                                            label: Text(
                                              header.toString(),
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    DesignSystem.primaryPurple,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    rows: (table['rows'] as List)
                                        .map<DataRow>(
                                          (row) => DataRow(
                                            cells: (row as List)
                                                .map<DataCell>(
                                                  (cell) => DataCell(
                                                    Text(
                                                      cell.toString(),
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 14,
                                                        color:
                                                            DesignSystem.textColor(
                                                              context,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        )
                                        .toList(),
                                    border: TableBorder.all(
                                      color: DesignSystem.outlineColor(context),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                            ],
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
