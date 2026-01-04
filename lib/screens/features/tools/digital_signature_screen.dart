import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import '../../../core/theme/design_system.dart';

class DigitalSignatureScreen extends StatefulWidget {
  const DigitalSignatureScreen({super.key});

  @override
  State<DigitalSignatureScreen> createState() => _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState extends State<DigitalSignatureScreen> {
  final GlobalKey _globalKey = GlobalKey();
  final List<Offset?> _points = [];

  void _clearSignature() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _saveSignature() async {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign first')));
      return;
    }

    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      Share.shareXFiles([XFile(file.path)], text: 'My Digital Signature');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving signature: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Digital Signature',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _clearSignature,
            tooltip: 'Clear',
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            onPressed: _saveSignature,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Sign below',
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: DesignSystem.secondaryText(context),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors
                      .white, // Signature canvas needs to be white for contrast
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: DesignSystem.softShadow,
                  border: Border.all(color: DesignSystem.dividerColor(context)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: RepaintBoundary(
                    key: _globalKey,
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _points.add(details.localPosition);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _points.add(details.localPosition);
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _points.add(null);
                        });
                      },
                      child: CustomPaint(
                        painter: SignaturePainter(points: _points),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Draw your signature on the screen.',
              style: GoogleFonts.outfit(
                color: DesignSystem.secondaryText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  List<Offset?> points;

  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
