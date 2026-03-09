import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart' as gsis;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. ቁልፉን በ const መሳብ (ይህ ለ GitHub ቢልድ ወሳኝ ነው)
  static const String _envGoogleId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  
  // 2. ቁልፉን መርጦ ማዘጋጀት
  static final String _googleClientId = _envGoogleId.isNotEmpty 
      ? _envGoogleId 
      : (dotenv.env['GOOGLE_CLIENT_ID'] ?? '');

  // የ Google Sign-In ኮንፊገሬሽን
  final gsis.GoogleSignIn _googleSignIn = gsis.GoogleSignIn(
    serverClientId: _googleClientId,
  );

  Future<User?> signInWithGoogle() async {
    // ዊንዶውስ ላይ ጎግል ሎግኢን ሌላ መንገድ ስለሚፈልግ ለአሁኑ እንዘለዋለን
    if (!kIsWeb && Platform.isWindows) {
      debugPrint("Google Sign-In is not supported on Windows in this flow.");
      return null;
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken ?? '',
        accessToken: googleAuth.accessToken,
      );

      debugPrint("Login Success! ✅ User: ${response.user?.email}");
      return response.user;
    } on SocketException {
      debugPrint("የኢንተርኔት ግንኙነት የለም! 🌐❌");
      return null;
    } catch (e) {
      debugPrint("Error during Google Sign-In: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb && !Platform.isWindows) {
        await _googleSignIn.signOut();
      }
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }

  User? get currentUser => _supabase.auth.currentUser;

  bool get isAuthenticated => _supabase.auth.currentSession != null;
}
