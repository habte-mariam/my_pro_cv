import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../cv_model.dart';

class DynamicProTemplate {
  final CvModel model;
  final PdfColor primaryColor;
  final String fontFamily;
  final CvDesign subDesign; // ተጠቃሚው የመረጠው ዲዛይን (Modern, Executive, ወዘተ)

  DynamicProTemplate({
    required this.model,
    required this.primaryColor,
    required this.fontFamily,
    required this.subDesign,
  });

  Future<pw.Document> generate() async {
    final pdf = pw.Document();
    final iconFont = await PdfGoogleFonts.materialIcons();
    final mainFont = await PdfGoogleFonts.robotoCondensedRegular();
    final boldFont = await PdfGoogleFonts.robotoCondensedBold();

    pw.ImageProvider? profileImage;
    if (model.profileImagePath.isNotEmpty) {
      final imgFile = File(model.profileImagePath);
      if (imgFile.existsSync()) {
        profileImage = pw.MemoryImage(imgFile.readAsBytesSync());
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(base: mainFont, bold: boldFont),
        build: (pw.Context context) {
          List<pw.Widget> content = [];

          // 1. Header (በመረጠው ዲዛይን መሰረት ቋሚ ይሆናል)
          content.add(_buildHeaderByDesign(profileImage, iconFont));
          content.add(pw.SizedBox(height: 20));

          // 2. ሴክሽኖች (በ layoutOrder መሰረት ዳይናሚክ ይሆናሉ)
          for (String section in model.layoutOrder) {
            content.add(_buildSectionContent(section, iconFont));
          }

          return content;
        },
      ),
    );
    return pdf;
  }

  // --- ዲዛይኑን አይቶ Header የሚሰራ ፈንክሽን ---
  pw.Widget _buildHeaderByDesign(pw.ImageProvider? img, pw.Font iconFont) {
    if (subDesign == CvDesign.executive) {
      // የ Executive ዲዛይን ራስጌ (Center)
      return pw.Center(
        child: pw.Column(children: [
          pw.Text("${model.firstName} ${model.lastName}".toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor)),
          pw.Text(model.jobTitle.toUpperCase(),
              style: const pw.TextStyle(fontSize: 12)),
        ]),
      );
    } else {
      // የ Modern ወይም ሌሎቹ ዲዛይን ራስጌ (Left align with Image)
      return pw.Row(children: [
        if (img != null) _buildCircularImage(img),
        pw.Expanded(
            child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("${model.firstName} ${model.lastName}".toUpperCase(),
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor)),
            pw.Text(model.jobTitle, style: const pw.TextStyle(fontSize: 14)),
          ],
        )),
      ]);
    }
  }

  // --- ሴክሽኑን እና ዲዛይኑን አይቶ ይዘት የሚሰራ ---
  pw.Widget _buildSectionContent(String section, pw.Font iconFont) {
    // እዚህ ጋር ያንተን Switch Case ትጠቀማለህ...
    // Summary, Experience, Education... እያለ ይቀጥላል
    
    return pw.SizedBox();
  }

  pw.Widget _buildCircularImage(pw.ImageProvider img) {
    return pw.Container(
      width: 70,
      height: 70,
      margin: const pw.EdgeInsets.only(right: 15),
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        image: pw.DecorationImage(image: img, fit: pw.BoxFit.cover),
      ),
    );
  }
}
