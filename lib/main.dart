import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

// Internal Imports
import 'database_helper.dart';
import 'app_fonts.dart';
import 'splash_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

// Global Notifier for Theme and Font changes
final ValueNotifier<Map<String, dynamic>> appSettingsNotifier =
    ValueNotifier({'themeColor': 0xFF1E293B, 'fontFamily': 'JetBrains Mono'});

void main() async {
  // 1. Flutter Engine ዝግጁ መሆኑን ማረጋገጥ
  WidgetsFlutterBinding.ensureInitialized();

  // 2. ለዊንዶውስ ዲፕ ሊንክ ምዝገባ
  if (!kIsWeb && Platform.isWindows) {
    try {
      final appLinks = AppLinks();
      await appLinks.getInitialLink();
    } catch (e) {
      debugPrint("Windows protocol registration error: $e");
    }
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // GitHub ላይ ሲሆን ፋይሉ ስለማይኖር እዚህ ጋር ዝም እንለዋለን
    debugPrint("Info: .env file not found, using Environment variables");
  }

  // 2. Supabase Initialization (ከ GitHub Secrets ወይም ከ .env)
  final String supabaseUrl = String.fromEnvironment('SUPABASE_URL').isNotEmpty
      ? String.fromEnvironment('SUPABASE_URL')
      : (dotenv.env['SUPABASE_URL'] ?? '');

  final String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty
          ? String.fromEnvironment('SUPABASE_ANON_KEY')
          : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // 4. Deep Link Handling
  final appLinks = AppLinks();

  appLinks.getInitialLink().then((uri) {
    if (uri != null) _handleDeepLink(uri);
  }).catchError((e) {
    debugPrint("Initial link error: $e");
    return null;
  });

  appLinks.uriLinkStream.listen((uri) {
    debugPrint('Link called: $uri');
    _handleDeepLink(uri);
  });

  // 5. ዳታቤዝ እና ፎንቶችን ማስነሳት
  await _initializeAppData();

  runApp(const MyApp());
}

void _handleDeepLink(Uri uri) async {
  if (uri.toString().contains('login-callback') ||
      uri.fragment.contains('access_token')) {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      debugPrint("Login success via Link! 🎉");
    } catch (e) {
      debugPrint("Error handling link: $e");
    }
  }
}

Future<void> _initializeAppData() async {
  try {
    await AppFonts.loadAllFontBytes();
    AppFonts.initFromBytes(AppFonts.fontBytesMap);

    final savedSettings = await DatabaseHelper.instance.getSettings();

    if (savedSettings.isNotEmpty) {
      appSettingsNotifier.value = {
        'themeColor': savedSettings['themeColor'] ?? 0xFF1E293B,
        'fontFamily': savedSettings['fontFamily'] ?? 'JetBrains Mono',
      };
    }
    debugPrint("App initialization successful! 🚀");
  } catch (e) {
    debugPrint("Initialization Error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, _) {
        final Color themeColor = Color(settings['themeColor']);

        return ScreenUtilInit(
          designSize: const Size(393, 852),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'CV Maker Pro',
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: themeColor,
                  primary: themeColor,
                ),
                fontFamily: settings['fontFamily'],
              ),
              initialRoute: '/',
              routes: {
                '/': (context) => const SplashScreen(),
                '/auth': (context) => const AuthWrapper(),
                '/home': (context) => const HomeScreen(),
                '/login': (context) => const LoginScreen(),
              },
            );
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _handleStartUp();
  }

  Future<void> _handleStartUp() async {
    // ዊንዶውስ ላይ ከሆነ ሎግኢኑን ችላ ብለን አፕዴት ብቻ ቼክ እናደርጋለን
    _checkAppUpdate();
  }

  Future<void> _checkAppUpdate() async {
    try {
      final data = await Supabase.instance.client
          .from('app_config')
          .select()
          .maybeSingle();

      if (data != null && mounted) {
        final int minVersion =
            int.tryParse(data['min_version'].toString()) ?? 0;
        final String updateUrl = data['update_url'] ?? "https://google.com";
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        final int currentVersion = int.tryParse(packageInfo.buildNumber) ?? 0;

        if (minVersion > currentVersion) {
          _showUpdateDialog(updateUrl);
        }
      }
    } catch (e) {
      debugPrint("Update check skipped: $e");
    }
  }

  void _showUpdateDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Update Required! 🚀"),
        content: const Text("A new version is available."),
        actions: [
          TextButton(
            onPressed: () async {
              final Uri uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text("Download"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 ዊንዶውስ ላይ ምንም አይነት የሎግኢን ቼክ ሳይደረግ በቀጥታ ወደ HomeScreen ይገባል
    if (!kIsWeb && Platform.isWindows) {
      return const HomeScreen();
    }

    // ለሌሎች ፕላትፎርሞች (Android/iOS) ሎግኢን አስፈላጊ ነው
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
