import 'package:flutter/material.dart';
import 'package:my_new_cv/forms/personal_form.dart';
import 'package:my_new_cv/forms/education_form.dart';
import 'package:my_new_cv/forms/experience_form.dart';
import 'package:my_new_cv/forms/certificates_form.dart';
import 'package:my_new_cv/forms/skill_form.dart';
import 'package:my_new_cv/forms/languages_form.dart';
import 'package:my_new_cv/forms/reference_form.dart';
import 'package:my_new_cv/step_wrapper.dart';
import 'package:my_new_cv/templates/template_picker_screen.dart'; // 👈 በትክክል መኖሩን አረጋግጥ
import '../cv_model.dart';
import '../database_helper.dart';
import '../database_service.dart';

class MainCvForm extends StatefulWidget {
  const MainCvForm({super.key});

  @override
  State<MainCvForm> createState() => _MainCvFormState();
}

class _MainCvFormState extends State<MainCvForm> {
  int _currentStep = 1;
  final int _totalSteps = 7;
  final CvModel _cvModel = CvModel();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. መጀመሪያ ሎካል (SQLite) ዳታቤዝን እንፈትሻለን
      final localData = await DatabaseHelper.instance.getFullProfile();

      if (localData != null &&
          localData['firstName'] != null &&
          localData['firstName'].toString().trim().isNotEmpty) {
        setState(() {
          _cvModel.fromMap(localData);
          _isLoading = false;
        });
        debugPrint("Data loaded from Local SQLite");
      } else {
        // 2. ሎካል ላይ ከሌለ ወደ ክላውድ (Supabase) እንሄዳለን
        final cloudData = await DatabaseService().fetchUserCv();

        if (cloudData != null) {
          final data = _cvModel.toJson();
          _cvModel.id = cloudData.id;
          await DatabaseHelper.instance.syncFullDataToLocal(data);

          setState(() {
            _cvModel.fromMap(data);
            _isLoading = false;
          });
          debugPrint("Data synced from Cloud and saved to Local!");
        } else {
          // በሁለቱም ቦታ ዳታ ከሌለ
          setState(() => _isLoading = false);
          debugPrint("No data found in Local or Cloud");
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final data = _cvModel.toJson();
        await DatabaseHelper.instance.saveProfile(data);

        if (_currentStep < _totalSteps) {
          setState(() => _currentStep++);
        } else {
          // መጨረሻ ደረጃ ላይ ሲሆን ወደ ቴምፕሌት መምረጫ ይሄዳል
          _navigateToTemplatePicker();
        }
      } catch (e) {
        debugPrint("Save Error: $e");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fix the errors before continuing.")),
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _navigateToTemplatePicker() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplatePickerScreen(
            cvModel: _cvModel,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return StepWrapper(
      currentStep: _currentStep,
      totalSteps: _totalSteps,
      cvModel: _cvModel, // 👈 ለአዲሱ StepWrapper የተጨመረ
      title: _getPageTitle(),
      onNext: _nextStep,
      onBack: _currentStep > 1 ? _prevStep : null,
      child: PopScope(
        canPop: _currentStep == 1,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _prevStep();
        },
        child: Form(
          key: _formKey,
          child: Column(
            // 👈 Column ካለህ Expanded ተጠቀም
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  // switch ሲያደርግ ግራ እንዳይጋባ layoutBuilder መጨመር ይረዳል
                  layoutBuilder:
                      (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: _buildStepContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPageTitle() {
    const Map<int, String> titles = {
      1: "Personal Details",
      2: "Education",
      3: "Work Experience",
      4: "Certifications",
      5: "Professional Skills",
      6: "Languages",
      7: "Finalize & References",
    };
    return titles[_currentStep] ?? "CV Form";
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return PersonalForm(
          key: const ValueKey(1),
          cv: _cvModel,
          onDataChanged: () => setState(() {}),
        );
      case 2:
        return EducationForm(
          key: ValueKey("${_cvModel.id}_${_cvModel.education.length}"),
          cv: _cvModel,
          onDataChanged: () => setState(() {}),
        );
      case 3:
        return ExperienceForm(
          key: const ValueKey(3),
          cv: _cvModel,
          onDataChanged: () => setState(() {}),
        );
      case 4:
        return CertificatesForm(
          key: const ValueKey(4),
          cv: _cvModel,
          onDataChanged: () => setState(() {}),
        );
      case 5:
        return SkillForm(
          key: const ValueKey(5),
          cv: _cvModel,
          onDataChanged: () => setState(() {}),
        );
      case 6:
        return LanguagesForm(
          key: const ValueKey(6),
          cv: _cvModel,
          onDataChanged: () => setState(() {}),
        );
      case 7:
        return ReferenceForm(
          key: const ValueKey(7),
          cv: _cvModel,
          onDataChanged: () => setState(() {}),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
