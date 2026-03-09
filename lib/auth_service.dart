import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart' as gsis;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // የ Google Sign-In ኮንፊገሬሽን
  final gsis.GoogleSignIn _googleSignIn = gsis.GoogleSignIn(
    serverClientId: dotenv.env['GOOGLE_CLIENT_ID'],
  );

  /// የጎግል ሎግኢን ተግባር - ከኢንተርኔት ስህተት መከላከያ ጋር
  Future<User?> signInWithGoogle() async {
    try {
      // 1. መጀመሪያ ኢንተርኔት መኖሩን ቼክ ማድረግ (አማራጭ)
      // ማሳሰቢያ፡ ዊንዶውስ ላይ ሎግኢን ካልፈለክ ይህን ሙሉ ፋንክሽን አትጠራውም

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
      return null; // ኢንተርኔት ከሌለ ዝም ብሎ null ይመልሳል
    } catch (e) {
      debugPrint("Error during Google Sign-In: $e");
      return null; // ስህተት ቢፈጠርም አፑ እንዳይዘጋ null ይመልሳል
    }
  }

  /// ሎግ አውት ለማድረግ
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }

  /// የአሁኑን ተጠቃሚ ለማወቅ
  /// ዊንዶውስ ላይ ኢንተርኔት ባይኖርም የተቀመጠ (Persisted) ሴሽን ካለ ያነባል
  User? get currentUser => _supabase.auth.currentUser;

  /// ተጠቃሚው ገብቷል ወይስ አልገባም የሚለውን ለማረጋገጥ
  bool get isAuthenticated => _supabase.auth.currentSession != null;
}
