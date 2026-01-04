import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';
import '../../services/api_service.dart';

class SpeechTranslationScreen extends StatefulWidget {
  const SpeechTranslationScreen({super.key});

  @override
  State<SpeechTranslationScreen> createState() =>
      _SpeechTranslationScreenState();
}

class _SpeechTranslationScreenState extends State<SpeechTranslationScreen> {
  bool _isListening = false;
  bool _isTranslating = false;
  String _targetLanguage = 'hi'; // Using codes for backend
  final String _recognizedText =
      "How are you doing today? I hope you are having a great time exploring the app.";
  String _translatedText = "";
  final ApiService _apiService = ApiService();

  final Map<String, String> _languageMap = {
    'Hindi': 'hi',
    'Marathi': 'mr',
    'English': 'en',
    'Spanish': 'es',
    'French': 'fr',
  };

  void _translate() async {
    if (_recognizedText.isEmpty) return;

    setState(() => _isTranslating = true);

    final result = await _apiService.translateText(
      _recognizedText,
      _targetLanguage,
    );

    setState(() {
      _isTranslating = false;
      if (result != null) {
        _translatedText = result;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Translation failed. Please try again.'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Speech & Language',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildListeningSection(),
            const SizedBox(height: 32),
            _buildLanguageSelector(),
            const SizedBox(height: 32),
            _buildOutputCard(),
            const SizedBox(height: 40),
            CustomGradientButton(
              text: _isTranslating ? 'Translating...' : 'Translate Now',
              isLoading: _isTranslating,
              onPressed: _translate,
              icon: Icons.translate_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningSection() {
    return FadeInDown(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isListening = !_isListening),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _isListening ? DesignSystem.primaryPurple : Colors.white,
                shape: BoxShape.circle,
                boxShadow: DesignSystem.softShadow,
                border: Border.all(
                  color: DesignSystem.primaryPurple.withOpacity(0.1),
                  width: 4,
                ),
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                size: 48,
                color: _isListening ? Colors.white : DesignSystem.primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isListening ? 'Listening...' : 'Tap Mic to Start',
            style: TextStyle(
              color: _isListening ? DesignSystem.primaryPurple : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return FadeInUp(
      child: GlassCard(
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _languageMap.entries
                  .firstWhere((e) => e.value == _targetLanguage)
                  .key,
              isExpanded: true,
              items: _languageMap.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    'Translate to: $value',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              onChanged: (val) =>
                  setState(() => _targetLanguage = _languageMap[val]!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutputCard() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: GlassCard(
        borderRadius: 24,
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recognized Text',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _recognizedText),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Original text copied!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: DesignSystem.primaryPurple,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.volume_up_rounded,
                          color: DesignSystem.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Text(
                'How are you doing today? I hope you are having a great time exploring the app.',
                style: TextStyle(fontSize: 18, height: 1.5),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Translation Result',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (_translatedText.isNotEmpty)
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _translatedText),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Translation copied!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: DesignSystem.primaryPurple,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Share.share(_translatedText);
                          },
                          icon: const Icon(
                            Icons.share_rounded,
                            color: DesignSystem.primaryPurple,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_translatedText.isEmpty && !_isTranslating)
                const Text(
                  'Your translation will appear here...',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                )
              else
                Text(
                  _translatedText,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: DesignSystem.primaryPurple,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
