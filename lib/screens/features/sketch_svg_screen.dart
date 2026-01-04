import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SketchSvgScreen extends StatefulWidget {
  const SketchSvgScreen({super.key});

  @override
  State<SketchSvgScreen> createState() => _SketchSvgScreenState();
}

class _SketchSvgScreenState extends State<SketchSvgScreen> {
  bool _isProcessing = false;
  String? _svgContent;
  File? _imageFile;
  List<Color> _palette = [];
  bool _showInspector = false;
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _svgContent = null;
        _palette = [
          DesignSystem.primaryPurple,
          const Color(0xFF6366F1),
          const Color(0xFF8B5CF6),
          const Color(0xFFD946EF),
        ]; // Simulated palette extraction
      });
    }
  }

  void _processSketch() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a sketch first')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final result = await _apiService.vectorizeSketch(_imageFile!);

    setState(() {
      _isProcessing = false;
      if (result != null) {
        _svgContent = result;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to vectorize sketch. Please try again.'),
          ),
        );
      }
    });
  }

  Future<void> _downloadSvg() async {
    if (_svgContent == null || _svgContent!.isEmpty) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/vector_sketch_${DateTime.now().millisecondsSinceEpoch}.svg',
      );
      await file.writeAsString(_svgContent!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      body: Stack(
        children: [
          _buildInfiniteCanvas(),
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      _buildUploadArea(),
                      const SizedBox(height: 48),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: CustomGradientButton(
                          text: _isProcessing
                              ? 'Vectorizing Sketch...'
                              : 'Convert to Vector SVG',
                          isLoading: _isProcessing,
                          onPressed: _processSketch,
                          icon: Icons.auto_awesome_motion_rounded,
                        ),
                      ),
                      if (_svgContent != null) ...[
                        const SizedBox(height: 48),
                        _buildPaletteSection(),
                        const SizedBox(height: 40),
                        _buildResultArea(),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 30),
      decoration: BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.primaryPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GRAPHICS',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Vector Engine',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.polyline_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInfiniteCanvas() {
    return Positioned.fill(
      child: CustomPaint(painter: _CanvasPainter(context)),
    );
  }

  Widget _buildUploadArea() {
    return FadeInDown(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: DesignSystem.surfaceColor(context),
            borderRadius: DesignSystem.radius24,
            image: _imageFile != null
                ? DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  )
                : null,
            border: Border.all(
              color: DesignSystem.outlineColor(context),
              width: 2,
            ),
            boxShadow: DesignSystem.softShadow,
          ),
          child: _imageFile == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DesignSystem.primaryPurple.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.draw_outlined,
                        size: 56,
                        color: DesignSystem.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Drop your Sketch',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: DesignSystem.textColor(context),
                      ),
                    ),
                    Text(
                      'AI will convert lines into vectors',
                      style: TextStyle(
                        color: DesignSystem.secondaryText(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: DesignSystem.radius24,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPaletteSection() {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SMART PALETTE',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: DesignSystem.primaryPurple,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: _palette
                .map(
                  (color) => Expanded(
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultArea() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE PREVIEW',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: DesignSystem.primaryPurple,
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showInspector = !_showInspector),
                icon: Icon(
                  _showInspector
                      ? Icons.visibility_off_rounded
                      : Icons.code_rounded,
                  size: 18,
                  color: DesignSystem.primaryPurple,
                ),
                label: Text(
                  _showInspector ? 'Hide Source' : 'View SVG Source',
                  style: GoogleFonts.outfit(
                    color: DesignSystem.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_showInspector)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: DesignSystem.radius24,
                boxShadow: DesignSystem.softShadow,
              ),
              child: SelectableText(
                _svgContent!,
                style: GoogleFonts.firaCode(
                  color: const Color(0xFFCE9178),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: DesignSystem.surfaceColor(context),
                borderRadius: DesignSystem.radius24,
                boxShadow: DesignSystem.softShadow,
                border: Border.all(color: DesignSystem.outlineColor(context)),
              ),
              child: Center(
                child: SvgPicture.string(
                  _svgContent!,
                  width: 240,
                  height: 240,
                  placeholderBuilder: (BuildContext context) => const SizedBox(
                    height: 100,
                    width: 100,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _svgContent!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('SVG Source Copied!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy Source'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadSvg,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Save SVG'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (_svgContent != null && _svgContent!.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening share menu...'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      try {
                        await Share.share(_svgContent!);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error sharing: $e')),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final BuildContext context;
  _CanvasPainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignSystem.outlineColor(context).withOpacity(0.05)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final accentPaint = Paint()
      ..color = DesignSystem.primaryPurple.withOpacity(0.05);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      100,
      accentPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      150,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
