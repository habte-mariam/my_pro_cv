import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../cv_model.dart';
import '../database_helper.dart';
import '../main.dart';

class CertificatesForm extends StatefulWidget {
  final CvModel cv;
  final VoidCallback? onDataChanged;

  const CertificatesForm({super.key, required this.cv, this.onDataChanged});

  @override
  State<CertificatesForm> createState() => _CertificatesFormState();
}

class _CertificatesFormState extends State<CertificatesForm> {
  final Map<String, TextEditingController> _controllers = {};
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

  void _addCertificate() {
    setState(() {
      widget.cv.certificates = List.from(widget.cv.certificates)
        ..add(<String, dynamic>{
          'certName': '',
          'organization': '',
          'year': '',
        });
    });
    _notifyChange();
  }

  Future<void> _saveToDatabase() async {
    setState(() => _isSaving = true);

    try {
      await DatabaseHelper.instance.clearCertificates(widget.cv.profileid);

      for (var cert in widget.cv.certificates) {
        Map<String, dynamic> certToSave = Map<String, dynamic>.from(cert);

        // 1. የድሮውን ID ማስወገድ (SQLite ራሱ አዲስ እንዲሰጠው)
        certToSave.remove('id');

        // 2. ትክክለኛውን profileId መመደብ
        certToSave['profileid'] = widget.cv.profileid;

        await DatabaseHelper.instance.addCertificate(certToSave);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Certificates Saved Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error saving: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = Color(appSettingsNotifier.value['themeColor']);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
                "Certifications", _addCertificate, Icons.verified, themeColor),
            SizedBox(height: 15.h),
            if (widget.cv.certificates.isEmpty)
              GestureDetector(
                onTap: _addCertificate,
                child: _buildEmptyState(
                    "No certificates added yet. Tap to add your achievements.",
                    themeColor),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cv.certificates.length,
              itemBuilder: (context, index) {
                final cert = widget.cv.certificates[index];
                return _buildCertCard(index, themeColor, cert);
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

  Widget _buildCertCard(
      int index, Color themeColor, Map<String, dynamic> cert) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border:
            Border.all(color: themeColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Certificate #${index + 1}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: themeColor)),
              IconButton(
                onPressed: () {
                  setState(() => widget.cv.certificates.removeAt(index));
                  _notifyChange();
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const Divider(),
          _buildField("cert_${index}_name",
              "Certificate Name (e.g. AWS Solutions Architect)", (v) {
            cert['certName'] = v;
            _notifyChange();
          }, cert['certName'].toString()),
          _buildField("cert_${index}_org", "Issuing Organization", (v) {
            cert['organization'] = v;
            _notifyChange();
          }, cert['organization'].toString()),
          _buildField("cert_${index}_year", "Year Obtained", (v) {
            cert['year'] = v;
            _notifyChange();
          }, cert['year'].toString(), keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildField(
      String key, String label, Function(String) onChanged, String initial,
      {TextInputType? keyboardType}) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initial);
    }
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        controller: _controllers[key],
        onChanged: onChanged,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

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
            icon: Icon(Icons.add_circle, color: themeColor, size: 28.sp)),
      ],
    );
  }

  Widget _buildEmptyState(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_outlined, color: color, size: 40.sp),
          SizedBox(height: 10.h),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(Color themeColor) {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveToDatabase,
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        minimumSize: Size(double.infinity, 50.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
      child: _isSaving
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Save Certificates",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
