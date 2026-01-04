import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/design_system.dart';
import '../../../widgets/glass_card.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  String _selectedType = 'Link / URL';
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _qrData = '';
  final GlobalKey _qrKey = GlobalKey();

  final List<Map<String, dynamic>> _qrTypes = [
    {'label': 'Link / URL', 'icon': Icons.link},
    {'label': 'Text', 'icon': Icons.text_fields},
    {'label': 'E-mail', 'icon': Icons.email},
    {'label': 'Phone number', 'icon': Icons.phone},
    {'label': 'Wi-Fi', 'icon': Icons.wifi},
    {'label': 'Facebook', 'icon': FontAwesomeIcons.facebook},
    {'label': 'VK', 'icon': FontAwesomeIcons.vk},
    {'label': 'Telegram', 'icon': FontAwesomeIcons.telegram},
  ];

  @override
  void initState() {
    super.initState();
    _dataController.addListener(_updateQrData);
    _ssidController.addListener(_updateQrData);
    _passwordController.addListener(_updateQrData);
  }

  @override
  void dispose() {
    _dataController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateQrData() {
    setState(() {
      if (_selectedType == 'Wi-Fi') {
        _qrData =
            'WIFI:S:${_ssidController.text};T:WPA;P:${_passwordController.text};;';
      } else {
        _qrData = _dataController.text;
      }
    });
  }

  Future<void> _shareQrCode() async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/qr_code.png').create();
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Here is my QR Code!');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing QR code: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'QR Generator',
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
        padding: const EdgeInsets.all(20.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeInDown(
              child: SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _qrTypes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final type = _qrTypes[index];
                    final isSelected = _selectedType == type['label'];
                    return ChoiceChip(
                      label: Row(
                        children: [
                          Icon(
                            type['icon'],
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : DesignSystem.secondaryText(context),
                          ),
                          const SizedBox(width: 8),
                          Text(type['label']),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType = type['label'];
                            _dataController.clear();
                            _ssidController.clear();
                            _passwordController.clear();
                            _qrData = '';
                          });
                        }
                      },
                      selectedColor:
                          Colors.blueAccent, // Matches the image roughly
                      backgroundColor: DesignSystem.surfaceColor(context),
                      labelStyle: GoogleFonts.outfit(
                        color: isSelected
                            ? Colors.white
                            : DesignSystem.textColor(context),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.blueAccent
                              : DesignSystem.outlineColor(context),
                        ),
                      ),
                      elevation: isSelected ? 4 : 1,
                      shadowColor: Colors.black26,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      if (_selectedType == 'Wi-Fi') ...[
                        TextField(
                          controller: _ssidController,
                          decoration: InputDecoration(
                            labelText: 'Network Name (SSID)',
                            prefixIcon: const Icon(Icons.wifi),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: true,
                        ),
                      ] else ...[
                        TextField(
                          controller: _dataController,
                          decoration: InputDecoration(
                            labelText: 'Enter $_selectedType',
                            prefixIcon: Icon(
                              _qrTypes.firstWhere(
                                (t) => t['label'] == _selectedType,
                              )['icon'],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: _selectedType == 'Link / URL'
                                ? 'https://example.com'
                                : 'Enter value',
                          ),
                          keyboardType: _selectedType == 'Phone number'
                              ? TextInputType.phone
                              : _selectedType == 'E-mail'
                              ? TextInputType.emailAddress
                              : TextInputType.text,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_qrData.isNotEmpty)
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: DesignSystem.softShadow,
                        ),
                        child: QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _shareQrCode,
                        icon: const Icon(Icons.share_rounded),
                        label: Text(
                          'Share QR Code',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignSystem.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
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
}
