import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/glass_card.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _apiService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  String _selectedType = 'all';
  final List<String> _types = ['all', 'ocr', 'math', 'pdf', 'sketch', 'guide'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: const BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'History',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? DesignSystem.primaryGradient : null,
                  color: isSelected ? null : DesignSystem.surfaceColor(context),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: DesignSystem.primaryPurple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  type.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: isSelected
                        ? Colors.white
                        : DesignSystem.textColor(context),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList() {
    final filteredHistory = _selectedType == 'all'
        ? _history
        : _history.where((item) {
            final type = item['taskType'] ?? 'unknown';
            return type.toString().toLowerCase().contains(_selectedType);
          }).toList();

    if (filteredHistory.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        return _buildHistoryItem(filteredHistory[index], index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'No history found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your activities will appear here',
            style: GoogleFonts.outfit(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  void _showHistoryDetail(dynamic item) {
    final type = item['taskType'] ?? 'Unknown';
    final input = item['inputData'] ?? item['input'] ?? '';
    final result = item['result'] ?? item['output'] ?? '';
    final timestamp = item['timestamp'] != null
        ? DateTime.parse(item['timestamp'])
        : DateTime.now();
    final formattedDate = DateFormat(
      'MMMM dd, yyyy • hh:mm a',
    ).format(timestamp);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: DesignSystem.surfaceColor(context),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DesignSystem.primaryPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: DesignSystem.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.toString().toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: GoogleFonts.outfit(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (input.isNotEmpty) ...[
                      _buildDetailSection('INPUT DATA', input),
                      const SizedBox(height: 24),
                    ],
                    _buildDetailSection(
                      'ANALYSIS RESULT',
                      result,
                      isMarkdown: true,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (result.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: result));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Text'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignSystem.surfaceColor(context),
                        foregroundColor: DesignSystem.textColor(context),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: DesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (result.isNotEmpty) {
                          // Provide immediate feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening share menu...'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          try {
                            await Share.share(
                              'Scan Result from IntelliScan ($type):\n\n$result',
                              subject: 'IntelliScan Result - $type',
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error sharing: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    String content, {
    bool isMarkdown = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: DesignSystem.primaryPurple,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DesignSystem.surfaceColor(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: isMarkdown
              ? MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.outfit(
                      fontSize: 15,
                      color: DesignSystem.textColor(context),
                      height: 1.5,
                    ),
                  ),
                )
              : Text(
                  content,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: DesignSystem.textColor(context),
                    height: 1.5,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(dynamic item, int index) {
    final type = item['taskType'] ?? 'Unknown';
    final timestamp = item['timestamp'] != null
        ? DateTime.parse(item['timestamp'])
        : DateTime.now();
    final formattedDate = DateFormat('MMM dd • hh:mm a').format(timestamp);

    IconData icon;
    Color iconColor;
    switch (type.toLowerCase()) {
      case 'ocr':
        icon = Icons.document_scanner_rounded;
        iconColor = Colors.blue;
        break;
      case 'math':
        icon = Icons.calculate_rounded;
        iconColor = Colors.orange;
        break;
      case 'pdf':
      case 'pdf_merge':
      case 'pdf_split':
      case 'pdf_compress':
        icon = Icons.picture_as_pdf_rounded;
        iconColor = Colors.red;
        break;
      case 'sketch':
        icon = Icons.draw_rounded;
        iconColor = Colors.teal;
        break;
      case 'guide':
        icon = Icons.auto_awesome_rounded;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.history_rounded;
        iconColor = Colors.grey;
    }

    return FadeInUp(
      delay: Duration(milliseconds: 100 * (index % 5)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          borderRadius: 20,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            title: Text(
              type.toUpperCase(),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              formattedDate,
              style: GoogleFonts.outfit(
                color: DesignSystem.secondaryText(context),
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
            ),
            onTap: () => _showHistoryDetail(item),
          ),
        ),
      ),
    );
  }
}
