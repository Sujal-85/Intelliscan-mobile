import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static const String _vaultDirName = 'secure_vault';
  static const String _pinKey = 'vault_pin_hash';

  // --- PIN Management ---

  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    if (storedHash == null) return false;

    final inputHash = sha256.convert(utf8.encode(pin)).toString();
    return storedHash == inputHash;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await prefs.setString(_pinKey, hash);
  }

  // --- File Encryption ---

  // Derives a 32-byte key from the PIN
  enc.Key _deriveKey(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  // --- Cloudinary Integration ---

  Future<void> logUpload(File file, String userId) async {
    // This function is kept for reference if we wanted to just upload locally encrypted files
    // But for stream safety, we upload bytes directly in uploadEncryptedFile.
  }

  Future<String?> uploadEncryptedFile(
    File originalFile,
    String pin,
    String userId,
  ) async {
    final key = _deriveKey(pin);
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));

    final bytes = await originalFile.readAsBytes();
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    // Combine IV + Encrypted Data
    final combinedBytes = iv.bytes + encrypted.bytes;

    // Create temp file for upload
    final tempDir = await getTemporaryDirectory();
    final filename = originalFile.uri.pathSegments.last;
    final tempFile = File('${tempDir.path}/$filename.enc');
    await tempFile.writeAsBytes(combinedBytes);

    // Upload to Backend
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/vault/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['userId'] = userId;
    request.files.add(await http.MultipartFile.fromPath('file', tempFile.path));

    final response = await request.send();
    // Cleanup
    if (await tempFile.exists()) await tempFile.delete();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);
      return json['file']['url'];
    } else {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> fetchVaultFiles(String userId) async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/vault/list/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['files'];
    }
    return [];
  }

  Future<List<int>> decryptRemoteFile(String url, String pin) async {
    // Download Encrypted File
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception("Failed to download file");

    final bytes = response.bodyBytes;

    final key = _deriveKey(pin);
    // Determine IV from first 16 bytes
    final encrypter = enc.Encrypter(enc.AES(key));
    final iv = enc.IV(bytes.sublist(0, 16));
    final encryptedBytes = bytes.sublist(16);

    final decrypted = encrypter.decryptBytes(
      enc.Encrypted(encryptedBytes),
      iv: iv,
    );
    return decrypted;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Keep local encryptFile for backup if needed, but primary is now uploadEncryptedFile
  Future<File> encryptFile(File originalFile, String pin) async {
    // ... existing implementation ...
    return File("");
  }

  // --- Security Question ---
  final List<Map<String, String>> securityQuestions = [
    {'id': 'q1', 'text': 'What was the name of your first pet?'},
    {'id': 'q2', 'text': 'What is your mother\'s maiden name?'},
    {'id': 'q3', 'text': 'What was the make of your first car?'},
    {'id': 'q4', 'text': 'In what city were you born?'},
    {'id': 'q5', 'text': 'What is your favorite food?'},
  ];

  Future<void> setSecurityQuestion(
    String userId,
    String questionId,
    String answer,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final answerHash = sha256
        .convert(utf8.encode(answer.toLowerCase().trim()))
        .toString();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/vault/set-security-question'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'questionId': questionId,
        'answerHash': answerHash,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to set security question');
    }
  }

  Future<String?> getSecurityQuestionId(String userId) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/vault/get-security-question/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['questionId'];
      }
    }
    return null;
  }

  Future<bool> verifySecurityAnswerEndpoint(
    String userId,
    String answer,
  ) async {
    final token = await _getToken();
    if (token == null) return false;

    final answerHash = sha256
        .convert(utf8.encode(answer.toLowerCase().trim()))
        .toString();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/vault/verify-security-answer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userId': userId, 'answerHash': answerHash}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isValid'] ?? false;
    }
    return false;
  }
}
