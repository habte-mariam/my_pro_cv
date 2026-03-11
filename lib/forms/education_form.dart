import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_new_cv/cv_model.dart';
import '../database_helper.dart';
import '../app_constants.dart';

class EducationForm extends StatefulWidget {
  final CvModel cv;
  final VoidCallback onDataChanged;

  const EducationForm({
    super.key,
    required this.cv,
    required this.onDataChanged, //required String profileId,
  });

  @override
  State<EducationForm> createState() => _EducationFormState();
}

class _EducationFormState extends State<EducationForm> {
  List<Map<String, dynamic>> _tempEducationList = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. መጀመሪያ ከ CvModel ዳታ ካለ እንወስዳለን
      if (widget.cv.education.isNotEmpty) {
        debugPrint("Education: Loading from CvModel");
        setState(() {
          _tempEducationList = List<Map<String, dynamic>>.from(
            widget.cv.education.map((e) => Map<String, dynamic>.from(e)),
          );
          _isLoading = false;
        });
        return;
      }

// 2. ከ CvModel ባዶ ከሆነ ከ SQLite ዳታቤዝ እንፈልጋለን
      debugPrint("Education: Fetching for UUID: ${widget.cv.profileid}");

      final db = await DatabaseHelper.instance.database;
      final results = await db.query(
        'education',
        where: 'profileid = ?',
        whereArgs: [widget.cv.profileid.toString()],
      );

      debugPrint("Found ${results.length} education records");

      if (mounted) {
        setState(() {
          _tempEducationList =
              results.map((e) => Map<String, dynamic>.from(e)).toList();
          // ሞዴሉንም እናድሰው UIው እንዲያውቀው
          widget.cv.education =
              List<Map<String, dynamic>>.from(_tempEducationList);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Education Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFieldUpdate(int index, String field, String value) {
    setState(() {
      _tempEducationList[index][field] = value;

      if (field == 'degree' && value.contains("Grade")) {
        _tempEducationList[index]['field'] = "";
      }
    });
  }

  void _addNewEntry() {
    setState(() {
      _tempEducationList.add({
        'profileid': widget.cv.profileid,
        'school': '',
        'degree': 'Bachelor\'s Degree',
        'field': '',
        'gradYear': '',
        'cgpa': '',
        'project': '',
      });
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _tempEducationList.removeAt(index);
    });
  }

  Future<void> _saveAllToDatabase() async {
    setState(() => _isSaving = true);
    try {
      await DatabaseHelper.instance.clearEducation(widget.cv.profileid);

      for (var edu in _tempEducationList) {
        final dataToSave = Map<String, dynamic>.from(edu);

        // 1. የድሮውን ID አውጣ (SQLite አዲስ እንዲሰጠው)
        dataToSave.remove('id');

        // 2. ትክክለኛው profileid መኖሩን አረጋግጥ
        dataToSave['profileid'] = widget.cv.profileid;

        await DatabaseHelper.instance.addEducation(dataToSave);
      }
      widget.cv.education = List<Map<String, dynamic>>.from(_tempEducationList);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("All changes saved successfully!"),
              backgroundColor: Colors.green),
        );
      }
      widget.onDataChanged();
    } catch (e) {
      debugPrint("Save Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _tempEducationList.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.all(16.w),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAllToDatabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("SAVE ALL CHANGES",
                        style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildHeader("Education History", themeColor, _addNewEntry),
            SizedBox(height: 20.h),
            if (_tempEducationList.isEmpty)
              _buildEmptyState(
                  "No education added yet", themeColor, _addNewEntry)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tempEducationList.length,
                itemBuilder: (context, index) {
                  final edu = _tempEducationList[index];
                  return _buildEducationCard(index, edu, themeColor);
                },
              ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, Color color, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 18.sp, fontWeight: FontWeight.bold, color: color)),
        IconButton(
          onPressed: onAdd,
          icon: Icon(Icons.add_circle, color: color, size: 28.sp),
        ),
      ],
    );
  }

  Widget _buildEducationCard(
      int index, Map<String, dynamic> edu, Color themeColor) {
    final String degree = edu['degree']?.toString() ?? "";
    final bool isGradeLevel = degree.contains("Grade");
    final String currentField = edu['field']?.toString() ?? "";

    // 1. 'Other' የሚለውን ከዝርዝሩ ውስጥ እናወጣዋለን (Simple Dropdown እንዲሆን)
    List<String> fieldOptions = AppConstants.allFieldsOfStudy.toList();

    // 2. ተጠቃሚው የጻፈው ትምህርት በዝርዝሩ ውስጥ የሌለ መሆኑን እንፈትሻለን
    bool isCustomField =
        currentField.isNotEmpty && !fieldOptions.contains(currentField);

    InputDecoration buildInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: themeColor.withValues(), width: 1),
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
              color: Colors.black.withValues(),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: themeColor.withValues()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Entry #${index + 1}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                      fontSize: 14.sp)),
              IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red),
                  onPressed: () => _removeEntry(index)),
            ],
          ),
          const Divider(),
          SizedBox(height: 10.h),

          // Degree Level
          _buildDropdown(
              "Degree / Level",
              edu['degree'],
              AppConstants.degreeLevels,
              (val) => _onFieldUpdate(index, 'degree', val!),
              buildInputDecoration),

          // School Name
          _buildCustomTextField(
              "School / University Name",
              edu['school'] ?? "",
              (val) => _onFieldUpdate(index, 'school', val),
              buildInputDecoration),

          if (!isGradeLevel) ...[
            // Field of Study Logic
            if (!isCustomField)
              Column(
                children: [
                  _buildDropdown(
                    "Field of Study",
                    fieldOptions.contains(currentField) ? currentField : null,
                    fieldOptions,
                    (val) => _onFieldUpdate(index, 'field', val!),
                    buildInputDecoration,
                  ),
                  // Custom Field ለመጨመር የሚያስችል አዝራር
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _onFieldUpdate(index, 'field',
                          " "), // ባዶ ቦታ በመስጠት custom field እንዲከፈት እናደርጋለን
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Not in the list?",
                          style: TextStyle(
                              fontSize: 28,
                              fontStyle: FontStyle.italic,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildCustomTextField(
                    "Enter Field of Study",
                    currentField.trim(),
                    (val) => _onFieldUpdate(index, 'field', val),
                    buildInputDecoration,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          _onFieldUpdate(index, 'field', ""), // ወደ ዝርዝሩ ለመመለስ
                      icon: const Icon(Icons.list, size: 16),
                      label: const Text("Back to list",
                          style: TextStyle(
                              fontSize: 28,
                              fontStyle: FontStyle.italic,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),

            Row(
              children: [
                Expanded(
                    child: _buildCustomTextField(
                        "Grad Year",
                        edu['gradYear'] ?? "",
                        (val) => _onFieldUpdate(index, 'gradYear', val),
                        buildInputDecoration,
                        isNumber: true)),
                SizedBox(width: 12.w),
                Expanded(
                    child: _buildCustomTextField(
                        "CGPA",
                        edu['cgpa'] ?? "",
                        (val) => _onFieldUpdate(index, 'cgpa', val),
                        buildInputDecoration,
                        isNumber: true)),
              ],
            ),
            _buildCustomTextField(
                "Final Project/Thesis",
                edu['project'] ?? "",
                (val) => _onFieldUpdate(index, 'project', val),
                buildInputDecoration),
          ] else
            _buildCustomTextField(
                "Year of Completion",
                edu['gradYear'] ?? "",
                (val) => _onFieldUpdate(index, 'gradYear', val),
                buildInputDecoration,
                isNumber: true),
        ],
      ),
    );
  }

  Widget _buildCustomTextField(
    String label,
    String value,
    Function(String) onChanged,
    InputDecoration Function(String) decorationFn, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        initialValue: value,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(fontSize: 14.sp),
        decoration: decorationFn(label),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
    InputDecoration Function(String) decorationFn,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: items.contains(value) ? value : null,
        items: items
            .map((e) => DropdownMenuItem(
                value: e, child: Text(e, style: TextStyle(fontSize: 13.sp))))
            .toList(),
        onChanged: onChanged,
        decoration: decorationFn(label),
      ),
    );
  }

  Widget _buildEmptyState(String msg, Color color, VoidCallback onTap) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.school_outlined,
              size: 60.sp, color: color.withValues(alpha: 0.2)),
          SizedBox(height: 10.h),
          Text(msg, style: TextStyle(color: color.withValues(alpha: 0.5))),
          TextButton(onPressed: onTap, child: const Text("Add Education Now")),
        ],
      ),
    );
  }
}
