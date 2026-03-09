import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'main.dart'; // appSettingsNotifier ን ለማግኘት

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentTheme = 0xFF1E293B;
  String _fontSize = "Medium";
  String _fontFamily = "JetBrains Mono";
  bool _isLoading = true;

  final List<int> _themeOptions = [
    0xFF15803D,
    0xFF0284C7,
    0xFFB9F2FF,
    0xFFB91C1C,
    0xFF7E22CE,
    0xFF000000,
    0xFF70D1F4,
    0xFFF97316,
    0xFF1A237E,
    0xFF374151,
    0xFF065F46,
    0xFF9D174D,
  ];

  final List<String> _fontOptions = [
    "JetBrains Mono",
    "Times",
    "Poppins",
    "Arimo",
    "NotoSerif"
  ];

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final s = await DatabaseHelper.instance.getSettings();
      if (mounted) {
        setState(() {
          _currentTheme = s['themeColor'] ?? 0xFF1E293B;
          _fontSize = s['fontSize'] ?? "Medium";
          String savedFont = s['fontFamily'] ?? "JetBrains Mono";
          if (savedFont == "Times New Roman") savedFont = "Times";
          _fontFamily = savedFont;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings(
      {int? theme, String? fSize, String? fFamily}) async {
    final newTheme = theme ?? _currentTheme;
    final newFont = fFamily ?? _fontFamily;
    final newSize = fSize ?? _fontSize;

    await DatabaseHelper.instance.saveSettings({
      'themeColor': newTheme,
      'fontSize': newSize,
      'fontFamily': newFont,
    });

    // አፑ በአዲስ ቀለም እና ፎንት እንዲታደስ ለ notifier መናገር
    appSettingsNotifier.value = {
      'themeColor': newTheme,
      'fontFamily': newFont,
      'fontSize': newSize, // FontSize ጭምር ማሳወቅ ከተፈለገ
    };

    if (mounted) {
      _showToast("Settings Updated!");
      _fetchSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isLightColor = _currentTheme == 0xFFB9F2FF;
    final Color primaryColor = Color(_currentTheme);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Settings",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                fontFamily: _fontFamily)),
        backgroundColor: primaryColor,
        foregroundColor: isLightColor ? Colors.black87 : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _buildHeader("DESIGN & THEME", primaryColor),
          _buildThemeSelector(),
          const SizedBox(height: 10),
          _buildHeader("TYPOGRAPHY", primaryColor),
          _buildSettingCard(
            icon: Icons.format_size_rounded,
            title: "Font Size",
            subtitle: "Current: $_fontSize",
            trailing: DropdownButton<String>(
              value: _fontSize,
              underline: const SizedBox(),
              style: TextStyle(color: Colors.black87, fontFamily: _fontFamily),
              onChanged: (v) => _updateSettings(fSize: v),
              items: ["Small", "Medium", "Large"]
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
            ),
          ),
          _buildSettingCard(
            icon: Icons.font_download_rounded,
            title: "Font Family",
            subtitle: "Current: $_fontFamily",
            trailing: DropdownButton<String>(
              value: _fontOptions.contains(_fontFamily)
                  ? _fontFamily
                  : _fontOptions[0],
              underline: const SizedBox(),
              style: TextStyle(color: Colors.black87, fontFamily: _fontFamily),
              onChanged: (v) => _updateSettings(fFamily: v),
              items: _fontOptions
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f, style: TextStyle(fontFamily: f)),
                      ))
                  .toList(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Divider(),
          ),
          _buildHeader("DATA MANAGEMENT", Colors.redAccent),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child:
                  const Icon(Icons.delete_forever_rounded, color: Colors.red),
            ),
            title: Text("Reset",
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontFamily: _fontFamily)),
            subtitle: const Text("Clear all CV data and reset settings"),
            onTap: () => _showResetDialog(),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text("App Version 1.0.0",
                style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontFamily: _fontFamily)),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: _fontFamily,
              letterSpacing: 1.1)),
    );
  }

  Widget _buildSettingCard(
      {required IconData icon,
      required String title,
      required String subtitle,
      required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey[600]),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                fontFamily: _fontFamily)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontFamily: _fontFamily)),
        trailing: trailing,
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Wrap(
        spacing: 15,
        runSpacing: 15,
        children: _themeOptions.map((colorValue) {
          bool isSelected = _currentTheme == colorValue;
          return GestureDetector(
            onTap: () => _updateSettings(theme: colorValue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(colorValue),
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? Colors.orange : Colors.transparent,
                    width: 3),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                        color: Color(colorValue).withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 2)
                ],
              ),
              child: isSelected
                  ? Icon(Icons.check,
                      color: colorValue == 0xFFB9F2FF
                          ? Colors.black
                          : Colors.white)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title:
            Text("Reset App Data?", style: TextStyle(fontFamily: _fontFamily)),
        content: Text(
            "This action will delete all your saved CVs and preferences. Are you sure?",
            style: TextStyle(fontFamily: _fontFamily)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                // 1. ዳታቤዙን ማጽዳት
                await DatabaseHelper.instance.clearAll();

                // 2. የአፑን ገጽታ (Theme) ወዲያውኑ ወደ መጀመሪያው ሁኔታ መመለስ
                // ይህ ካልተደረገ Settings ገጹ ላይ የነበረው Theme አይቀየርም
                appSettingsNotifier.value = {
                  'themeColor': 0xFF1E293B, // Default Slate color
                  'fontFamily': 'JetBrains Mono',
                  'fontSize': 'Medium',
                  'templateIndex': 0,
                };

                if (context.mounted) Navigator.pop(context);
                if (!mounted) return;

                _fetchSettings();

                _showToast("All data cleared & settings reset! ✅");
              },
              child: const Text("RESET EVERYTHING")),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: TextStyle(fontFamily: _fontFamily)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating));
  }
}
