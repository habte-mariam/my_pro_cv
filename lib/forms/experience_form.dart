import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/cupertino.dart';
import '../cv_model.dart';
import '../database_helper.dart';
import '../ai_service.dart';
import '../main.dart';

class ExperienceForm extends StatefulWidget {
  final CvModel cv;
  final VoidCallback? onDataChanged;

  const ExperienceForm({super.key, required this.cv, this.onDataChanged});

  @override
  State<ExperienceForm> createState() => _ExperienceFormState();
}

class _ExperienceFormState extends State<ExperienceForm> {
  final Map<String, TextEditingController> _controllers = {};
  String? _activeAiKey;
  bool _isSaving = false;

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _notifyChange() {
    if (widget.onDataChanged != null) widget.onDataChanged!();
  }

  void _addExperience() {
    setState(() {
      widget.cv.experience = List.from(widget.cv.experience)
        ..add(<String, dynamic>{
          'companyName': '',
          'jobTitle': '',
          'startDate': 'Select Date',
          'endDate': 'Select Date',
          'duration': '',
          'jobDescription': '',
          'achievements': '',
          'isCurrentlyWorking': 0,
        });
    });
    _notifyChange();
  }

  Future<void> _generateAIContent(
      Map<String, dynamic> exp, String fieldKey, int index) async {
    final String currentFieldKey = "exp_${index}_$fieldKey";
    if (_activeAiKey == currentFieldKey) return;

    final String jobTitle = exp['jobTitle']?.toString() ?? "";
    final String company = exp['companyName']?.toString() ?? "a company";

    if (jobTitle.isEmpty) {
      _showSnackBar("Please enter a Job Title first.", Colors.orange);
      return;
    }

    String taskInstruction = fieldKey == 'achievements'
        ? "Briefly describe 2 genuine career wins as a $jobTitle. Write it like a professional sharing a real success story in a conversation, avoiding all AI buzzwords. Be humble but impactful. Limit to 2-3 lines total."
        : "In 2 natural sentences, explain how you actually made a difference as a $jobTitle. Focus on the human side of your work and real daily impact. Avoid formal robotic clichés. Keep it strictly under 3 lines.";

    String contextData = "Job Title: $jobTitle, Company: $company";

    try {
      if (mounted) setState(() => _activeAiKey = currentFieldKey);

      bool isAmharicInput = RegExp(r'[\u1200-\u137F]').hasMatch(jobTitle);

      String result = await AIService.askAI(
        contextData,
        customPrompt: taskInstruction,
        isAmharic: isAmharicInput,
      );

      if (mounted && result.isNotEmpty) {
        // AIው "Here is..." ብሎ ቢጀምር እንኳን እንዲቆርጠው የ AIService ማጽጃን ይጠቀማል
        final String fullText = result.trim();

        final String controllerKey = "exp_${index}_$fieldKey";
        final controller = _controllers[controllerKey];

        String currentText = "";
        // ለፈጣን Typewriter Effect በየ 5 ካራክተሩ መጻፍ
        for (int i = 0; i < fullText.length; i += 5) {
          int end = (i + 5 < fullText.length) ? i + 5 : fullText.length;
          await Future.delayed(const Duration(milliseconds: 10));

          if (!mounted) return;
          currentText += fullText.substring(i, end);

          setState(() {
            exp[fieldKey] = currentText;
            if (controller != null) {
              controller.text = currentText;
              controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length));
            }
          });
        }
        _notifyChange();
      }
    } catch (e) {
      _showSnackBar("AI error occurred.", Colors.red);
    } finally {
      if (mounted) setState(() => _activeAiKey = null);
    }
  }

  void _selectDate(BuildContext context, Map<String, dynamic> exp, String key) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250.h,
        color: Colors.white,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: DateTime.now(),
                onDateTimeChanged: (DateTime newDate) {
                  setState(() {
                    String formatted =
                        "${_getMonthName(newDate.month)} ${newDate.year}";
                    exp[key] = formatted;
                    _updateDuration(exp);
                  });
                  _notifyChange();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDuration(Map<String, dynamic> exp) {
    String start = exp['startDate'] ?? '';
    String end =
        (exp['isCurrentlyWorking'] == 1) ? 'Present' : (exp['endDate'] ?? '');
    if (start != 'Select Date' && end.isNotEmpty) {
      exp['duration'] = "$start - $end";
    }
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  Future<void> _saveToDatabase() async {
    final profileData = await DatabaseHelper.instance.getFullProfile();

    if (profileData == null) {
      _showSnackBar("Please save your Personal Info first!", Colors.red);
      return;
    }

// ትክክለኛውን ID ከዳታቤዝ ያገኛል

    setState(() => _isSaving = true);
    try {
      await DatabaseHelper.instance.clearExperience(widget.cv.id);
      for (var exp in widget.cv.experience) {
        Map<String, dynamic> data = Map.from(exp);
        data['profileid'] = widget.cv.id;
        await DatabaseHelper.instance.addExperience(data);
      }
      _showSnackBar("Experience Saved Successfully!", Colors.green);
    } catch (e) {
      _showSnackBar("Database Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = Color(appSettingsNotifier.value['themeColor']);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
                "Work Experience", _addExperience, Icons.work, themeColor),
            SizedBox(height: 15.h),
            if (widget.cv.experience.isEmpty)
              _buildEmptyState(
                  "No experience added yet.", themeColor, _addExperience),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cv.experience.length,
              itemBuilder: (context, index) {
                final exp = widget.cv.experience[index];
                return _buildExperienceCard(exp, index, themeColor);
              },
            ),
            SizedBox(height: 30.h),
            _buildSaveButton(themeColor),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceCard(
      Map<String, dynamic> exp, int index, Color themeColor) {
    bool isCurrent = exp['isCurrentlyWorking'] == 1;
    final descKey = "exp_${index}_jobDescription";
    final achKey = "exp_${index}_achievements";

    _controllers.putIfAbsent(
        descKey, () => TextEditingController(text: exp['jobDescription']));
    _controllers.putIfAbsent(
        achKey, () => TextEditingController(text: exp['achievements']));

    InputDecoration _buildInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: themeColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Experience #${index + 1}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                      fontSize: 14.sp)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  setState(() => widget.cv.experience.removeAt(index));
                  _notifyChange();
                },
              )
            ],
          ),
          const Divider(),
          SizedBox(height: 10.h),

          _buildCustomTextField("Company Name", exp['companyName'], (v) {
            exp['companyName'] = v;
            _notifyChange();
          }, _buildInputDecoration),

          _buildCustomTextField("Job Title", exp['jobTitle'], (v) {
            exp['jobTitle'] = v;
            _notifyChange();
          }, _buildInputDecoration),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10.r),
            ),
            margin: EdgeInsets.only(bottom: 12.h),
            child: SwitchListTile(
              title: Text("Currently working here",
                  style:
                      TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
              value: isCurrent,
              activeColor: themeColor,
              onChanged: (val) {
                setState(() {
                  exp['isCurrentlyWorking'] = val ? 1 : 0;
                  if (val) exp['endDate'] = 'Present';
                  _updateDuration(exp);
                });
                _notifyChange();
              },
            ),
          ),

          Row(
            children: [
              Expanded(
                child: _buildDatePickerBox("Start Date", exp['startDate'],
                    () => _selectDate(context, exp, 'startDate')),
              ),
              if (!isCurrent) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildDatePickerBox("End Date", exp['endDate'],
                      () => _selectDate(context, exp, 'endDate')),
                ),
              ],
            ],
          ),
          SizedBox(height: 15.h),

          // Job Description - እዚህ ጋር controller ተጨምሯል
          _buildCustomTextField(
            "Job Description",
            exp['jobDescription'],
            (v) {
              exp['jobDescription'] = v;
              _notifyChange();
            },
            _buildInputDecoration,
            maxLines: 4,
            controller: _controllers[descKey], // የ AI ጽሁፍ እንዲታይ
          ),
// Job Description AI Button
          _buildAIButton(
            () => _generateAIContent(exp, 'jobDescription', index),
            themeColor,
            descKey, // 👈 ይህንን ጨምር (የመጀመሪያው በተን መለያ)
          ),

          SizedBox(height: 12.h),

          // Key Achievements
          _buildCustomTextField(
            "Key Achievements",
            exp['achievements'],
            (v) {
              exp['achievements'] = v;
              _notifyChange();
            },
            _buildInputDecoration,
            maxLines: 3,
            controller: _controllers[achKey],
          ),

          // Achievements AI Button
          _buildAIButton(
            () => _generateAIContent(exp, 'achievements', index),
            themeColor,
            achKey, // 👈 ይህንን ጨምር (የሁለተኛው በተን መለያ)
          ),
        ],
      ),
    );
  }

// ወጥ የሆነ TextField ለሁሉም ቦታ
  Widget _buildCustomTextField(String label, String value,
      Function(String) onChanged, Function decorationFn,
      {int maxLines = 1, TextEditingController? controller}) {
    // controller እዚህ ጋር ተቀባይ ሆኗል
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? value : null,
        maxLines: maxLines,
        style: TextStyle(fontSize: 14.sp),
        decoration: decorationFn(label),
        onChanged: onChanged,
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildHeader(
      String title, VoidCallback onAdd, IconData icon, Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(icon, color: themeColor),
          SizedBox(width: 8.w),
          Text(title,
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: themeColor)),
        ]),
        IconButton(
            onPressed: onAdd,
            icon: Icon(Icons.add_circle, color: themeColor, size: 30.sp)),
      ],
    );
  }

  Widget _buildDatePickerBox(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAIButton(
      VoidCallback onPressed, Color themeColor, String fieldKey) {
    // 1. ይህ በተን አሁን እየጻፈ መሆኑን ለማወቅ ስሙን እናመሳክራለን
    bool isThisActive = _activeAiKey == fieldKey;
    // 2. ማንኛውም AI እየሰራ መሆኑን ለማወቅ
    bool isAnyAiRunning = _activeAiKey != null;

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        // ማንኛውም AI እየጻፈ ከሆነ በተኑ አይነካም
        onPressed: isAnyAiRunning ? null : onPressed,
        icon: isThisActive
            ? SizedBox(
                width: 15.w,
                height: 15.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                ))
            : Icon(Icons.auto_awesome,
                size: 16.sp, color: isAnyAiRunning ? Colors.grey : themeColor),
        label: Text(
          isThisActive ? "AI is writing..." : "AI Write",
          style: TextStyle(
            color: isAnyAiRunning ? Colors.grey : themeColor,
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(30.w),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(children: [
          Icon(Icons.add_business_outlined, color: color, size: 40.sp),
          Text(msg, style: TextStyle(color: color)),
        ]),
      ),
    );
  }

  Widget _buildSaveButton(Color themeColor) {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveToDatabase,
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        minimumSize: Size(double.infinity, 55.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
      child: _isSaving
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Save Experience Details",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
