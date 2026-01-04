import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../core/theme/design_system.dart';
import '../screens/features/ocr_screen.dart';
import '../screens/features/math_solver_screen.dart';
import '../screens/features/sketch_svg_screen.dart';
import '../screens/features/pdf_tools_screen.dart';
import '../screens/features/batch_processing_screen.dart';
import '../screens/features/object_recognition_screen.dart';
import '../screens/features/document_summarizer_screen.dart';
import '../screens/features/smart_invoice_screen.dart';

class QuickActionPopup extends StatelessWidget {
  const QuickActionPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.charcoal,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What would you like to do?',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildActionItem(
                    context,
                    'Batch Studio',
                    'Process multiple files at once',
                    Icons.copy_all_rounded,
                    Colors.indigoAccent,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BatchProcessingScreen(),
                      ),
                    ),
                    0,
                  ),
                  const SizedBox(height: 12),
                  _buildActionItem(
                    context,
                    'AI Vision',
                    'Identify objects in photos',
                    Icons.visibility_rounded,
                    Colors.teal,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ObjectRecognitionScreen(),
                      ),
                    ),
                    1,
                  ),
                  const SizedBox(height: 12),
                  _buildActionItem(
                    context,
                    'Smart Summarizer',
                    'Condense long documents',
                    Icons.summarize_rounded,
                    Colors.deepOrangeAccent,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DocumentSummarizerScreen(),
                      ),
                    ),
                    2,
                  ),
                  const SizedBox(height: 12),
                  _buildActionItem(
                    context,
                    'Financial Scanner',
                    'Extract receipt/invoice data',
                    Icons.receipt_long_rounded,
                    Colors.green,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SmartInvoiceScreen(),
                      ),
                    ),
                    3,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildActionItem(
                    context,
                    'Scan Document',
                    'Extract text from images',
                    Icons.document_scanner_rounded,
                    DesignSystem.primaryPurple,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const OCRScreen()),
                    ),
                    4,
                  ),
                  const SizedBox(height: 12),
                  _buildActionItem(
                    context,
                    'Solve Math',
                    'Get step-by-step solutions',
                    Icons.calculate_rounded,
                    DesignSystem.primaryOrange,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MathSolverScreen(),
                      ),
                    ),
                    5,
                  ),
                  const SizedBox(height: 12),
                  _buildActionItem(
                    context,
                    'Sketch to SVG',
                    'Convert drawings to vector',
                    Icons.draw_rounded,
                    Colors.blueAccent,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SketchSvgScreen(),
                      ),
                    ),
                    6,
                  ),
                  const SizedBox(height: 12),
                  _buildActionItem(
                    context,
                    'PDF Tools',
                    'Merge, split, and convert',
                    Icons.picture_as_pdf_rounded,
                    Colors.redAccent,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PDFToolsScreen()),
                    ),
                    7,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    int index,
  ) {
    return FadeInRight(
      delay: Duration(milliseconds: 100 * index + 100),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DesignSystem.charcoal,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: color.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
