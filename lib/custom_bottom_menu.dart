import 'package:flutter/material.dart';
import 'package:my_new_cv/forms/main_cv_form.dart';
import 'cv_model.dart';
import 'database_helper.dart';
import 'cv_preview_screen.dart';
import 'templates/template_picker_screen.dart';
import 'saved_cvs_screen.dart';

class CustomBottomMenu extends StatelessWidget {
  final CvModel? userCv;
  final Color primaryColor;
  final Color contentColor;
  final Function? onRefresh;

  const CustomBottomMenu({
    super.key,
    required this.userCv,
    required this.primaryColor,
    required this.contentColor,
    this.onRefresh,
  });

  Future<void> _navigateTo(BuildContext context, Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    // ከሄድንበት ገጽ ስንመለስ ዳታው እንዲታደስ
    if (onRefresh != null) onRefresh!();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, Icons.home_rounded, "Home", () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }),
              _navItem(context, Icons.palette_rounded, "Design", () {
                if (userCv != null) {
                  _navigateTo(context, TemplatePickerScreen(cvModel: userCv!));
                } else {
                  _showWarning(context, "Please enter your details first!");
                }
              }),

              // ማዕከላዊ ቁልፍ (ወደ Wizard የሚወስድ)
              _buildCenterButton(context),

              _navItem(context, Icons.folder_copy_rounded, "Saved",
                  () => _navigateTo(context, const SavedCvsScreen())),

              _navItem(context, Icons.visibility_rounded, "Preview", () async {
                if (userCv != null) {
                  final settings = await DatabaseHelper.instance.getSettings();
                  if (!context.mounted) return;
                  _navigateTo(
                      context,
                      CvPreviewScreen(
                        cvModel: userCv!,
                        templateIndex: settings['templateIndex'] ?? 0,
                        primaryColor:
                            Color(settings['themeColor'] ?? 0xFF1E293B),
                      ));
                } else {
                  _showWarning(context, "Please enter your details first!");
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context) {
    return GestureDetector(
      // እዚህ ጋር ወደ አዲሱ MainCvForm እንዲሄድ ተቀይሯል
      onTap: () => _navigateTo(context, const MainCvForm()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: primaryColor.withValues(),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                userCv == null
                    ? Icons.add_circle_outline
                    : Icons.auto_fix_high_rounded,
                color: contentColor,
                size: 20),
            const SizedBox(width: 6),
            Text(
              userCv == null ? "START" : "EDIT",
              style: TextStyle(
                  color: contentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blueGrey.shade400, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.blueGrey.shade700,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showWarning(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.orange.shade800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}
