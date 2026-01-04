import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../services/auth_service.dart';

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class AiService {
  final AuthService _authService = AuthService();

  Future<String> askGuide(List<ChatMessage> conversation) async {
    try {
      final user = _authService.currentUser;

      final response = await http.post(
        Uri.parse(ApiConfig.guideEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': conversation.map((m) => m.toJson()).toList(),
          'userId': user?.uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'I could not process that request.';
      } else {
        return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Could not connect to the AI service. Please ensure the backend is running.';
    }
  }
}
