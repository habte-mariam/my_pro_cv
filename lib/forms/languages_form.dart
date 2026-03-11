import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/cupertino.dart';
import '../cv_model.dart';
import '../app_constants.dart';
import '../main.dart';
import '../database_helper.dart'; // ዳታቤዝ ለመጠቀም

class LanguagesForm extends StatefulWidget {
  final CvModel cv;
  final VoidCallback? onDataChanged;

  const LanguagesForm({super.key, required this.cv, this.onDataChanged});

  @override
  State<LanguagesForm> createState() => _LanguagesFormState();
}

class _LanguagesFormState extends State<LanguagesForm> {
  final TextEditingController _customLanguageController =
      TextEditingController();
  String _selectedLangLevel = AppConstants.languageLevels[1]; // Intermediate
  bool _isSaving = false;

  @override
  void dispose() {
    _customLanguageController.dispose();
    super.dispose();
  }

  // ዳታውን ወደ ዳታቤዝ የማስቀመጫ ተግባር
  Future<void> _saveLanguagesToDb() async {
    setState(() => _isSaving = true);
    try {
      final db = DatabaseHelper.instance;
      // 1. መጀመሪያ በሊስቱ ያለውን የድሮ ዳታ አጥፋ (Profile ID 1 እንደሆነ በማሰብ)
      await DatabaseHelper.instance.clearLanguages(widget.cv.profileid);

      // 2. አሁን ያሉትን ቋንቋዎች በሙሉ አንድ በአንድ አስገባ
      for (var lang in widget.cv.languages) {
        await db.addLanguage({
          'profileid': widget.cv.profileid,
          'name': lang['name'],
          'level': lang['level'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Languages saved successfully!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error saving languages: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addLanguage() {
    String langName = _customLanguageController.text.trim();
    if (langName.isNotEmpty) {
      bool exists = widget.cv.languages
          .any((l) => l['name'].toLowerCase() == langName.toLowerCase());
      if (!exists) {
        setState(() {
          widget.cv.languages
              .add({'name': langName, 'level': _selectedLangLevel});
          _customLanguageController.clear();
        });
        if (widget.onDataChanged != null) widget.onDataChanged!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = appSettingsNotifier.value;
    final Color themeColor = Color(settings['themeColor']);
    final String fontFamily = settings['fontFamily'];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // ከላይ እንዲጀምር
        crossAxisAlignment: CrossAxisAlignment.start, // ወደ ግራ እንዲለጠፍ
        children: [
          _buildSectionHeader("Languages (${widget.cv.languages.length})",
              Icons.language, themeColor, fontFamily),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: _iphoneCardDecoration(),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              controller: _customLanguageController,
                              placeholder: "Search language",
                              placeholderStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13.sp,
                                  fontFamily: fontFamily),
                              style: TextStyle(
                                  color: Colors.black, fontFamily: fontFamily),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: null,
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              icon: Icon(Icons.expand_more, color: themeColor),
                              items: AppConstants.commonLanguages
                                  .map((String lang) {
                                return DropdownMenuItem<String>(
                                  value: lang,
                                  child: Text(lang,
                                      style: TextStyle(
                                          fontSize: 13.sp,
                                          fontFamily: fontFamily)),
                                );
                              }).toList(),
                              onChanged: (newValue) => setState(() =>
                                  _customLanguageController.text = newValue!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _addLanguage,
                    child: CircleAvatar(
                        backgroundColor: themeColor,
                        child: const Icon(Icons.add, color: Colors.white)),
                  ),
                ]),
                SizedBox(height: 12.h),
                _buildPickerTrigger("Proficiency Level", _selectedLangLevel,
                    () => _showLevelPicker(context), themeColor, fontFamily),
                SizedBox(height: 15.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: widget.cv.languages
                      .asMap()
                      .entries
                      .map((entry) => Chip(
                            label: Text(
                                "${entry.value['name']} - ${entry.value['level']}",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontFamily: fontFamily)),
                            onDeleted: () {
                              setState(() =>
                                  widget.cv.languages.removeAt(entry.key));
                              if (widget.onDataChanged != null) {
                                widget.onDataChanged!();
                              }
                            },
                            backgroundColor: themeColor,
                            deleteIconColor: Colors.white70,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                          ))
                      .toList(),
                ),
                if (widget.cv.languages.isNotEmpty) ...[
                  SizedBox(height: 20.h),
                  const Divider(),
                  SizedBox(height: 10.h),
                  // Save Button በካርዱ ውስጥ እንዲሆን
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveLanguagesToDb,
                    icon: _isSaving
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? "Saving..." : "Save Languages",
                        style: TextStyle(
                            fontFamily: fontFamily,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 45.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 100.h), // ለስክሮል እንዲመች
        ],
      ),
    );
  }

  // ---------------- Helper Widgets ----------------

  void _showLevelPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250.h,
        color: Colors.white,
        child: Column(
          children: [
            _buildPickerHeader(context),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40.h,
                scrollController: FixedExtentScrollController(
                  initialItem:
                      AppConstants.languageLevels.indexOf(_selectedLangLevel),
                ),
                onSelectedItemChanged: (index) => setState(() =>
                    _selectedLangLevel = AppConstants.languageLevels[index]),
                children: AppConstants.languageLevels
                    .map((l) => Center(child: Text(l)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, Color themeColor, String fontFamily) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(children: [
        Icon(icon, color: themeColor, size: 18.sp),
        SizedBox(width: 8.w),
        Text(title,
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: fontFamily,
                color: themeColor)),
      ]),
    );
  }

  Widget _buildPickerHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      color: Colors.grey[100],
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        CupertinoButton(
            child: const Text("Done"), onPressed: () => Navigator.pop(context))
      ]),
    );
  }

  Widget _buildPickerTrigger(String label, String value, VoidCallback onTap,
      Color themeColor, String fontFamily) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.grey[300]!)),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12.sp,
                  fontFamily: fontFamily)),
          Row(children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                    fontFamily: fontFamily,
                    fontSize: 12.sp)),
            Icon(Icons.arrow_drop_down, color: themeColor),
          ]),
        ]),
      ),
    );
  }

  BoxDecoration _iphoneCardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      );
}
