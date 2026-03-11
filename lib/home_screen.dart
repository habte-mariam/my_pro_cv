import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_new_cv/database_helper.dart';
import 'package:my_new_cv/forms/main_cv_form.dart';
import 'package:my_new_cv/profile_service.dart';
import 'package:package_info_plus/package_info_plus.dart' show PackageInfo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Screens
import 'package:my_new_cv/about_screen.dart';
import 'package:my_new_cv/help_screen.dart';
import 'package:my_new_cv/settings_screen.dart';
import 'package:my_new_cv/saved_cvs_screen.dart';
import 'package:my_new_cv/templates/template_picker_screen.dart';
import 'package:my_new_cv/admin_stats_page.dart';

// Helpers & Services
import 'cv_model.dart';
import 'database_service.dart';
import 'auth_service.dart';

//pdf
import 'files/image_to_pdf_screen.dart';
import 'files/pdf_merge_screen.dart';
import 'files/pdf_compress_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. .env ፋይሉን ለመጫን መሞከር (ለ Local PC ስራ)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Info: .env file not found, using Environment variables");
  }

  // 2. ቁልፎቹን መሳብ (በጣም ወሳኙ ክፍል!)
  // ማሳሰቢያ፡ const የግድ ያስፈልጋል፣ አለበለዚያ GitHub ላይ የሰጠኸውን Key አያነብም
  const String envUrl = String.fromEnvironment('SUPABASE_URL');
  const String envKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // ከ Environment ካጣ ወደ .env ይሄዳል
  final String supabaseUrl =
      envUrl.isNotEmpty ? envUrl : (dotenv.env['SUPABASE_URL'] ?? '');
  final String supabaseAnonKey =
      envKey.isNotEmpty ? envKey : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

  // 3. Supabase ማስጀመር (ከመጀመሩ በፊት ባዶ አለመሆኑን ቼክ እናድርግ)
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint("CRITICAL ERROR: Supabase Keys are missing!");
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CV Builder Pro',
          theme: ThemeData(
            useMaterial3: true,
            primaryColor: const Color(0xFF1E293B),
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF1E293B)),
          ),
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: widget!,
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CvModel? userCv;
  final int _primaryColorValue = 0xFF1E293B;
  bool _isLoading = true;
  int _adminTapCount = 0;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadLastEmail();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUserLogsAndStats();
    });
  }

  Future<void> _loadLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('last_searched_email') ?? '';
    if (lastEmail.isNotEmpty) {
      setState(() {
        _emailSearchController.text = lastEmail;
      });
    }
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20.sp, color: const Color(0xFF009688)),
      title: Text(title, style: TextStyle(fontSize: 13.sp)),
      onTap: onTap,
    );
  }

  Future<void> _updateUserLogsAndStats() async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      final user = _supabase.auth.currentUser;
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      final Battery battery = Battery();
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final connectivityResult = await (Connectivity().checkConnectivity());

      // 1. የቦታ መረጃ ማግኘት (IP-Based)
      String systemLocation = "Unknown";
      try {
        final locResponse = await http
            .get(Uri.parse('http://ip-api.com/json'))
            .timeout(const Duration(seconds: 5));
        if (locResponse.statusCode == 200) {
          final data = jsonDecode(locResponse.body);
          systemLocation = "${data['city']}, ${data['country']}";
        }
      } catch (_) {
        debugPrint("Location fetch failed");
      }

      // 2. የስልክ ሞዴል እና OS ስሪት ማግኘት
      String model = "Unknown";
      String osVersion = "Unknown";

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
          model = androidInfo.model;
          osVersion = "Android ${androidInfo.version.release}";
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
          model = iosInfo.utsname.machine;
          osVersion = "iOS ${iosInfo.systemVersion}";
        }
      }

      // 3. የባትሪ እና የኢንተርኔት ሁኔታ
      int batteryLevel = await battery.batteryLevel;
      String internetStatus =
          connectivityResult.contains(ConnectivityResult.none)
              ? "Offline"
              : (connectivityResult.contains(ConnectivityResult.wifi)
                  ? "WiFi"
                  : "Mobile/Other");

      // 4. መለያዎችን ማዘጋጀት (ያልገባ ተጠቃሚ ቢሆንም እንኳ)
      // 🎯 ቁልፍ ለውጥ፡ ተጠቃሚው ካልገባ 'guest_user' የሚል ስም እንሰጠዋለን
      final String finalEmail = user?.email ?? "guest_user";
      final String finalName =
          user?.userMetadata?['full_name'] ?? user?.email ?? "Guest User";

      // 5. ወደ Supabase መላክ (Upsert)
      await _supabase.from('user_logs').upsert({
        'user_id': user?.id, // Login ካላደረገ null ይሆናል
        'email': finalEmail, // መለያ 1
        'name': finalName,
        'model': model, // መለያ 2
        'os_version': osVersion,
        'battery': "$batteryLevel%",
        'internet': internetStatus,
        'location': systemLocation,
        'app_version': packageInfo.version,
        'last_seen': DateTime.now().toIso8601String(),
        'action': 'app_open',
      }, onConflict: 'email, model'); // 🎯 በኢሜይል እና በሞዴል ጥምረት ይለያቸዋል

      debugPrint("Sync Success for: $finalEmail ($model)");
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  Future<void> _initializeData() async {
    await _refreshData();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _checkUpdateWithSupabase();
    });
  }

  Future<void> _checkUpdateWithSupabase() async {
    try {
      final response = await _supabase.from('app_settings').select().filter(
          'key',
          'in',
          '("min_version_code","link_arm64","link_armV7","link_universal")');
      final settings = {for (var item in response) item['key']: item['value']};
      int latestVersion =
          int.tryParse(settings['min_version_code'] ?? '0') ?? 0;
      final info = await PackageInfo.fromPlatform();
      int currentBuildNumber = int.tryParse(info.buildNumber) ?? 0;

      if (latestVersion > currentBuildNumber) {
        String updateUrl = settings['link_universal'] ?? '';
        if (!kIsWeb && Platform.isAndroid) {
          final deviceInfo = DeviceInfoPlugin();
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          if (androidInfo.supportedAbis.contains("arm64-v8a")) {
            updateUrl = settings['link_arm64'] ?? updateUrl;
          } else if (androidInfo.supportedAbis.contains("armeabi-v7a")) {
            updateUrl = settings['link_armV7'] ?? updateUrl;
          }
        }
        if (!mounted) return;
        _showForceUpdateDialog(context, updateUrl);
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dbService = DatabaseService();
      // DatabaseService.fetchUserCv() አሁን ሙሉውን ዳታ ሰብስቦ ያመጣል
      final cloudData = await dbService.fetchUserCv();
      if (mounted) {
        setState(() {
          userCv = cloudData;
          _isLoading = false;
        });
        _updateUserLogsAndStats();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => screen));
    if (mounted) _refreshData();
  }

  final TextEditingController _emailSearchController = TextEditingController();
  bool _isSearching = false;

  void _handleProfileSearch() async {
    final email = _emailSearchController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSearching = true);

    // 1. ከ Supabase ፈልጎ ወደ SQLite Sync ያደርጋል
    final cloudResult = await ProfileService.searchAndSyncByEmail(email);

    if (cloudResult != null) {
      final fullLocalData =
          await DatabaseHelper.instance.getFullProfile(email: email);

      if (mounted && fullLocalData != null) {
        // ✅ 2. ሰርች የተደረገውን ኢሜይል ለወደፊት እንዲቀመጥ ሴቭ እናደርጋለን
        await _saveLastSearchedEmail(email);

        setState(() {
          userCv = CvModel.fromJson(fullLocalData);
          _isSearching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profile for ${userCv?.firstName} loaded! ✅"),
            backgroundColor: Colors.green,
          ),
        );
        _emailSearchController.clear();
        _updateUserLogsAndStats();
      }
    } else {
      // ... (No profile found logic)
      if (mounted) {
        setState(() => _isSearching = false);
        // SnackBar logic
      }
    }
  }

// 💾 ኢሜይሉን ሴቭ ማድረጊያ ረዳት ፈንክሽን
  Future<void> _saveLastSearchedEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_searched_email', email);
    debugPrint("Last searched email saved: $email");
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(_primaryColorValue);
    final Color contentColor = Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: contentColor,
        elevation: 0,
        // የ AppBar ቁመት ለፎቶውና ለስሙ እንዲበቃ 90.h አድርገነዋል
        toolbarHeight: 90.h,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, size: 22.sp),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        // 🎯 ምስሉን እና ስሙን (ርዕሱን) እዚህ title ውስጥ አዋህደነዋል
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                if (++_adminTapCount >= 7) {
                  _adminTapCount = 0;
                  _navigateTo(const AdminStatsPage());
                }
              },
              child: CircleAvatar(
                radius: 24.r, // መጠኑ ቆጥብ ያለ ነው
                backgroundColor: Colors.white24,
                backgroundImage: (userCv?.profileImagePath != null &&
                        userCv!.profileImagePath.isNotEmpty &&
                        File(userCv!.profileImagePath).existsSync())
                    ? FileImage(File(userCv!.profileImagePath))
                    : null,
                child: (userCv?.profileImagePath == null ||
                        userCv!.profileImagePath.isEmpty ||
                        !File(userCv!.profileImagePath).existsSync())
                    ? Icon(CupertinoIcons.person_fill,
                        color: Colors.white, size: 22.sp)
                    : null,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              // ስም ካለ ስሙን፣ ከሌለ ደግሞ "CV Builder Pro" ያሳያል
              (userCv?.firstName != null && userCv!.firstName.isNotEmpty)
                  ? "${userCv!.firstName} ${userCv!.lastName}"
                  : "CV Builder Pro",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.share, size: 20.sp),
            onPressed: _shareApp,
          ),
        ],
        // የ AppBarሩን የታችኛውን ጫፍ ክብ (Curved) ለማድረግ
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25.r),
            bottomRight: Radius.circular(25.r),
          ),
        ),
      ),
      drawer: _buildDrawer(primaryColor, contentColor),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ⚠️ _buildModernHeader እዚህ ጋር አያስፈልግም (ከላይ ገብቷል)
                    _buildSearchField(),
                    _buildFeatureHint(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar:
          _buildPersistentBottomNav(primaryColor, contentColor),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _emailSearchController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "Search CV by Email...",
            hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
            prefixIcon: Icon(CupertinoIcons.search,
                size: 20.sp, color: Colors.blueGrey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15.h),
            suffixIcon: _isSearching
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ))
                : IconButton(
                    icon: Icon(Icons.arrow_forward_ios,
                        size: 18.sp, color: Colors.blue),
                    onPressed: _handleProfileSearch,
                  ),
          ),
          onSubmitted: (_) => _handleProfileSearch(), // Enter ሲጫኑ እንዲፈልግ
        ),
      ),
    );
  }

  Widget _buildFeatureHint() {
    return Padding(
      padding: EdgeInsets.only(top: 60.h),
      child: Column(
        children: [
          Icon(CupertinoIcons.chevron_compact_down,
              size: 30.sp, color: Colors.blueGrey[200]),
          Text("Explore features",
              style: TextStyle(fontSize: 12.sp, color: Colors.blueGrey[400])),
        ],
      ),
    );
  }

  Widget _buildPersistentBottomNav(Color primaryColor, Color contentColor) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10.h, top: 10.h),
      decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(CupertinoIcons.house_fill, "Home", () => _refreshData(),
              active: true),
          _navItem(CupertinoIcons.paintbrush, "Design", () {
            CvModel displayData = userCv ?? _getSampleCvData();
            _navigateTo(TemplatePickerScreen(cvModel: displayData));
          }),
          _buildMainButton(primaryColor, contentColor),
          _navItem(CupertinoIcons.doc_on_doc, "Saved",
              () => _navigateTo(const SavedCvsScreen())),
          _navItem(
              CupertinoIcons.lab_flask_solid, "PDF Tools", _handlePdfToolsMenu),
        ],
      ),
    );
  }

  Widget _buildMainButton(Color primaryColor, Color contentColor) {
    return GestureDetector(
      onTap: () => _navigateTo(const MainCvForm()),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
                color: primaryColor.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(userCv == null ? Icons.add_rounded : Icons.edit_note_rounded,
                color: contentColor, size: 20.sp),
            SizedBox(width: 6.w),
            Text(userCv == null ? "CREATE" : "EDIT",
                style: TextStyle(
                    color: contentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                    letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap,
      {bool active = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: active ? Color(_primaryColorValue) : Colors.blueGrey[300],
              size: 24.sp),
          SizedBox(height: 4.h),
          Text(label,
              style: TextStyle(
                  fontSize: 10.sp,
                  color:
                      active ? Color(_primaryColorValue) : Colors.blueGrey[500],
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }

  void _handlePdfToolsMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 10.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("PDF Master Tools",
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 15.h),
              _buildDrawerItem(Icons.image, "Images to PDF", () {
                Navigator.pop(context);
                _navigateTo(const ImageToPdfScreen());
              }),
              _buildDrawerItem(Icons.merge_type, "Merge PDF", () {
                Navigator.pop(context);
                _navigateTo(const PdfMergeScreen());
              }),
              _buildDrawerItem(Icons.compress, "Compress PDF", () {
                Navigator.pop(context);
                _navigateTo(const PdfCompressScreen());
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(Color primaryColor, Color textColor) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 40.sp),
            ),
            accountName: Text(
                "${userCv?.firstName ?? 'User'} ${userCv?.lastName ?? ''}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(userCv?.email ?? "CV Builder Pro User"),
          ),
          _drawerTile(Icons.settings_outlined, "Settings",
              () => _navigateTo(const SettingsScreen())),
          _drawerTile(Icons.help_outline_rounded, "Help Center",
              () => _navigateTo(const HelpScreen())),
          _drawerTile(Icons.info_outline_rounded, "About App",
              () => _navigateTo(const AboutScreen())),
          const Spacer(),
          const Divider(indent: 20, endIndent: 20),
          _drawerTile(Icons.logout_rounded, "Sign Out", () async {
            await AuthService().signOut();
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          }, color: Colors.redAccent),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, size: 22.sp, color: color ?? Colors.blueGrey[700]),
      title: Text(title,
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.blueGrey[800])),
      onTap: onTap,
    );
  }

  void _showForceUpdateDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PopScope(
          canPop: true,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r)),
            title: const Text("Update Available"),
            content: const Text(
                "A new version is available with better features. Would you like to update now?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "NOT NOW",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              TextButton(
                  onPressed: () => _launchUpdateUrl(url),
                  child: const Text("UPDATE NOW",
                      style: TextStyle(fontWeight: FontWeight.bold)))
            ],
          )),
    );
  }

  void _launchUpdateUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareApp() async {
    await Share.share(
      "Download CV Builder Pro: https://fktfokhkelroszuzvxck.supabase.co/storage/v1/object/public/updates/CVMaker.apk",
      subject: 'Check out this CV Builder App!',
    );
  }

  CvModel _getSampleCvData() {
    CvModel sample = CvModel();

    // Basic Info
    sample.firstName = "Nahom";
    sample.lastName = "Tadesse";
    sample.jobTitle = "Full Stack Developer";
    sample.email = "nahom.tadesse@example.com";
    sample.phone = "+2519xxxxxxxx";
    sample.phone2 = "+251xxxxxxxx"; // New field
    sample.address = "Bole, Addis Ababa";
    sample.nationality = "Ethiopian"; // New field
    sample.gender = "Male"; // New field
    sample.age = "26"; // New field
    sample.linkedin = "linkedin.com/in/nahom-tadesse";
    sample.portfolio = "github.com/nahom-dev";
    sample.summary =
        "Passionate software engineer with over 5 years of experience in building scalable web and mobile applications using Flutter and Node.js. Dedicated to writing clean, maintainable code.";

    // Education (Using updated keys: school, degree, field, gradYear, cgpa, project)
    sample.education = [
      {
        "school": "Addis Ababa University",
        "degree": "BSc",
        "field": "Software Engineering",
        "gradYear": "2021",
        "cgpa": "3.85",
        "project": "AI-based Traffic Management System"
      },
    ];

    // Experience (Using updated keys: companyName, jobTitle, duration, jobDescription, achievements, isCurrentlyWorking)
    sample.experience = [
      {
        "companyName": "TechEthio Solutions",
        "jobTitle": "Senior Flutter Developer",
        "duration": "2022 - Present",
        "jobDescription":
            "Leading a team of 5 developers to build a nationwide fintech application.",
        "achievements":
            "Reduced app load time by 40% using optimized state management.",
        "isCurrentlyWorking": 1 // 1 for true
      },
      {
        "companyName": "Global Systems",
        "jobTitle": "Junior Developer",
        "duration": "2021 - 2022",
        "jobDescription":
            "Developed and maintained various client websites using React.",
        "achievements": "Awarded Employee of the Month twice.",
        "isCurrentlyWorking": 0 // 0 for false
      },
    ];

    // Skills (name, level)
    sample.skills = [
      {"name": "Flutter & Dart", "level": "Expert"},
      {"name": "Firebase", "level": "Advanced"},
      {"name": "Node.js", "level": "Intermediate"},
      {"name": "PostgreSQL", "level": "Intermediate"},
    ];

    // Certificates (certName, organization, year)
    sample.certificates = [
      {
        "certName": "Google Professional Cloud Architect",
        "organization": "Google",
        "year": "2023"
      },
      {
        "certName": "Mobile App Security",
        "organization": "Udemy",
        "year": "2022"
      },
    ];

    // Languages (name, level)
    sample.languages = [
      {"name": "Amharic", "level": "Native"},
      {"name": "English", "level": "Fluent"},
    ];

    // References (name, job, organization, phone, email)
    sample.user_references = [
      {
        "name": "Dr. Elias Solomon",
        "job": "Technical Director",
        "organization": "TechEthio Solutions",
        "phone": "+2519xxxxxxxx",
        "email": "elias.s@techethio.com"
      },
    ];

    return sample;
  }
}
