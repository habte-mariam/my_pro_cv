import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // ኢንተርኔት ለመፈተሽ
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoggingIn = false;
  final TextEditingController _emailController = TextEditingController();

  // የኢንተርኔት ግንኙነትን የሚፈትሽ ፋንክሽን
  Future<bool> _checkInternet() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _showNoInternetDialog();
      return false;
    }
    return true;
  }

  // ኢንተርኔት የለም የሚል Dialog
  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 10),
            Text("No Internet"),
          ],
        ),
        content:
            const Text("Please turn on your internet connection to continue."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // 1. የ Google Sign-In (ለአንድሮይድ እና ለዌብ)
  Future<void> _handleGoogleSignIn() async {
    if (_isLoggingIn) return;

    if (!await _checkInternet()) return;

    if (!kIsWeb && Platform.isWindows) {
      _showSnackBar(
          "Google Sign-In is not supported on Windows. Please use Email.");
      return;
    }

    setState(() => _isLoggingIn = true);
    try {
      final authService = AuthService();
      await authService.signInWithGoogle();
    } catch (e) {
      _showSnackBar("Login Error: $e");
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  // 2. የ Email Magic Link (ለዊንዶውስ)
  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Please enter your email");
      return;
    }
    if (!await _checkInternet()) return;

    setState(() => _isLoggingIn = true);

    try {
      // 🔴 በቀጥታ Supabaseን እዚህ እንጠራዋለን
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        // ተጠቃሚው ሊንኩን ሲነካ ወደ አፑ እንዲመለስ
        emailRedirectTo:
            kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      );

      _showSnackBar(
          "Email link sent to $email. Please check your email inbox (and Spam folder).");
    } catch (e) {
      _showSnackBar("Email Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWindows = !kIsWeb && Platform.isWindows;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Stack(
                children: [
                  // Decorations
                  Positioned(
                    top: -60.h,
                    right: -60.w,
                    child: CircleAvatar(
                      radius: 140.r,
                      backgroundColor:
                          const Color(0xFF1E293B).withOpacity(0.05),
                    ),
                  ),
                  Positioned(
                    bottom: -40.h,
                    left: -40.w,
                    child: CircleAvatar(
                      radius: 100.r,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                    ),
                  ),

                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth > 500
                              ? 400
                              : double.infinity),
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 35.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 40.h),

                              // Logo
                              Hero(
                                tag: 'app_logo',
                                child: Container(
                                  padding: EdgeInsets.all(25.r),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(30.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      )
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.description_rounded,
                                    size: 60.sp,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),

                              SizedBox(height: 30.h),
                              Text(
                                "CV Pro Generator",
                                style: TextStyle(
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                isWindows
                                    ? "Sign in with your email to continue on Windows."
                                    : "Professional resumes made simple.\nSign in to start building your future.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.blueGrey.shade600),
                              ),

                              SizedBox(height: 50.h),

                              // Conditional UI based on Platform
                              if (isWindows) ...[
                                TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    hintText: "Enter your email",
                                    prefixIcon:
                                        const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15.r),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50.h,
                                  child: ElevatedButton(
                                    onPressed: _isLoggingIn
                                        ? null
                                        : _handleEmailSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E293B),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15.r)),
                                    ),
                                    child: _isLoggingIn
                                        ? const CircularProgressIndicator(
                                            color: Colors.white)
                                        : const Text("Send Link",
                                            style:
                                                TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ] else ...[
                                // Google Login for Android/Web
                                _isLoggingIn
                                    ? const CircularProgressIndicator(
                                        color: Color(0xFF1E293B))
                                    : SizedBox(
                                        width: double.infinity,
                                        height: 56.h,
                                        child: OutlinedButton.icon(
                                          onPressed: _handleGoogleSignIn,
                                          icon: Image.network(
                                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                            height: 22.h,
                                          ),
                                          label: const Text(
                                              "Continue with Google"),
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        15.r)),
                                            side: BorderSide(
                                                color: Colors.grey.shade200),
                                          ),
                                        ),
                                      ),
                              ],

                              SizedBox(height: 40.h),
                              Opacity(
                                opacity: 0.5,
                                child: Text(
                                    "By continuing, you agree to our Terms",
                                    style: TextStyle(fontSize: 11.sp)),
                              ),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
