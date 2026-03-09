import 'package:flutter/material.dart';
import 'cv_preview_screen.dart';
import 'database_helper.dart';
import 'cv_model.dart';
import 'ai_service.dart';

class CVFormStepper extends StatefulWidget {
  const CVFormStepper({super.key});

  @override
  State<CVFormStepper> createState() => _CVFormStepperState();
}

class _CVFormStepperState extends State<CVFormStepper> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isAiGenerating = false;
  int _clickCount = 0; // የተለያየ ስታይል ለመፍጠር የሚያገለግል

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jobTitleController.dispose();
    _summaryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final data = await DatabaseHelper.instance.getFullProfile();
    if (data != null) {
      setState(() {
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _jobTitleController.text = data['jobTitle'] ?? '';
        _summaryController.text = data['summary'] ?? '';
        _phoneController.text = data['phone'] ?? '';
      });
    }
  }

  bool _isStepValid() {
    if (_currentStep == 0) {
      if (_firstNameController.text.trim().isEmpty ||
          _lastNameController.text.trim().isEmpty ||
          _jobTitleController.text.trim().isEmpty) {
        _showSnackBar("እባክዎ ስም እና የስራ መደብ ያስገቡ");
        return false;
      }
    } else if (_currentStep == 1) {
      if (_summaryController.text.trim().length < 5) {
        _showSnackBar("እባክዎ ስለራስዎ አጭር ማብራሪያ ይጻፉ ወይም በ AI ያመንጩ");
        return false;
      }
    }
    return true;
  }

  // --- AI Content Generation Logic ---
  Future<void> _generateAIContent() async {
    if (_jobTitleController.text.trim().isEmpty) {
      _showSnackBar("Please enter your Job Title first!");
      return;
    }

    setState(() => _isAiGenerating = true);

    try {
      // አማርኛ መሆኑን መለየት
      bool isAmharic =
          RegExp(r'[\u1200-\u137F]').hasMatch(_jobTitleController.text);

      // ለ AI የሚሰጥ መረጃ
      String contextData =
          "Job Title: ${_jobTitleController.text}, Name: ${_firstNameController.text}";

      // ዋና ትዕዛዝ
      String prompt = isAmharic
          ? "ለዚህ የስራ መደብ ፕሮፌሽናል የሆነ የሲቪ ማጠቃለያ ጻፍ።"
          : "Write a high-impact professional CV summary for this job title.";

      // አዲሱን AIService መጥራት (ከ Failover ጋር)
      final String result = await AIService.askAI(
        contextData,
        customPrompt: prompt,
        isAmharic: isAmharic,
        styleIndex: _clickCount, // በየተራ ስታይሉን እንዲቀይር
      );

      if (mounted) {
        setState(() {
          _summaryController.text = result;
          _clickCount++; // በሚቀጥለው ጊዜ የተለየ ስታይል እንዲያመጣ
        });
      }
    } catch (e) {
      debugPrint("AI Critical Error: $e");
      _showSnackBar("AI failed to generate content. Check internet.");
    } finally {
      if (mounted) setState(() => _isAiGenerating = false);
    }
  }

  Future<void> _finalizeAndGenerate() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.saveProfile({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'jobTitle': _jobTitleController.text,
        'phone': _phoneController.text,
        'summary': _summaryController.text,
      });

      final rawData = await DatabaseHelper.instance.getFullProfile();
      final settings = await DatabaseHelper.instance.getSettings();

      if (rawData != null && mounted) {
        CvModel model = CvModel();
        model.fromMap(rawData);

        int templateIndex = settings['templateIndex'] ?? 0;
        Color primaryColor =
            Color(settings['themeColor'] ?? Colors.indigo.value);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CvPreviewScreen(
              cvModel: model,
              templateIndex: templateIndex,
              primaryColor: primaryColor,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar("ስህተት ተከስቷል: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ሲቪዎን ያዘጋጁ",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              elevation: 0,
              onStepContinue: () {
                if (_isStepValid()) {
                  if (_currentStep < 2) {
                    setState(() => _currentStep += 1);
                  } else {
                    _finalizeAndGenerate();
                  }
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) setState(() => _currentStep -= 1);
              },
              steps: _buildSteps(),
              controlsBuilder: (context, controls) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: controls.onStepContinue,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: Text(_currentStep == 2 ? "ሲቪ አውጣ" : "ቀጥል",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controls.onStepCancel,
                            style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            child: const Text("ተመለስ"),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        title: const Text("መሰረታዊ"),
        content: Column(
          children: [
            _buildTextField("ስም (First Name)", _firstNameController),
            const SizedBox(height: 12),
            _buildTextField("የአባት ስም (Last Name)", _lastNameController),
            const SizedBox(height: 12),
            _buildTextField("የስራ መደብ (Job Title)", _jobTitleController),
            const SizedBox(height: 12),
            _buildTextField("ስልክ ቁጥር", _phoneController,
                keyboardType: TextInputType.phone),
          ],
        ),
      ),
      Step(
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        title: const Text("ማጠቃለያ"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Professional Summary",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                _isAiGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton.icon(
                        onPressed: _generateAIContent,
                        icon: const Icon(Icons.auto_awesome,
                            color: Colors.orange, size: 18),
                        label: const Text("AI Generate",
                            style: TextStyle(color: Colors.orange)),
                      ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField("ስለ ስራ ልምድዎ ባጭሩ ያብራሩ", _summaryController,
                maxLines: 5),
          ],
        ),
      ),
      Step(
        isActive: _currentStep >= 2,
        title: const Text("ማጠናቀቂያ"),
        content: _buildFinalStep(),
      ),
    ];
  }

  Widget _buildFinalStep() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
          SizedBox(height: 16),
          Text("ሁሉም ተሞልቷል!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("ሲቪዎን ለማየት እና ለማውረድ 'ሲቪ አውጣ' የሚለውን ይጫኑ።",
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
