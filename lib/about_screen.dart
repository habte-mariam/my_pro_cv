import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ScreenUtil ተጨምሯል
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isChecking = false;
  bool _isLaunching = false;

  Future<void> _checkUpdateWithSupabase() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // Key Names (min_version_code, update_url) አልተቀየሩም
      final response = await Supabase.instance.client
          .from('app_settings')
          .select()
          .or('key.eq.min_version_code,key.eq.update_url');

      final settings = {for (var item in response) item['key']: item['value']};

      int latestVersion = int.parse(settings['min_version_code'] ?? '0');
      String updateUrl = settings['update_url'] ?? '';

      final info = await PackageInfo.fromPlatform();
      int currentBuildNumber = int.parse(info.buildNumber);

      if (!mounted) return;

      if (latestVersion > currentBuildNumber) {
        _showForceUpdateDialog(context, updateUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("App is up to date!", style: TextStyle(fontSize: 14.sp)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar("Failed to check updates: $e");
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _launchUpdateUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar("Could not launch the update URL.");
      }
    } catch (e) {
      _showErrorSnackBar("An error occurred: $e");
    }
  }

  void _showForceUpdateDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r)),
            title: Row(
              children: [
                Icon(Icons.system_update, color: Colors.indigo, size: 24.sp),
                SizedBox(width: 10.w),
                Text("Required Update",
                    style: TextStyle(
                        fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              "A critical update is available. You must update the app to continue using its services.",
              style: TextStyle(fontSize: 15.sp),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                    onPressed: _isLaunching
                        ? null
                        : () async {
                            setState(() => _isLaunching = true);
                            await _launchUpdateUrl(url);
                            if (mounted) setState(() => _isLaunching = false);
                          },
                    child: Text("UPDATE NOW",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("About App",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 80.sp, color: Colors.indigo),
              SizedBox(height: 20.h),
              Text("CV Maker Pro",
                  style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[900])),
              SizedBox(height: 10.h),
              Text("Version 1.0.0",
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
              SizedBox(height: 40.h),
              _isChecking
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _checkUpdateWithSupabase,
                      icon: Icon(Icons.cloud_download, size: 20.sp),
                      label: Text("Check for Updates",
                          style: TextStyle(fontSize: 16.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s, style: TextStyle(fontSize: 14.sp)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
