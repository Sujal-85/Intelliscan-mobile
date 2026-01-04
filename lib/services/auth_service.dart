import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/config/api_config.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper to sync with backend
  Future<void> _syncWithBackend(User user) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': user.email,
          'fullName': user.displayName ?? user.email!.split('@')[0],
          'avatar': user.photoURL,
          'firebaseId': user.uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          print('Backend Sync Successful. Token stored.');

          // Show Welcome Notification
          await NotificationService().showWelcomeNotification(
            user.displayName ?? user.email!.split('@')[0],
          );
        }
      } else {
        print('Backend Sync Failed: ${response.body}');
      }
    } catch (e) {
      print('Backend Sync Error: $e');
    }
  }

  // Sign in with Email & Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        await _syncWithBackend(cred.user!);
      }
      return cred;
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  // Sign up with Email & Password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        await _syncWithBackend(cred.user!);
      }
      return cred;
    } catch (e) {
      print('Error signing up with email: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        await _syncWithBackend(cred.user!);
      }
      return cred;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign in with GitHub
  Future<UserCredential?> signInWithGitHub() async {
    try {
      GithubAuthProvider githubProvider = GithubAuthProvider();
      final cred = await _auth.signInWithProvider(githubProvider);
      if (cred.user != null) {
        await _syncWithBackend(cred.user!);
      }
      return cred;
    } catch (e) {
      print('Error signing in with GitHub: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
