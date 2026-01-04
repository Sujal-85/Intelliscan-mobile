import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:open_file/open_file.dart';
import '../../core/theme/design_system.dart';
import '../../services/security_service.dart';
import '../../services/auth_service.dart';
import 'security_question_screen.dart';

class SecureVaultScreen extends StatefulWidget {
  const SecureVaultScreen({super.key});

  @override
  State<SecureVaultScreen> createState() => _SecureVaultScreenState();
}

class _SecureVaultScreenState extends State<SecureVaultScreen> {
  final SecurityService _securityService = SecurityService();
  final AuthService _authService = AuthService();
  List<dynamic> _files = [];
  bool _isLoading = true;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final hasPin = await _securityService.isPinSet();
    if (!hasPin) {
      if (mounted) {
        // Force Security Question Setup First
        final setupSuccess = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SecurityQuestionScreen(isSetup: true),
          ),
        );

        if (setupSuccess == true) {
          if (mounted) _showPinDialog(isSetup: true);
        } else {
          if (mounted) Navigator.pop(context); // Exit if setup cancelled
        }
      }
    } else {
      if (mounted) _showPinDialog(isSetup: false);
    }
  }

  Future<void> _forgotPin() async {
    final verified = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SecurityQuestionScreen(isSetup: false),
      ),
    );

    if (verified == true) {
      // Allow resetting PIN
      if (mounted) {
        Navigator.pop(
          context,
        ); // Close existing dialog if open (handled by return)
        _showPinDialog(isSetup: true); // Show Set PIN dialog
      }
    }
  }

  Future<void> _showPinDialog({required bool isSetup}) async {
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PinDialog(
        isSetup: isSetup,
        onForgotPin: isSetup ? null : _forgotPin,
      ),
    );

    if (pin != null) {
      if (isSetup) {
        await _securityService.setPin(pin);
        setState(() => _isUnlocked = true);
        _loadFiles();
      } else {
        final isValid = await _securityService.verifyPin(pin);
        if (isValid) {
          setState(() => _isUnlocked = true);
          _loadFiles();
        } else {
          if (mounted) Navigator.pop(context);
        }
      }
    } else {
      if (!_isUnlocked && mounted) Navigator.pop(context);
    }
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final user = _authService.currentUser;
    if (user != null) {
      final files = await _securityService.fetchVaultFiles(user.uid);
      setState(() {
        _files = files;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);

      final pin = await showDialog<String>(
        context: context,
        builder: (context) => const _PinDialog(
          isSetup: false,
          title: "Enter PIN to Encrypt & Upload",
        ),
      );

      if (pin != null) {
        setState(() => _isLoading = true);
        final user = _authService.currentUser;
        if (user != null) {
          try {
            await _securityService.uploadEncryptedFile(file, pin, user.uid);
            _loadFiles();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
            }
          }
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Secure Vault',
          style: GoogleFonts.outfit(color: DesignSystem.textColor(context)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: DesignSystem.textColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: DesignSystem.primaryPurple,
            ),
            onPressed: _importFile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: DesignSystem.secondaryText(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vault is Empty',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: DesignSystem.secondaryText(context),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final name = file['public_id'].split('/').last;
                final url = file['url'];

                return FadeInUp(
                  child: Card(
                    color: DesignSystem.surfaceColor(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.cloud_done_rounded,
                        color: DesignSystem.primaryOrange,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: DesignSystem.textColor(context),
                        ),
                      ),
                      subtitle: Text(
                        file['created_at'],
                        style: TextStyle(
                          color: DesignSystem.secondaryText(context),
                        ),
                      ),
                      onTap: () async {
                        final pin = await showDialog<String>(
                          context: context,
                          builder: (context) => const _PinDialog(
                            isSetup: false,
                            title: "Enter PIN to View",
                          ),
                        );

                        if (pin != null) {
                          try {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            final decryptedBytes = await _securityService
                                .decryptRemoteFile(url, pin);

                            if (context.mounted) Navigator.pop(context);

                            final tempDir = await getTemporaryDirectory();
                            final tempFile = File(
                              '${tempDir.path}/${name.replaceAll(".enc", "")}',
                            );
                            await tempFile.writeAsBytes(decryptedBytes);

                            if (context.mounted) {
                              await OpenFile.open(tempFile.path);
                            }
                          } catch (e) {
                            if (context.mounted) Navigator.pop(context);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Decryption Failed!"),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  final bool isSetup;
  final String title;
  final VoidCallback? onForgotPin;

  const _PinDialog({
    required this.isSetup,
    this.title = "Security Check",
    this.onForgotPin,
  });

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final TextEditingController _controller = TextEditingController();
  String _errorText = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isSetup ? 'Set Vault PIN' : widget.title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              hintText: 'Enter 4-digit PIN',
              errorText: _errorText.isEmpty ? null : _errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() => _errorText = ''),
          ),
          if (!widget.isSetup && widget.onForgotPin != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onForgotPin,
                child: Text(
                  'Forgot PIN?',
                  style: GoogleFonts.outfit(
                    color: DesignSystem.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.length == 4) {
              Navigator.pop(context, _controller.text);
            } else {
              setState(() => _errorText = 'Enter 4 digits');
            }
          },
          child: Text(widget.isSetup ? 'Set PIN' : 'Unlock'),
        ),
      ],
    );
  }
}
