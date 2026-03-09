import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../cv_model.dart';
import '../ai_service.dart';
import '../main.dart';
import '../database_helper.dart';

class ReferenceForm extends StatefulWidget {
  final CvModel cv;
  final VoidCallback? onDataChanged;

  const ReferenceForm({super.key, required this.cv, this.onDataChanged});

  @override
  State<ReferenceForm> createState() => _ReferenceFormState();
}

class _ReferenceFormState extends State<ReferenceForm> {
  bool _isAiLoading = false;
  bool _isSaving = false;
  late TextEditingController _summaryController;

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController(text: widget.cv.summary);
  }

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  void _addReference() {
    setState(() {
      widget.cv.user_references.add(<String, dynamic>{
        'name': '',
        'job': '',
        'organization': '',
        'phone': '',
        'email': '',
      });
    });
  }

  Future<void> _handleManualSave() async {
    setState(() => _isSaving = true);
    try {
      // 1. መጀመሪያ በ UUID String ማጽዳት
      await DatabaseHelper.instance.clearReferences(widget.cv.id);

      // 2. String ስለሆነ ባዶ አለመሆኑን ብቻ ቼክ ማድረግ (ከ -1 ጋር አታወዳድር)
      if (widget.cv.id.toString().isNotEmpty) {
        // ማሳሰቢያ፡ DatabaseHelper ውስጥ ይሄ ሜተድ String መቀበሉን አረጋግጥ
        await DatabaseHelper.instance.updateProfileSummary(widget.cv.id, widget.cv.summary);

        for (var ref in widget.cv.user_references) {
          await DatabaseHelper.instance.addReference({
            'profileid': widget.cv.id, // ይህ UUID String ነው
            'name': ref['name']?.toString() ?? '',
            'job': ref['job']?.toString() ?? '',
            'organization': ref['organization']?.toString() ?? '',
            'phone': ref['phone']?.toString() ?? '',
            'email': ref['email']?.toString() ?? '',
          });
        }

        widget.onDataChanged?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("All changes saved successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Save Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = appSettingsNotifier.value;
    final themeColor = Color(settings['themeColor']);
    final fontFamily = settings['fontFamily'];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Professional Summary Section
            _buildSectionHeader("Professional Summary", Icons.notes_rounded,
                themeColor, fontFamily),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: _iphoneCardDecoration(),
              child: Column(
                children: [
                  CupertinoTextField(
                    // 'null' ካደረግከው ሳጥኑ ገደብ አይኖረውም፣ እንደ ጽሁፉ ርዝመት 'Auto' ይሰፋል
                    maxLines: null,

                    // መጀመሪያ ሲታይ ግን ቢያንስ የ 3 መስመር ስፋት እንዲኖረው ያደርጋል
                    minLines: 3,

                    placeholder:
                        "Your professional summary will appear here...",
                    controller: _summaryController,

                    // ጽሁፉ ከሳጥኑ ጠርዝ ጋር እንዳይጣበቅ ፓዲንግ መጨመር
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),

                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: fontFamily,
                      height: 1.5, // ለንባብ ምቹ እንዲሆን (Line height)
                    ),

                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey[200]!),
                    ),

                    onChanged: (v) => widget.cv.summary = v,
                  ),
                  SizedBox(height: 10.h),
                  _buildAiButton(themeColor, fontFamily),
                ],
              ),
            ),

            SizedBox(height: 25.h),

            // 2. References Section
            _buildSectionHeader(
                "References", Icons.people_alt_rounded, themeColor, fontFamily),
            if (widget.cv.user_references.isEmpty)
              _buildEmptyState(fontFamily)
            else
              ...widget.cv.user_references.asMap().entries.map((entry) {
                return _buildRefCard(
                    entry.key, themeColor, fontFamily, entry.value);
              }),

            SizedBox(height: 20.h),

            // 3. Combined Save and Add Actions Box
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: _iphoneCardDecoration(),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _addReference,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("ADD NEW REFERENCE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: themeColor,
                      minimumSize: Size(double.infinity, 45.h),
                      side:
                          BorderSide(color: themeColor.withValues(alpha: 0.5)),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  const Divider(),
                  SizedBox(height: 12.h),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleManualSave,
                    icon: _isSaving
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_done_outlined),
                    label: Text(_isSaving ? "SAVING..." : "SAVE ALL CHANGES",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50.h),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  Widget _buildRefCard(int index, Color themeColor, String fontFamily,
      Map<String, dynamic> ref) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: _iphoneCardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 14.r,
                backgroundColor: themeColor.withValues(alpha: 0.1),
                child: Text("${index + 1}",
                    style: TextStyle(
                        color: themeColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => widget.cv.user_references.removeAt(index)),
                icon: Icon(CupertinoIcons.trash,
                    color: Colors.red[300], size: 18.sp),
              ),
            ],
          ),
          _buildField("Full Name", (v) => ref['name'] = v, ref['name'] ?? '',
              fontFamily),
          _buildField(
              "Job Title", (v) => ref['job'] = v, ref['job'] ?? '', fontFamily),
          _buildField("Organization", (v) => ref['organization'] = v,
              ref['organization'] ?? '', fontFamily),
          _buildField(
              "Phone", (v) => ref['phone'] = v, ref['phone'] ?? '', fontFamily),
          _buildField(
              "Email", (v) => ref['email'] = v, ref['email'] ?? '', fontFamily),
        ],
      ),
    );
  }

  Widget _buildField(String label, Function(String) onUpdate, String initial,
      String fontFamily) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: CupertinoTextField(
        placeholder: label,
        controller: TextEditingController(text: initial)
          ..selection =
              TextSelection.fromPosition(TextPosition(offset: initial.length)),
        onChanged: onUpdate,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
            color: Colors.grey[50], borderRadius: BorderRadius.circular(10.r)),
        style: TextStyle(fontSize: 14.sp, fontFamily: fontFamily),
      ),
    );
  }

  Widget _buildAiButton(Color themeColor, String fontFamily) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        // AIው ዳታ እያመጣ ከሆነ በተኑን Disable ያደርገዋል
        onPressed: _isAiLoading ? null : _generateAiSummary,
        icon: _isAiLoading
            ? SizedBox(
                width: 14.w,
                height: 14.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                ),
              )
            : Icon(Icons.auto_awesome, size: 16.sp, color: themeColor),
        label: Text(
          _isAiLoading ? "Processing..." : "AI Write",
          style: TextStyle(
            color: _isAiLoading ? Colors.grey : themeColor,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily, // የተመረጠውን ፎንት እንዲጠቀም
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

// 1. የ Typewriter Effect ፋንክሽን
  Future<void> _typewriterEffect(String fullText) async {
    String currentText = "";
    for (int i = 0; i < fullText.length; i++) {
      // ፍጥነቱን እዚህ ማስተካከል ትችላለህ (15-25ms ይመከራል)
      await Future.delayed(const Duration(milliseconds: 20));
      currentText += fullText[i];

      setState(() {
        _summaryController.text = currentText;
        widget.cv.summary = currentText;
      });

      // ካርሰሩ (Cursor) ሁልጊዜ መጨረሻ ላይ እንዲሆን
      _summaryController.selection = TextSelection.fromPosition(
        TextPosition(offset: _summaryController.text.length),
      );
    }
  }

  // 2. ዋናው የ AI Summary ጀነሬተር
  Future<void> _generateAiSummary() async {
    if (widget.cv.jobTitle.isEmpty &&
        widget.cv.skills.isEmpty &&
        widget.cv.experience.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Please fill in your Job Title, Skills, and Experience first!")),
      );
      return;
    }

    setState(() {
      _isAiLoading = true;
      _summaryController.clear(); // አዲስ እንዲጀምር አሮጌውን ያጸዳል
    });

    try {
      String skillsText = widget.cv.skills.map((e) => e['name']).join(', ');

      String contextData = """
        Role: Senior Career Consultant.
        ai role: You are an expert Human Career Consultant. Your goal is to rewrite the input into a natural, human-sounding professional narrative.
        rules: HUMAN-CENTRIC LANGUAGE: Avoid robotic AI clichés (e.g., avoid overusing 'spearheaded', 'leveraged', 'synergy', 'passionate'). Use clear, strong, and grounded verbs that a real professional would use.
        focus: You are a professional career architect and narrative writer. Your task is to transform raw input into a sophisticated, personal, and descriptive professional story. CRITICAL RULES: First, never copy input text directly; instead, describe the user's background using high-impact, original professional language. Second, for the Professional Summary section, generate a single, compelling paragraph of exactly 5 to 7 lines that synthesizes the user's overall value proposition. For Work Experience (Description or Achievements): You MUST be extremely concise. Craft a powerful description of ONLY 2 to 3 lines in total. Even if multiple points are requested, synthesize them so they do not exceed this 3-line limit. focusing on personal contributions and strategic impact. Fourth, maintain a strictly formal and ATS-optimized tone throughout. Output ONLY the final polished text, excluding any conversational intro, labels, or 'Here is your text' style remarks.
        Task: Write a personalized, human-sounding professional summary for ${widget.cv.firstName} ${widget.cv.lastName}.
        Profile: A ${widget.cv.jobTitle} skilled in $skillsText.
        Experience: ${widget.cv.experience} key achievements and responsibilities.
        
Requirements:
      1. Perspective: First-person ("I", "my").
      2. Content: Focus ONLY on hard skills and real-world work approach. 
      3. BANNED WORDS: Do NOT use: "passionate," "driven," "catalyst," "proven track record," "synergy," "dynamic," or "innovative." 
      4. NO FILLERS: Start the text immediately. Do NOT include "Here is your summary" or any introductory remarks.
      5. NO FORMATTING: Do NOT use bolding (**), bullet points, or quotation marks. Just plain text.
      6. HUMAN FEEL: Use simple, strong verbs like "I manage," "I build," "I solve," instead of flowery language.
3. "The Post-AI Career Narrative": You are a top-tier career consultant specializing in crafting authentic, human-centric professional summaries. Your task is to create a compelling narrative that highlights the user's real skills and work style without resorting to overused AI-generated clichés.
CRITICAL RULES:
1. First-Person Perspective: Write the summary as if the user is speaking directly about themselves, using "I" and "my" statements.
2. Content Focus: Emphasize the user's hard skills, practical experience, and unique approach to work. Avoid generic statements about being "passionate" or "driven."
3. Banned Words: Do NOT use the following words or phrases, which are commonly associated with AI-generated content: "passionate," "driven," "catalyst," "proven track record," "synergy," "dynamic," "innovative."
4. No Fillers: Do NOT include any introductory phrases like "Here is your summary" or "Based on your input." Start the summary immediately with the content.
5. No Formatting: Do NOT use any special formatting such as bold (**), bullet points, or quotation marks. The output should be plain text.
6. Human Feel: Use straightforward, strong verbs that a real professional would use, such as "I manage," "I build," "I solve," instead of flowery or exaggerated language.  
7. Output ONLY the final polished summary text, without any labels, explanations, or conversational remarks.
8. Length: The summary should be a single, compelling paragraph of exactly 5 to 7 lines that synthesizes the user's overall value proposition in a clear and authentic way.
9. quickly synthesize any multiple points about work experience into a concise description of 2 to 3 lines that focuses on the user's personal contributions and strategic impact, without exceeding this limit, even if multiple achievements are provided.
10. Tone: Maintain a strictly formal and ATS-optimized tone throughout the summary. Avoid any language that might seem overly casual or conversational. The goal is to create a polished, professional narrative that resonates with hiring managers and passes through Applicant Tracking Systems effectively.
11. "The Post-AI Career Narrative": You are a top-tier career consultant specializing in crafting authentic, human-centric professional summaries. Your task is to create a compelling narrative that highlights the user's real skills and work style without resorting to overused AI-generated clichés.
CRITICAL RULES:
1. dynamic, innovative," or "proven track record."
2. No Fillers: Do NOT include any introductory phrases like "Here is your summary" or "Based on your input." Start the summary immediately with the content.
3. No Formatting: Do NOT use any special formatting such as bold (**), bullet points, 
or quotation marks. The output should be plain text.
4. Human Feel: Use straightforward, strong verbs that a real professional would use, such as "I manage," "I build," "I solve," instead of flowery or exaggerated language.
5. Output ONLY the final polished summary text, without any labels, explanations, or conversational remarks.
6. Length: The summary should be a single, compelling paragraph of exactly 5 to 7 lines that synthesizes the user's overall value proposition in a clear and authentic way.
      """;

      String aiResponse = await AIService.askAI(contextData, isAmharic: false);

      if (aiResponse.isNotEmpty) {
        // 1. የላቀ የጽዳት ስራ (RegExp በመጠቀም አላስፈላጊ መግቢያዎችን እና ምልክቶችን ማጥፋት)
        String cleanResponse = aiResponse
            .replaceAll(
                RegExp(
                    r'^(Summary|Professional Summary|Result|Output|Here is your summary):',
                    caseSensitive: false),
                '')
            .replaceAll('*', '')
            .replaceAll('"', '')
            .trim();
        if (cleanResponse
                .split('\n')
                .first
                .toLowerCase()
                .contains('certainly') ||
            cleanResponse.split('\n').first.toLowerCase().contains('here is')) {
          List<String> lines = cleanResponse.split('\n');
          lines.removeAt(0); // የመጀመሪያውን አላስፈላጊ መስመር ይጥላል
          cleanResponse = lines.join(' ').trim();
        }
        // 👈 እዚህ ጋር በቀጥታ ሴት ከማድረግ ይልቅ Typewriter ይጠራል
        await _typewriterEffect(cleanResponse);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Service temporarily unavailable. Please try again.")),
      );
    } finally {
      setState(() => _isAiLoading = false);
    }
  }

  BoxDecoration _iphoneCardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      );

  Widget _buildSectionHeader(
      String title, IconData icon, Color themeColor, String fontFamily) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
      child: Row(
        children: [
          Icon(icon, color: themeColor, size: 18.sp),
          SizedBox(width: 8.w),
          Text(title,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                  fontFamily: fontFamily)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String fontFamily) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        children: [
          Icon(Icons.people_outline, color: Colors.grey[400], size: 40.sp),
          SizedBox(height: 10.h),
          Text("No references added yet",
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13.sp,
                  fontFamily: fontFamily)),
        ],
      ),
    );
  }
}
