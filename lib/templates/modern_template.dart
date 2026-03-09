import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../cv_model.dart';

class ModernTemplate {
  final CvModel model;
  final PdfColor primaryColor;
  final String fontFamily;

  ModernTemplate({
    required this.model,
    required this.primaryColor,
    required this.fontFamily,
  });

  Future<pw.Document> generate() async {
    final pdf = pw.Document();

    // ፎንቶችን ማዘጋጀት
    final mainFont = await PdfGoogleFonts.robotoCondensedRegular();
    final boldFont = await PdfGoogleFonts.robotoCondensedBold();
    final iconFont = await PdfGoogleFonts.materialIcons();

    pw.ImageProvider? profileImage;
    if (model.profileImagePath.isNotEmpty) {
      try {
        final imgFile = File(model.profileImagePath);
        if (imgFile.existsSync()) {
          profileImage = pw.MemoryImage(imgFile.readAsBytesSync());
        }
      } catch (e) {
        debugPrint("Error loading profile image: $e");
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(base: mainFont, bold: boldFont),
        build: (context) => [
          pw.Stack(
            children: [
              // የSidebar ዳራ (ከለሩን አይቀይረውም፣ አንተ የመረጥከውን primaryColor ይጠቀማል)
              pw.Container(
                width: 210,
                decoration: pw.BoxDecoration(color: primaryColor),
              ),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // --- SIDEBAR (Contact, Skills, Languages) ---
                  pw.Container(
                    width: 210,
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 40, horizontal: 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildCircularProfile(profileImage),
                        pw.SizedBox(height: 30),
                        _buildSidebarSection("CONTACT & PERSONAL", [
                          if (model.phone.isNotEmpty)
                            _sidebarItem(0xe0cd, model.phone, iconFont),
                          if (model.phone2.isNotEmpty)
                            _sidebarItem(
                                0xe0cd, "Alt: ${model.phone2}", iconFont),
                          if (model.email.isNotEmpty)
                            _sidebarItem(0xe158, model.email, iconFont),
                          if (model.address.isNotEmpty)
                            _sidebarItem(0xe0c8, model.address, iconFont),

                          // ተጨማሪ የግል መረጃዎች (ከ CvModel profiles የተገኙ)
                          if (model.gender.isNotEmpty)
                            _sidebarItem(
                                0xe63d, "Gender: ${model.gender}", iconFont),
                          if (model.age.isNotEmpty)
                            _sidebarItem(0xef5d, "Age: ${model.age}", iconFont),
                          if (model.nationality.isNotEmpty)
                            _sidebarItem(0xe153,
                                "Nationality: ${model.nationality}", iconFont),
                        ]),
                        if (model.skills.isNotEmpty)
                          _buildSidebarSection("SKILLS", [
                            // '_buildSkillBar' የነበረው ወደ '_buildSkillStars' ተቀይሯል
                            ...model.skills.map((s) => _buildSkillStars(s)),
                          ]),
                        if (model.languages.isNotEmpty)
                          _buildSidebarSection("LANGUAGES", [
                            ...model.languages
                                .map((l) => _buildLanguageItem(l)),
                          ]),
                      ],
                    ),
                  ),

                  // --- MAIN CONTENT ---
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 40, horizontal: 30),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Header: ስም እና የስራ መደብ
                          pw.Text(
                              "${model.firstName} ${model.lastName}"
                                  .toUpperCase(),
                              style: pw.TextStyle(
                                  fontSize: 28,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor)),
                          pw.Text(model.jobTitle.toUpperCase(),
                              style: const pw.TextStyle(
                                  fontSize: 14, color: PdfColors.grey700)),

                          // LinkedIn እና Portfolio (ከዳታቤዝህ የተወሰደ)
                          pw.SizedBox(height: 10),
                          pw.Row(children: [
                            if (model.linkedin.isNotEmpty)
                              _iconText(
                                  0xe894, "LinkedIn", iconFont, primaryColor),
                            pw.SizedBox(width: 15),
                            if (model.portfolio.isNotEmpty)
                              _iconText(
                                  0xe894, "Portfolio", iconFont, primaryColor),
                          ]),

                          pw.SizedBox(height: 25),

                          _buildMainSection("PROFESSIONAL SUMMARY", [
                            pw.Text(model.summary,
                                style: const pw.TextStyle(
                                    fontSize: 10, lineSpacing: 1.5)),
                          ]),

                          _buildMainSection("WORK EXPERIENCE", [
                            ...model.experience
                                .map((exp) => _buildExperienceItem(exp)),
                          ]),

                          if (model.education.isNotEmpty)
                            _buildMainSection("EDUCATION", [
                              ...model.education
                                  .map((edu) => _buildEducationItem(edu)),
                            ]),

                          if (model.certificates.isNotEmpty)
                            _buildMainSection("CERTIFICATIONS", [
                              ...model.certificates
                                  .map((cert) => _buildCertItem(cert)),
                            ]),

                          // References (በዳታቤዝህ user_references በሚለው ስም ነው ያለው)
                          if (model.user_references.isNotEmpty)
                            _buildMainSection("REFERENCES", [
                              pw.Wrap(
                                spacing: 20,
                                runSpacing: 15,
                                children: model.user_references
                                    .map((ref) => _buildReferenceItem(ref))
                                    .toList(),
                              ),
                            ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  // --- Helper Widgets (በዳታቤዙ መሰረት የተሰሩ) ---

  pw.Widget _iconText(int iconCode, String text, pw.Font font, PdfColor color) {
    return pw.Row(children: [
      pw.Icon(pw.IconData(iconCode), font: font, size: 10, color: color),
      pw.SizedBox(width: 4),
      pw.Text(text, style: pw.TextStyle(fontSize: 9, color: color)),
    ]);
  }

  pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    final String jobTitle = exp['jobTitle']?.toString() ?? '';
    final String company = exp['companyName']?.toString() ?? '';
    final String startDate = exp['startDate']?.toString() ?? '';
    final String endDate = (exp['isCurrentlyWorking'] == 1)
        ? 'Present'
        : (exp['endDate']?.toString() ?? '');
    final String duration = exp['duration']?.toString() ?? '';
    final String description = exp['jobDescription']?.toString() ?? '';
    final String achievements = exp['achievements']?.toString() ?? '';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Timeline Indicator
          pw.Column(
            children: [
              pw.Container(
                width: 6,
                height: 6,
                decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle, color: primaryColor),
              ),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
            ],
          ),
          pw.SizedBox(width: 10),

          // ዋናው መረጃ
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // መስመር 1: Job Title እና Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (jobTitle.isNotEmpty)
                      pw.Expanded(
                        child: pw.Text(jobTitle,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10.5)),
                      ),
                    if (startDate.isNotEmpty)
                      pw.Text("$startDate - $endDate",
                          style: const pw.TextStyle(
                              fontSize: 8.5, color: PdfColors.grey700)),
                  ],
                ),

                // መስመር 2: Company Name እና Duration (በቀኝ በኩል)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (company.isNotEmpty)
                      pw.Text(company,
                          style: pw.TextStyle(
                              color: primaryColor,
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold)),
                    if (duration.isNotEmpty)
                      pw.Text("($duration)",
                          style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                              fontStyle: pw.FontStyle.italic)),
                  ],
                ),

                if (description.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      description,
                      style: pw.TextStyle(
                        fontSize: 9,
                        lineSpacing: 2,
                      ),
                    ),
                  ),

                if (achievements.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                              text: "Achievement: ",
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.lightGreen)),
                          pw.TextSpan(
                              text: achievements,
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontStyle: pw.FontStyle.italic)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEducationItem(Map<String, dynamic> edu) {
    // 'null' እንዳይመጣ እና ዳታው ንጹህ እንዲሆን
    final String degree = edu['degree']?.toString() ?? '';
    final String field = edu['field']?.toString() ?? '';
    final String school = edu['school']?.toString() ?? '';
    final String gradYear = edu['gradYear']?.toString() ?? '';
    final String cgpa = edu['cgpa']?.toString() ?? '';
    final String project = edu['project']?.toString() ?? '';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Timeline Indicator (ከስራ ልምዱ ጋር አንድ አይነት እንዲሆን)
          pw.Column(
            children: [
              pw.Container(
                width: 6,
                height: 6,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: primaryColor,
                ),
              ),
              pw.Container(width: 1, height: 35, color: PdfColors.grey300),
            ],
          ),
          pw.SizedBox(width: 10),

          // ዋናው መረጃ
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (degree.isNotEmpty || field.isNotEmpty)
                      pw.Expanded(
                        child: pw.Text(
                          "$degree ${field.isNotEmpty ? 'in $field' : ''}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            font: pw.Font
                                .helveticaBold(), // Arial/Helvetica style
                          ),
                        ),
                      ),
                    if (gradYear.isNotEmpty)
                      pw.Text(
                        gradYear,
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700),
                      ),
                  ],
                ),

                if (school.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(
                      school,
                      style: pw.TextStyle(fontSize: 9, color: primaryColor),
                    ),
                  ),

                // CGPA እና Project በአንድ መስመር ወይም በተከታታይ
                pw.Row(
                  children: [
                    if (cgpa.isNotEmpty)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(2)),
                        ),
                        child: pw.Text(
                          "CGPA: $cgpa",
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    if (cgpa.isNotEmpty && project.isNotEmpty)
                      pw.SizedBox(width: 10),
                    if (project.isNotEmpty)
                      pw.Expanded(
                        child: pw.Text(
                          "Project: $project",
                          style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                              fontStyle: pw.FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCertItem(Map<String, dynamic> cert) {
    final String certName = cert['certName']?.toString() ?? '';
    final String org = cert['organization']?.toString() ?? '';
    final String year = cert['year']?.toString() ?? '';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // በአይከን ፋንታ በቀለል ያለ ክብ ተክተነዋል (ስህተቱን ለማጥፋት)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, right: 8),
            child: pw.Container(
              width: 5,
              height: 5,
              decoration: pw.BoxDecoration(
                color: primaryColor,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),

          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (certName.isNotEmpty)
                      pw.Expanded(
                        child: pw.Text(
                          certName,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                        ),
                      ),
                    if (year.isNotEmpty)
                      pw.Text(
                        year,
                        style: const pw.TextStyle(
                            fontSize: 8.5, color: PdfColors.grey700),
                      ),
                  ],
                ),
                if (org.isNotEmpty)
                  pw.Text(
                    org,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      color: primaryColor,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReferenceItem(Map<String, dynamic> ref) {
    return pw.Container(
      width: 150,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(ref['name'] ?? '',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
          pw.Text("${ref['job']} at ${ref['organization']}",
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
          pw.Text("Ph: ${ref['phone']}",
              style: const pw.TextStyle(fontSize: 8)),
          pw.Text("Email: ${ref['email']}",
              style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildLanguageItem(Map<String, dynamic> l) {
    final String level = l['level']?.toString() ?? '';
    final String levelLower = level.toLowerCase();

    int dotCount = 0;
    if (levelLower.contains('native') || levelLower.contains('fluent')) {
      dotCount = 5;
    } else if (levelLower.contains('advanced')) {
      dotCount = 4;
    } else if (levelLower.contains('intermediate')) {
      dotCount = 3;
    } else if (levelLower.contains('elementary') ||
        levelLower.contains('basic')) {
      dotCount = 2;
    } else if (level.isNotEmpty) {
      dotCount = 1;
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(l['name'] ?? '',
              style: pw.TextStyle(color: PdfColors.black, fontSize: 9)),
          pw.Row(
            children: [
              // ነጥቦቹ
              if (dotCount > 0)
                pw.Row(
                  children: List.generate(5, (index) {
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(right: 2),
                      width: 5,
                      height: 5,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: index < dotCount
                            ? PdfColors.lightGreen
                            : PdfColors.grey300,
                      ),
                    );
                  }),
                ),
              // ደረጃው በጽሑፍ (ካለ ብቻ)
              if (level.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 5),
                  child: pw.Text("($level)",
                      style: const pw.TextStyle(
                          fontSize: 7, color: PdfColors.grey700)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSkillStars(Map<String, dynamic> s) {
    final String level = s['level']?.toString().toLowerCase() ?? '';

    // የከዋክብት ብዛት መወሰኛ (Expert=5, Advanced=4, Intermediate=3, ወዘተ)
    int starCount = 1;
    if (level.contains('expert')) {
      starCount = 5;
    } else if (level.contains('advanced')) {
      starCount = 4;
    } else if (level.contains('intermediate')) {
      starCount = 3;
    } else if (level.contains('beginner') || level.contains('basic')) {
      starCount = 2;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // የክህሎቱ ስም
          pw.Expanded(
            child: pw.Text(s['name'] ?? '',
                style: pw.TextStyle(color: PdfColors.black, fontSize: 9)),
          ),
          // ከዋክብቱን መሳያ
          pw.Row(
            children: List.generate(5, (index) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 2),
                child: pw.Container(
                  width: 8,
                  height: 8,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle, // ወይም ኮከብ ቅርጽ መጠቀም ይቻላል
                    color: index < starCount
                        ? PdfColors.lightGreen
                        : PdfColors.grey300,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMainSection(String title, List<pw.Widget> children) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor)),
          pw.SizedBox(height: 3),
          pw.Container(height: 1, color: PdfColors.grey200),
          pw.SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildSidebarSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
                fontSize: 11)),
        pw.SizedBox(height: 5),
        pw.Container(height: 0.5, color: PdfColors.white),
        pw.SizedBox(height: 10),
        ...children,
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _sidebarItem(int iconCode, String text, pw.Font iconFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        children: [
          pw.Icon(pw.IconData(iconCode),
              font: iconFont, color: PdfColors.white, size: 10),
          pw.SizedBox(width: 10),
          pw.Expanded(
              child: pw.Text(text,
                  style:
                      const pw.TextStyle(color: PdfColors.black, fontSize: 9))),
        ],
      ),
    );
  }

  pw.Widget _buildCircularProfile(pw.ImageProvider? img) {
    return pw.Container(
      width: 100,
      height: 100,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: PdfColors.grey200,
        border: pw.Border.all(color: PdfColors.white, width: 3),
        image: img != null
            ? pw.DecorationImage(image: img, fit: pw.BoxFit.cover)
            : null,
      ),
      child: img == null
          ? pw.Center(
              child: pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  pw.Text(
                    "CV",
                    style: pw.TextStyle(
                      fontSize: 34,
                      fontWeight: pw.FontWeight.bold,
                      font: pw.Font.helveticaBold(), // Arial-like font
                      color: const PdfColor(0.2, 0.2, 0.2, 0.4),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3, right: 3),
                    child: pw.Text(
                      "CV",
                      style: pw.TextStyle(
                        fontSize: 34,
                        fontWeight: pw.FontWeight.bold,
                        font: pw.Font.helveticaBold(), // Arial-like font
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
