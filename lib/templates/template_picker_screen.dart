import 'package:flutter/material.dart';
import 'package:my_new_cv/app_fonts.dart';
import 'package:my_new_cv/cv_preview_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../cv_model.dart';
import 'master_template.dart';
import '../database_helper.dart';

class TemplatePickerScreen extends StatefulWidget {
  final CvModel cvModel;
  const TemplatePickerScreen({super.key, required this.cvModel});

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  // --- States ---
  CvDesign selectedDesign = CvDesign.executive;
  PdfColor selectedColor = PdfColors.indigo900;
  String selectedFont = "JetBrains Mono";
  double selectedScale = 1.0;
  bool isMenuOpen = false;

  final List<Map<String, dynamic>> designs = [
    {'type': CvDesign.minimalistSplit, 'name': 'Split Minimal'},
    {'type': CvDesign.executive, 'name': 'Executive'},
    {'type': CvDesign.compact, 'name': 'Classic Split'},
    {'type': CvDesign.modern, 'name': 'Modern'},
    {'type': CvDesign.dynamicPro, 'name': 'Dynamic Pro'},
  ];

  final List<PdfColor> colorOptions = [
    PdfColors.indigo900,
    PdfColors.blue900,
    PdfColors.black,
    PdfColors.teal900,
    PdfColors.red900,
    PdfColors.grey900,
  ];

  @override
  void initState() {
    super.initState();
    _prepareSetup();
  }

  Future<void> _prepareSetup() async {
    await AppFonts.loadAllFontBytes();
    AppFonts.initFromBytes(AppFonts.fontBytesMap);
    final settings = await DatabaseHelper.instance.getSettings();
    if (mounted) {
      setState(() {
        if (settings['fontFamily'] != null &&
            AppFonts.availableFamilies.contains(settings['fontFamily'])) {
          selectedFont = settings['fontFamily'];
        }
      });
    }
  }

  void _generateAndPreview() async {
    if (!mounted) return;

    debugPrint("Directly navigating to preview...");

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CvPreviewScreen(
          cvModel: widget.cvModel,
          templateIndex: selectedDesign.index,
          primaryColor: Color(selectedColor.toInt()),
          fontFamily: selectedFont,
          scale: selectedScale,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Color(selectedColor.toInt());
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        title: const Text("Customize CV",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(isMenuOpen ? Icons.close : Icons.tune_rounded),
            onPressed: () => setState(() => isMenuOpen = !isMenuOpen),
          )
        ],
      ),
      body: Stack(
        children: [
          // 1. PDF Preview - Background
          Positioned.fill(
            child: PdfPreview(
              key: ValueKey(
                  '$selectedDesign-$selectedColor-$selectedFont-$selectedScale'),
              build: (format) async {
                final template = MasterTemplate(
                  model: widget.cvModel,
                  design: selectedDesign,
                  primaryColor: selectedColor,
                  fontFamily: selectedFont,
                  scale: selectedScale,
                );
                final doc = await template.generate();
                return doc.save();
              },
              useActions: false,
              canChangePageFormat: false,
              canDebug: false,
              loadingWidget: const Center(child: CircularProgressIndicator()),
            ),
          ),

          // 2. Right Side Customization Menu
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 0,
            bottom: 0,
            right: isMenuOpen ? 0 : -screenWidth * 0.75,
            width: screenWidth * 0.75,
            child: Container(
              decoration: BoxDecoration(
                // ✅ ተስተካክሏል፡ withValues() ተተክቷል
                color: Colors.white.withValues(alpha: 0.98),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: const Offset(-5, 0))
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        children: [
                          _buildColorPicker(),
                          const Divider(height: 30),
                          _buildFontAndSizeControls(activeColor),
                          const Divider(height: 30),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text("TEMPLATES",
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 1.1)),
                          ),
                          const SizedBox(height: 10),
                          ...designs.map((design) {
                            final isSelected = selectedDesign == design['type'];
                            return ListTile(
                              selected: isSelected,
                              // ✅ ተስተካክሏል፡ withValues() ተተክቷል
                              selectedTileColor:
                                  activeColor.withValues(alpha: 0.1),
                              title: Text(design['name'],
                                  style: TextStyle(
                                      color: isSelected
                                          ? activeColor
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: activeColor)
                                  : null,
                              onTap: () => setState(
                                  () => selectedDesign = design['type']),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Action Button
          Positioned(
            bottom: 20,
            left: 20,
            right: isMenuOpen ? (screenWidth * 0.75) + 20 : 20,
            child: _buildActionButton(activeColor, screenWidth),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildColorPicker() {
    return Column(
      children: [
        const Text("THEME COLOR",
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.1)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colorOptions.map((color) {
            final isSelected = selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => selectedColor = color),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Color(color.toInt()),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected ? Colors.orange : Colors.transparent,
                      width: 3),
                  boxShadow: [
                    if (isSelected)
                      const BoxShadow(color: Colors.black26, blurRadius: 5)
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFontAndSizeControls(Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("FONT",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          DropdownButton<String>(
            value: AppFonts.availableFamilies.contains(selectedFont)
                ? selectedFont
                : AppFonts.availableFamilies.first,
            isExpanded: true,
            underline: Container(height: 1, color: Colors.grey[300]),
            items: AppFonts.availableFamilies
                .map((f) => DropdownMenuItem(
                    value: f,
                    child:
                        Text(f, style: TextStyle(fontFamily: f, fontSize: 14))))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => selectedFont = val);
            },
          ),
          const SizedBox(height: 25),
          Text("TEXT SIZE: ${selectedScale.toStringAsFixed(1)}",
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          Slider(
            value: selectedScale,
            min: 0.7,
            max: 1.5,
            divisions: 13,
            activeColor: activeColor,
            onChanged: (val) => setState(() => selectedScale = val),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Color activeColor, double screenWidth) {
    // ✅ ተስተካክሏል፡ ስህተቱን ለማጥፋት double.infinity ፋንታ MediaQuery ተጠቅመናል
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isMenuOpen ? (screenWidth * 0.25) - 30 : screenWidth - 40,
      child: ElevatedButton(
        onPressed: _generateAndPreview,
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          minimumSize: const Size(0, 58),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 8,
          // ✅ ተስተካክሏል፡ withValues() ተተክቷል
          shadowColor: activeColor.withValues(alpha: 0.4),
        ),
        child: Text(
          "PREVIEW & DOWNLOAD",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.1),
        ),
      ),
    );
  }
}
