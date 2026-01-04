import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/ai_service.dart';
import 'dart:io';

class MathSolverScreen extends StatefulWidget {
  const MathSolverScreen({super.key});

  @override
  State<MathSolverScreen> createState() => _MathSolverScreenState();
}

class _MathSolverScreenState extends State<MathSolverScreen> {
  bool _isAnalyzing = false;
  String? _latexResult;
  List<String> _steps = [];
  File? _imageFile;
  final ApiService _apiService = ApiService();
  final AiService _aiService = AiService();
  final ImagePicker _picker = ImagePicker();

  bool _isExplaining = false;
  String? _explanation;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _latexResult = null;
        _steps = [];
      });
    }
  }

  void _analyzeMath() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image first')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _latexResult = null;
      _steps = [];
    });

    final result = await _apiService.solveMath(_imageFile!);

    setState(() {
      _isAnalyzing = false;
      if (result != null) {
        _latexResult = result['latex'];

        // Split the solution into steps if it contains numbered steps or bullet points
        final rawSolution = result['solution'] ?? "";
        if (rawSolution.contains(RegExp(r'\d+\.'))) {
          _steps = rawSolution
              .split(RegExp(r'(?=\d+\.)'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        } else {
          _steps = [rawSolution];
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to solve math problem. Please try again.'),
          ),
        );
      }
    });
  }

  Future<void> _explainWithAI() async {
    if (_steps.isEmpty && _latexResult == null) return;
    setState(() => _isExplaining = true);

    String prompt =
        "Please explain this math solution step-by-step in simple terms:\n\n";
    if (_latexResult != null) prompt += "Problem: $_latexResult\n\n";
    if (_steps.isNotEmpty) prompt += "Steps:\n${_steps.join('\n')}";

    final result = await _aiService.askGuide([
      ChatMessage(role: 'user', content: prompt),
    ]);

    setState(() {
      _isExplaining = false;
      _explanation = result;
    });
  }

  Future<void> _downloadSolution() async {
    if (_latexResult == null && _steps.isEmpty) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/math_solution_${DateTime.now().millisecondsSinceEpoch}.txt',
      );

      String content = "Math Solution\n\n";
      if (_latexResult != null) content += "Equation: $_latexResult\n\n";
      content += "Steps:\n${_steps.join('\n')}";
      if (_explanation != null) content += "\n\nAI Explanation:\n$_explanation";

      await file.writeAsString(content);

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
          _buildScientificBackground(),
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
                      _buildUploadSection(),
                      const SizedBox(height: 48),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: CustomGradientButton(
                          text: _isAnalyzing
                              ? 'Solving Equation...'
                              : 'Solve Intelligence',
                          isLoading: _isAnalyzing,
                          onPressed: _analyzeMath,
                          icon: Icons.auto_graph_rounded,
                        ),
                      ),
                      if (_latexResult != null) ...[
                        const SizedBox(height: 48),
                        _buildGraphPlotter(),
                        const SizedBox(height: 40),

                        // Smart Actions
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isExplaining ? null : _explainWithAI,
                                  child: GlassCard(
                                    borderRadius: 16,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Column(
                                        children: [
                                          if (_isExplaining)
                                            const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          else
                                            const Icon(
                                              Icons.psychology_rounded,
                                              color: DesignSystem.primaryOrange,
                                            ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Explain with AI',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: DesignSystem.textColor(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_explanation != null) ...[
                          const SizedBox(height: 32),
                          FadeInUp(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI TUTOR',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: DesignSystem.primaryOrange,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GlassCard(
                                  borderRadius: 20,
                                  color: Colors.orange[50]?.withOpacity(0.1),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      _explanation!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: DesignSystem.textColor(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
                        _buildStepByStepSection(),
                        const SizedBox(height: 32),
                        _buildResultSection(),
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
                  'MATHEMATICS',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Solver Intelligence',
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
            child: const Icon(Icons.functions_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildScientificBackground() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.03,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final mathIcons = [
              Icons.functions,
              Icons.architecture,
              Icons.calculate,
              Icons.edit_note,
              Icons.percent,
              Icons.timeline,
            ];
            return Container(
              padding: const EdgeInsets.all(40),
              child: Icon(
                mathIcons[index % mathIcons.length],
                size: 80,
                color: DesignSystem.primaryPurple,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return FadeInDown(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: double.infinity,
          height: 200,
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
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: DesignSystem.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Capture Equation',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: DesignSystem.textColor(context),
                      ),
                    ),
                    Text(
                      'Supports integrals, fractions & algebra',
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

  Widget _buildGraphPlotter() {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VISUALIZATION',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: DesignSystem.primaryPurple,
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            borderRadius: 24,
            child: Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(24),
              child: CustomPaint(painter: _GraphPainter(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepByStepSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP-BY-STEP SOLUTION',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: DesignSystem.primaryPurple,
            ),
          ),
          const SizedBox(height: 16),
          ..._steps.map((step) => _buildStepTile(step)),
        ],
      ),
    );
  }

  Widget _buildStepTile(String step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        borderRadius: 20,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignSystem.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: DesignSystem.primaryPurple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  step,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    height: 1.5,
                    color: DesignSystem.textColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MATH METADATA',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: DesignSystem.primaryPurple,
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            borderRadius: 24,
            color: DesignSystem.surfaceColor(context),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raw LaTeX Representative:',
                    style: TextStyle(
                      color: DesignSystem.secondaryText(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignSystem.primaryPurple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      _latexResult!,
                      style: GoogleFonts.firaCode(
                        fontSize: 13,
                        color: DesignSystem.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (_latexResult != null) {
                      Clipboard.setData(ClipboardData(text: _latexResult!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('LaTeX copied!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadSolution,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (_latexResult != null && _latexResult!.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening share menu...'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      try {
                        await Share.share(
                          'Math Solution from IntelliScan:\n\n$_latexResult',
                          subject: 'IntelliScan Math Result',
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

class _GraphPainter extends CustomPainter {
  final BuildContext context;
  _GraphPainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignSystem.primaryPurple.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid
    for (int i = 0; i <= 10; i++) {
      double x = size.width * (i / 10);
      double y = size.height * (i / 10);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final axisPaint = Paint()
      ..color = DesignSystem.primaryPurple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw axes
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      axisPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      axisPaint,
    );

    final linePaint = Paint()
      ..color = DesignSystem.primaryPurple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.2,
      size.width,
      size.height * 0.5,
    );

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
