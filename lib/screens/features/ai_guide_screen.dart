import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/design_system.dart';
import '../../services/ai_service.dart';

class AiGuideScreen extends StatefulWidget {
  const AiGuideScreen({super.key});

  @override
  State<AiGuideScreen> createState() => _AiGuideScreenState();
}

class _AiGuideScreenState extends State<AiGuideScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final AiService _aiService = AiService();

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        role: 'assistant',
        content: 'Hi! I am your IntelliScan Guide. How can I help you today?',
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    final response = await _aiService.askGuide(_messages);

    setState(() {
      _messages.add(ChatMessage(role: 'assistant', content: response));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundColor(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg, index);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FadeIn(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          DesignSystem.primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI is thinking...',
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignSystem.secondaryText(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        gradient: DesignSystem.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Guide',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
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
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, int index) {
    bool isUser = msg.role == 'user';
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: 100 * (index % 5)),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: msg.content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Message copied!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser ? null : DesignSystem.surfaceColor(context),
              gradient: isUser ? DesignSystem.primaryGradient : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(24),
                topRight: const Radius.circular(24),
                bottomLeft: Radius.circular(isUser ? 24 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: MarkdownBody(
              data: msg.content,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.outfit(
                  color: isUser
                      ? Colors.white
                      : DesignSystem.textColor(context),
                  fontSize: 15,
                  height: 1.4,
                ),
                strong: GoogleFonts.outfit(
                  color: isUser
                      ? Colors.white
                      : DesignSystem.textColor(context),
                  fontWeight: FontWeight.bold,
                ),
                listBullet: GoogleFonts.outfit(
                  color: isUser
                      ? Colors.white
                      : DesignSystem.textColor(context),
                ),
                code: GoogleFonts.firaCode(
                  backgroundColor: isUser
                      ? Colors.white.withOpacity(0.1)
                      : DesignSystem.backgroundColor(context).withOpacity(0.5),
                  fontSize: 13,
                  color: isUser
                      ? Colors.white
                      : DesignSystem.textColor(context),
                ),
                codeblockDecoration: BoxDecoration(
                  color: isUser
                      ? Colors.white.withOpacity(0.1)
                      : DesignSystem.backgroundColor(context).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: 55,
                decoration: BoxDecoration(
                  color: DesignSystem.backgroundColor(context),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: DesignSystem.outlineColor(context).withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.outfit(
                    color: DesignSystem.textColor(context),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask your guide...',
                    hintStyle: GoogleFonts.outfit(
                      color: DesignSystem.secondaryText(context),
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                height: 55,
                width: 55,
                decoration: const BoxDecoration(
                  gradient: DesignSystem.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DesignSystem.primaryPurple,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
