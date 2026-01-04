import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/design_system.dart';
import '../../services/security_service.dart';
import '../../services/auth_service.dart';

class SecurityQuestionScreen extends StatefulWidget {
  final bool isSetup;
  const SecurityQuestionScreen({super.key, required this.isSetup});

  @override
  State<SecurityQuestionScreen> createState() => _SecurityQuestionScreenState();
}

class _SecurityQuestionScreenState extends State<SecurityQuestionScreen> {
  final SecurityService _securityService = SecurityService();
  final AuthService _authService = AuthService();
  final TextEditingController _answerController = TextEditingController();

  String? _selectedQuestionId;
  String? _questionTextForVerify;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isSetup) {
      _loadUserQuestion();
    }
  }

  Future<void> _loadUserQuestion() async {
    setState(() => _isLoading = true);
    final user = _authService.currentUser;
    if (user != null) {
      final qId = await _securityService.getSecurityQuestionId(user.uid);
      if (qId != null) {
        final q = _securityService.securityQuestions.firstWhere(
          (element) => element['id'] == qId,
          orElse: () => {'text': 'Unknown Question'},
        );
        setState(() {
          _questionTextForVerify = q['text'];
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No security question set. Cannot recover PIN.'),
            ),
          );
          Navigator.pop(context, false);
        }
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    if (_answerController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        if (widget.isSetup) {
          if (_selectedQuestionId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a question')),
            );
            setState(() => _isLoading = false);
            return;
          }
          await _securityService.setSecurityQuestion(
            user.uid,
            _selectedQuestionId!,
            _answerController.text,
          );
          if (mounted) Navigator.pop(context, true);
        } else {
          final isValid = await _securityService.verifySecurityAnswerEndpoint(
            user.uid,
            _answerController.text,
          );
          if (isValid) {
            if (mounted) Navigator.pop(context, true);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Incorrect Answer')));
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          widget.isSetup ? 'Setup Recovery' : 'Forgot PIN',
          style: GoogleFonts.outfit(color: DesignSystem.textColor(context)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: DesignSystem.textColor(context),
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeInDown(
                    child: Text(
                      widget.isSetup
                          ? 'Select a security question to recover your Vault PIN if forgotten.'
                          : 'Answer your security question to reset your PIN.',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: DesignSystem.secondaryText(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  FadeInUp(
                    child: widget.isSetup
                        ? DropdownButtonFormField<String>(
                            initialValue: _selectedQuestionId,
                            dropdownColor: DesignSystem.cardColor(context),
                            decoration: InputDecoration(
                              labelText: 'Select Question',
                              labelStyle: TextStyle(
                                color: DesignSystem.secondaryText(context),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: DesignSystem.secondaryText(
                                    context,
                                  ).withOpacity(0.3),
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: DesignSystem.textColor(context),
                            ),
                            items: _securityService.securityQuestions.map((q) {
                              return DropdownMenuItem(
                                value: q['id'],
                                child: Text(
                                  q['text']!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: DesignSystem.textColor(context),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedQuestionId = val),
                          )
                        : Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: DesignSystem.cardColor(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: DesignSystem.primaryPurple.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              _questionTextForVerify ?? 'Loading question...',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: DesignSystem.textColor(context),
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: TextField(
                      controller: _answerController,
                      style: TextStyle(color: DesignSystem.textColor(context)),
                      decoration: InputDecoration(
                        labelText: 'Your Answer',
                        labelStyle: TextStyle(
                          color: DesignSystem.secondaryText(context),
                        ),
                        hintText: 'Enter answer (case insensitive)',
                        hintStyle: TextStyle(
                          color: DesignSystem.secondaryText(
                            context,
                          ).withOpacity(0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: DesignSystem.secondaryText(
                              context,
                            ).withOpacity(0.3),
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_open_rounded,
                          color: DesignSystem.primaryPurple,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignSystem.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.isSetup
                            ? 'Save Security Question'
                            : 'Verify & Reset PIN',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
