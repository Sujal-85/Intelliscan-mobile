import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/design_system.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class MyFilesScreen extends StatefulWidget {
  const MyFilesScreen({super.key});

  @override
  State<MyFilesScreen> createState() => _MyFilesScreenState();
}

class _MyFilesScreenState extends State<MyFilesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _apiService.getHistory();
      if (mounted) {
        setState(() {
          _tasks = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: DesignSystem.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'My Files',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                ? _buildEmptyState()
                : FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return _buildFileCard(task);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 60,
            color: DesignSystem.secondaryText(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No files found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: DesignSystem.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(dynamic task) {
    final type = task['taskType'] ?? 'Unknown';
    final date = task['timestamp'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(task['timestamp']))
        : 'Unknown Date';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getColorForType(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getIconForType(type), color: _getColorForType(type)),
        ),
        title: Text(
          type.toString().toUpperCase(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: DesignSystem.textColor(context),
          ),
        ),
        subtitle: Text(
          date,
          style: GoogleFonts.outfit(
            color: DesignSystem.secondaryText(context),
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: DesignSystem.secondaryText(context),
          ),
          onPressed: () {}, // TODO: Show actions
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    if (type.toLowerCase().contains('ocr')) return DesignSystem.primaryPurple;
    if (type.toLowerCase().contains('pdf')) return Colors.redAccent;
    if (type.toLowerCase().contains('math')) return DesignSystem.primaryOrange;
    return Colors.blueAccent;
  }

  IconData _getIconForType(String type) {
    if (type.toLowerCase().contains('ocr')) {
      return Icons.document_scanner_rounded;
    }
    if (type.toLowerCase().contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (type.toLowerCase().contains('math')) return Icons.calculate_rounded;
    return Icons.insert_drive_file_rounded;
  }
}
