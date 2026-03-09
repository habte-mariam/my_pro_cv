import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../cv_model.dart';
import '../app_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../main.dart';
import '../database_helper.dart';

class SkillForm extends StatefulWidget {
  final CvModel cv;
  final VoidCallback? onDataChanged;

  const SkillForm({super.key, required this.cv, this.onDataChanged});

  @override
  State<SkillForm> createState() => _SkillsFormState();
}

class _SkillsFormState extends State<SkillForm> {
  final TextEditingController _customSkillController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSaving = false;

  // እዚህ ጋር ባዶ እንዲሆን ተደርጓል
  String _selectedSkillLevel = "";
  String? _selectedCategory;
  final List<String> _skillLevels = [
    "Beginner",
    "Elementary",
    "Intermediate",
    "Advanced",
    "Expert"
  ];

  @override
  void dispose() {
    _customSkillController.dispose();
    super.dispose();
  }

  Future<void> _saveSkillsToDb() async {
    setState(() => _isSaving = true);
    try {
      final db = DatabaseHelper.instance;
      await DatabaseHelper.instance.clearSkills(widget.cv.id);

      for (var skill in widget.cv.skills) {
        await db.addSkill({
          'profileid': widget.cv.id,
          'name': skill['name'],
          'level': skill['level'] ?? "",
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Skills saved successfully!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving skills: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  double? getLevelProgress(String? level) {
    if (level == null || level.isEmpty) return null;

    switch (level.trim()) {
      case "Beginner":
        return 0.2; // 20%
      case "Elementary":
        return 0.4; // 40%
      case "Intermediate":
        return 0.6; // 60%
      case "Advanced":
        return 0.8; // 80%
      case "Expert":
        return 1.0; // 100%
      default:
        return null;
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (!mounted) return;
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) =>
              setState(() => _customSkillController.text = val.recognizedWords),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _addCustomSkill() {
    String skillName = _customSkillController.text.trim();
    if (skillName.isNotEmpty) {
      setState(() {
        widget.cv.skills
            .insert(0, {'name': skillName, 'level': _selectedSkillLevel});
        _customSkillController.clear();
        _selectedSkillLevel = ""; // ለቀጣዩ እንዲመች መልሶ ባዶ ማድረግ
      });
      if (widget.onDataChanged != null) widget.onDataChanged!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = appSettingsNotifier.value;
    final Color themeColor = Color(settings['themeColor']);
    final String fontFamily = settings['fontFamily'];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("My Skills (${widget.cv.skills.length})",
                    Icons.star_rounded, themeColor, fontFamily),
                SizedBox(height: 10.h),
                _buildSkillList(themeColor, fontFamily),
                SizedBox(height: 20.h),

                // --- ይሄ ነው ዋናው አንድ ሳጥን (One Box) ---
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: _iphoneCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Add New Skill",
                          Icons.add_circle_outline, themeColor, fontFamily),
                      SizedBox(height: 12.h),

                      // 1. ካቴጎሪ መምረጫው
                      _buildCategoryDropdown(themeColor, fontFamily),

                      // 2. ካቴጎሪ ሲመረጥ ብቻ ዝርዝሩ ወዲያውኑ ይታያል
                      if (_selectedCategory != null) ...[
                        SizedBox(height: 10.h),
                        _buildSkillSelectionList(themeColor, fontFamily),
                      ],

                      SizedBox(height: 15.h),
                      _buildCustomInputRow(themeColor, fontFamily),
                      SizedBox(height: 12.h),
                      _buildPickerTrigger(
                          "Proficiency",
                          _selectedSkillLevel.isEmpty
                              ? "Not Selected"
                              : _selectedSkillLevel,
                          () => _showLevelPicker(context),
                          themeColor,
                          fontFamily),

                      // ቢያንስ አንድ ስኪል ካለ የሴቭ ቁልፉ እዚሁ ሳጥን ውስጥ ይታያል
                      if (widget.cv.skills.isNotEmpty) ...[
                        SizedBox(height: 20.h),
                        const Divider(),
                        SizedBox(height: 10.h),
                        _buildSaveButtonInside(themeColor),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

// 1. የካቴጎሪ መምረጫ ሜተድ
  Widget _buildCategoryDropdown(Color themeColor, String fontFamily) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          hint: const Text("First Select Category"),
          items: AppConstants.categorizedSkills.keys
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
        ),
      ),
    );
  }

// 2. የስኪል ዝርዝር በCheckbox (Scrollable)
  Widget _buildSkillSelectionList(Color themeColor, String fontFamily) {
    final List<String> skillsInCategory =
        AppConstants.categorizedSkills[_selectedCategory]!;

    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: RawScrollbar(
        thumbColor: themeColor.withValues(alpha: 0.4),
        thickness: 4.w,
        radius: Radius.circular(20.r),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: skillsInCategory.length,
          itemBuilder: (context, index) {
            final skill = skillsInCategory[index];
            bool isSelected = widget.cv.skills.any((e) => e['name'] == skill);

            return CheckboxListTile(
              title: Text(skill, style: TextStyle(fontSize: 13.sp)),
              value: isSelected,
              activeColor: themeColor,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    widget.cv.skills.add({
                      'name': skill,
                      'level': _selectedSkillLevel.isEmpty
                          ? "Intermediate"
                          : _selectedSkillLevel
                    });
                  } else {
                    widget.cv.skills.removeWhere((e) => e['name'] == skill);
                  }
                });
                if (widget.onDataChanged != null) widget.onDataChanged!();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkillList(Color themeColor, String fontFamily) {
    if (widget.cv.skills.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Text("No skills added yet.",
              style: TextStyle(fontFamily: fontFamily, color: Colors.grey)),
        ),
      );
    }

    return Wrap(
      spacing: 12.w, // ክፍተቱን ትንሽ ሰፋ አድርገነዋል
      runSpacing: 12.h,
      children: widget.cv.skills.asMap().entries.map((entry) {
        String level = entry.value['level'] ?? "";
        double? progress = getLevelProgress(level);

        // Expert (1.0) ከሆነ የተለየ ቀለም (ለምሳሌ አረንጓዴ) መጠቀም ትችላለህ
        Color progressColor = (progress == 1.0) ? Colors.green : themeColor;

        return Container(
          width: 160.w, // ለጽሁፎች ሰፊ ቦታ እንዲኖር
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r), // ይበልጥ የተጠጋጋ ጠርዝ
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: themeColor.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(entry.value['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                            fontFamily: fontFamily)),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => widget.cv.skills.removeAt(entry.key));
                      if (widget.onDataChanged != null) widget.onDataChanged!();
                    },
                    child:
                        Icon(Icons.cancel, size: 18.sp, color: Colors.red[300]),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              if (level.isNotEmpty) ...[
                Text(level,
                    style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: progressColor,
                        fontFamily: fontFamily)),
                SizedBox(height: 6.h),
                ClipRRect(
                  // ባሩ ጫፉ እንዲጠጋጋ (Rounded እንዲሆን)
                  borderRadius: BorderRadius.circular(10.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6.h, // ባሩን ትንሽ ወፈር አድርገነዋል
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ] else
                SizedBox(height: 14.h),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomInputRow(Color themeColor, String fontFamily) => Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _customSkillController,
              padding: EdgeInsets.all(12.w),
              placeholder: "Custom Skill...",
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12.r),
              ),
              suffix: IconButton(
                icon: Icon(_isListening ? Icons.stop : Icons.mic,
                    color: themeColor),
                onPressed: _listen,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
              onPressed: _addCustomSkill,
              icon: Icon(Icons.add_circle, color: themeColor, size: 35.sp)),
        ],
      );

  void _showLevelPicker(BuildContext context) {
    int initialItem = _skillLevels.indexOf(_selectedSkillLevel);
    if (initialItem == -1) initialItem = 0;

    String tempSelected = _selectedSkillLevel.isEmpty
        ? _skillLevels[initialItem]
        : _selectedSkillLevel;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250.h,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Header
            Container(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("Clear",
                        style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      setState(() => _selectedSkillLevel = "");
                      Navigator.pop(context);
                    },
                  ),
                  Text("Select Level",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      )),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("Done",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() => _selectedSkillLevel = tempSelected);
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            ),
            // Picker
            Expanded(
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: initialItem),
                itemExtent: 45.h,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                onSelectedItemChanged: (i) {
                  // እዚህ ጋር ነው Haptic Feedback የሚጨመረው
                  HapticFeedback.selectionClick();
                  tempSelected = _skillLevels[i];
                },
                children: _skillLevels
                    .map((l) => Center(
                          child: Text(
                            l,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ይህንን ኮድ በክላሱ መጨረሻ አካባቢ ጨምረው
  Widget _buildSaveButtonInside(Color themeColor) {
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : _saveSkillsToDb,
      icon: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.cloud_upload_outlined),
      label: Text(_isSaving ? "Saving..." : "SAVE ALL SKILLS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp)),
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 48.h),
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  Widget _buildSectionHeader(
          String title, IconData icon, Color themeColor, String fontFamily) =>
      Row(children: [
        Icon(icon, color: themeColor, size: 22.sp),
        SizedBox(width: 8.w),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                fontFamily: fontFamily))
      ]);

  BoxDecoration _iphoneCardDecoration() => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
          ]);

  Widget _buildPickerTrigger(String label, String value, VoidCallback onTap,
          Color themeColor, String fontFamily) =>
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12.r)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey[600])),
                    Row(
                      children: [
                        Text(value,
                            style: TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.bold)),
                        Icon(Icons.arrow_drop_down, color: themeColor),
                      ],
                    )
                  ])));
}
