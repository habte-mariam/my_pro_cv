import 'package:my_new_cv/templates/dynamic_pro_template.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../cv_model.dart';
import 'modern_template.dart';
import 'compact_professional_template.dart';
import 'executive_template.dart';
import 'minimalist_split_template.dart'; // 👈 1. አዲሱን ፋይል እዚህ Import አድርግ

class MasterTemplate {
  final CvModel model;
  final CvDesign design;
  final PdfColor primaryColor;
  final String fontFamily;
  final double scale; // 👈 2. Scale ተጨምሯል
  final CvDesign selectedSubDesign;

  MasterTemplate({
    required this.model,
    required this.design,
    required this.primaryColor,
    this.fontFamily = 'JetBrains Mono',
    this.scale = 1.0, // 👈 3. Default እሴት ሰጥተነዋል
    this.selectedSubDesign = CvDesign.modern, // 👈 4. subDesign እንደ አማራጭ ተጨምሯል
  });

  Future<pw.Document> generate() async {
    // 1. Executive
    if (design == CvDesign.executive) {
      return await ExecutiveTemplate(
        model: model,
        primaryColor: primaryColor,
        fontFamily: fontFamily,
        // scale ካለው እዚህም ማለፍ አለበት
      ).generate();
    }

    // 2. Modern
    if (design == CvDesign.modern) {
      return await ModernTemplate(
        model: model,
        primaryColor: primaryColor,
        fontFamily: fontFamily,
      ).generate();
    }

    // 3. Compact
    if (design == CvDesign.compact) {
      final myConfig = CVThemeConfig(
        primary: primaryColor,
        sidebarBg: const PdfColor.fromInt(0xFFF5F5F5),
        textMain: PdfColors.black,
        fontFamily: fontFamily,
        scale: scale, // 👈 ከተጠቃሚው የመጣውን scale እዚህ እናስገባለን
      );

      return await CompactProfessionalTemplate(
        model: model,
        config: myConfig,
      ).generate();
    }

    // 4. Minimalist Split (አዲሱ ቴምፕሌት) 👈 4. እዚህ ጋር ተያይዟል
    if (design == CvDesign.minimalistSplit) {
      return await MinimalistSplitTemplate(
        model: model,
        primaryColor: primaryColor,
        fontFamily: fontFamily,
        scale: scale, // 👈 Scale እዚህም ይሰራል
      ).generate();
    }
    if (design == CvDesign.dynamicPro) {
      return await DynamicProTemplate(
        model: model,
        primaryColor: primaryColor,
        fontFamily: fontFamily,
        subDesign: selectedSubDesign, // subDesign እንደ አማራጭ ተጨምሯል
      ).generate();
    }
    // Default
    return await ExecutiveTemplate(
      model: model,
      primaryColor: primaryColor,
      fontFamily: fontFamily,
    ).generate();
  }
}
