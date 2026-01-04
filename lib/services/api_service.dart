import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';
import '../services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'notification_service.dart';
import '../services/subscription_service.dart';
import '../screens/subscription/subscription_screen.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // for navigatorKey

class ApiService {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> _canProceed(String serviceType) async {
    final errorMessage = await _subscriptionService.deductCredits(
      serviceType: serviceType,
    );

    if (errorMessage != null) {
      if (navigatorKey.currentState != null) {
        // Determine title based on error
        String title = "Access Denied";
        if (errorMessage.contains("Insufficient")) {
          title = "Insufficient Credits";
        }
        if (errorMessage.contains("expired")) title = "Plan Expired";

        showDialog(
          context: navigatorKey.currentState!.context,
          builder: (context) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                },
                child: const Text("Upgrade / Renew"),
              ),
            ],
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<String?> extractText(
    File imageFile, {
    String mode = 'standard',
  }) async {
    if (!await _canProceed('basic')) return null;
    try {
      print('Sending OCR request to: ${ApiConfig.ocrEndpoint}');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.ocrEndpoint),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      request.fields['mode'] = mode;
      request.fields['use_ai_correction'] = 'true';

      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add optional userId if available
      final user = _authService.currentUser;
      if (user != null) {
        request.fields['userId'] = user.uid;
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'];
      }
      print('OCR Failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('OCR Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> solveMath(File imageFile) async {
    if (!await _canProceed('advanced')) return null;
    try {
      print('Sending Math request to: ${ApiConfig.mathEndpoint}');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.mathEndpoint),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final user = _authService.currentUser;
      if (user != null) {
        request.fields['userId'] = user.uid;
      }

      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print('Math Solve Failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Math Error: $e');
      return null;
    }
  }

  Future<String?> vectorizeSketch(File imageFile) async {
    if (!await _canProceed('advanced')) return null;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.sketchEndpoint),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final user = _authService.currentUser;
      if (user != null) {
        request.fields['userId'] = user.uid;
      }

      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return response.body; // Direct SVG string
      }
      print(
        'Sketch Vectorize Failed: ${response.statusCode} - ${response.body}',
      );
      return null;
    } catch (e) {
      print('Sketch Error: $e');
      return null;
    }
  }

  Future<File?> pdfAction(
    String endpoint,
    List<File> files, {
    Map<String, String>? fields,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(endpoint));

      for (var file in files) {
        request.files.add(
          await http.MultipartFile.fromPath('files', file.path),
        );
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      final user = _authService.currentUser;
      if (user != null) {
        request.fields['userId'] = user.uid;
      }

      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${dir.path}/pdf_tool_result_$timestamp.pdf');
        await file.writeAsBytes(response.bodyBytes);
        _notificationService.showLocalNotification(
          title: 'PDF Task Complete',
          body: 'Your PDF file is ready.',
        );
        return file;
      }
      return null;
    } catch (e) {
      print('PDF Action Error: $e');
      return null;
    }
  }

  Future<List<dynamic>> getHistory() async {
    try {
      print('Fetching History from: ${ApiConfig.historyEndpoint}');
      final user = _authService.currentUser;
      if (user == null) return [];

      final response = await http.get(
        Uri.parse('${ApiConfig.historyEndpoint}${user.uid}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('History Fetch Error: $e');
      return [];
    }
  }

  Future<String?> transcribeAudio(File audioFile) async {
    if (!await _canProceed('advanced')) return null;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.transcribeEndpoint),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );

      final user = _authService.currentUser;
      if (user != null) {
        request.fields['userId'] = user.uid;
      }

      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'];
      }
      return null;
    } catch (e) {
      print('Transcription Error: $e');
      return null;
    }
  }

  Future<String?> translateText(String text, String targetLang) async {
    try {
      final user = _authService.currentUser;

      // Note: Translation endpoint likely needs auth too if protected.
      // If it's a simple post, adding header to headers map is tricky with the current structure
      // Wait, http.post headers map is in argument.
      // Let's refactor slightly to add token.

      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.post(
        Uri.parse(ApiConfig.translateEndpoint),
        headers: headers,
        body: jsonEncode({
          'text': text,
          'target_lang': targetLang,
          'userId': user?.uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated_text'];
      }
      return null;
    } catch (e) {
      print('Translation Error: $e');
      return null;
    }
  }

  Future<File?> textToSpeech(
    String text, {
    String voiceId = "en-US-ChristopherNeural",
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.ttsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'voice_id': voiceId}),
      );

      if (response.statusCode == 200) {
        // Here we would normally save the bytes to a temporary file
        // For now return null or implement temp file saving if path_provider is available
        return null;
      }
      return null;
    } catch (e) {
      print('TTS Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> recognizeObjects(File imageFile) async {
    if (!await _canProceed('basic')) return null;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.objectRecognitionEndpoint),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final user = _authService.currentUser;
      if (user != null) {
        request.fields['userId'] = user.uid;
      }

      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Object Recognition Error: $e');
      return null;
    }
  }

  Future<String?> summarizeDocument(String text) async {
    if (!await _canProceed('basic')) return null;
    try {
      final user = _authService.currentUser;

      final token = await _getToken();
      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.post(
        Uri.parse(ApiConfig.summarizeEndpoint),
        headers: headers,
        body: jsonEncode({
          'text': text,
          'max_sentences': 5,
          'userId': user?.uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['summary'];
      }
      return null;
    } catch (e) {
      print('Summarization Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> extractInvoiceData(File imageFile) async {
    if (!await _canProceed('advanced')) return null;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.invoiceExtractionEndpoint),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final user = _authService.currentUser;
      if (user != null) {
        request.fields['userId'] = user.uid;
      }

      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['extracted_data'];
      }
      return null;
    } catch (e) {
      print('Invoice Extraction Error: $e');
      return null;
    }
  }

  Future<List<dynamic>?> detectBarcodes(File imageFile) async {
    if (!await _canProceed('basic')) return null;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.barcodeDetectionEndpoint),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final user = _authService.currentUser;
      if (user != null) {
        request.fields['userId'] = user.uid;
      }

      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['barcodes'];
      }
      return null;
    } catch (e) {
      print('Barcode Detection Error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // SOCIAL & SYSTEM
  // ---------------------------------------------------------------------------

  Future<bool> submitFeedback({
    required int rating,
    required String category,
    required String message,
  }) async {
    final user = _authService.currentUser;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/system/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user?.uid,
          'email': user?.email,
          'rating': rating,
          'category': category,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Feedback failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  Future<Map<String, String>> getCommunityLinks() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/system/community'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'discord': data['discord'] ?? 'https://discord.gg',
          'telegram': data['telegram'] ?? 'https://t.me',
        };
      }
    } catch (e) {
      print('Error fetching community links: $e');
    }
    return {'discord': 'https://discord.gg', 'telegram': 'https://t.me'};
  }

  Future<Map<String, dynamic>> getReferralInfo() async {
    final user = _authService.currentUser;
    if (user == null) return {};

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/referral/info?userId=${user.uid}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Referral info failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching referral info: $e');
    }

    // Fallback
    return {'referralCode': '-----', 'points': 0, 'referralsCount': 0};
  }

  Future<Map<String, dynamic>> claimReferralCode(String code) async {
    final user = _authService.currentUser;
    if (user == null) return {'success': false, 'message': 'Not logged in'};

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/referral/claim?userId=${user.uid}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'points': data['pointsAwarded'],
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to claim',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<bool> updateProfileInfo({
    required String fullName,
    String? phone,
    String? bio,
    String? location,
  }) async {
    try {
      final user = _authService.currentUser;
      final token = await _getToken();

      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/update-info'),
        headers: headers,
        body: jsonEncode({
          'userId': user?.uid,
          'fullName': fullName,
          'phone': phone,
          'bio': bio,
          'location': location,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update Profile Error: $e');
      return false;
    }
  }

  Future<bool> updateAvatar(File imageFile) async {
    try {
      final user = _authService.currentUser;
      final token = await _getToken();
      if (user == null) return false;

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      // Data URI format
      final avatarString = 'data:image/jpeg;base64,$base64Image';

      final headers = {'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/update-avatar'),
        headers: headers,
        body: jsonEncode({'userId': user.uid, 'avatar': avatarString}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print(
        'Update Avatar Error: $e',
      ); // Replaced debugPrint with print for simplicity or add import
      return false;
    }
  }

  Future<void> updateDeviceToken() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final token = await _notificationService.getDeviceToken();
      if (token == null) return;

      print('Updating Device Token: $token');
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/update-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': user.uid, 'token': token}),
      );
    } catch (e) {
      print('Error updating device token: $e');
    }
  }

  Future<void> deleteAccount() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/delete'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account: ${response.body}');
    }
  }
}
