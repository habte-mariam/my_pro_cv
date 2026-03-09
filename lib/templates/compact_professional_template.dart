import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../cv_model.dart';
import '../app_fonts.dart';

class CVThemeConfig {
  final PdfColor primary; // ዋናው ቀለም (ለምሳሌ ሰማያዊ)
  final PdfColor sidebarBg; // የሳይድባሩ ቀለም
  final PdfColor textMain; // የጽሁፍ ቀለም
  final String fontFamily; // የፎንት አይነት
  final double scale; // የሳይዝ ማስተካከያ (0.8, 1.0, 1.2...)

  CVThemeConfig({
    required this.primary,
    required this.sidebarBg,
    required this.textMain,
    required this.fontFamily,
    this.scale = 1.0,
  });
}

class CompactProfessionalTemplate {
  final CvModel model;
  final CVThemeConfig config; // ይህ መኖሩን አረጋግጥ

  CompactProfessionalTemplate({
    required this.model,
    required this.config,
  });

  Future<pw.Document> generate() async {
    final pdf = pw.Document();

    final iconData =
        await rootBundle.load("assets/fonts/MaterialIcons-Regular.ttf");
    final iconFont = pw.Font.ttf(iconData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // --- የግራ ክፍል (Sidebar) ---
                pw.Container(
                  width: 190,
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF5F5F5),
                    borderRadius: pw.BorderRadius.only(
                      topRight: pw.Radius.circular(40),
                      bottomRight: pw.Radius.circular(40),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 18, vertical: 30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildProfileImage(),
                      pw.SizedBox(height: 25),
                      _buildSidebarHeader("CONTACT"),
                      _buildContactSubHeader("Personal"),
                      _buildContactInfo(0xe0b0, model.phone, iconFont),
                      if (model.phone2.isNotEmpty)
                        _buildContactInfo(0xe0cd, model.phone2, iconFont),
                      _buildContactInfo(0xe7e9, model.age, iconFont),
                      _buildContactInfo(0xe7ff, model.gender, iconFont),
                      _buildContactSubHeader("Address"),
                      _buildContactInfo(0xe0be, model.email, iconFont),
                      _buildContactInfo(0xe0c8, model.address, iconFont),
                      _buildContactInfo(0xe55d, model.nationality, iconFont),
                      if (model.linkedin.isNotEmpty ||
                          model.portfolio.isNotEmpty) ...[
                        _buildContactSubHeader("Social"),
                        if (model.linkedin.isNotEmpty)
                          _buildContactInfo(
                              0xe150, "LinkedIn Profile", iconFont,
                              url: model.linkedin),
                        if (model.portfolio.isNotEmpty)
                          _buildContactInfo(
                              0xe894, "Personal Portfolio", iconFont,
                              url: model.portfolio),
                      ],
                      pw.SizedBox(height: 25),
                      _buildSidebarHeader("EDUCATION"),
                      ...model.education.map(
                          (edu) => _buildSidebarEducationItem(edu, iconFont)),
                      if (model.certificates.isNotEmpty) ...[
                        pw.SizedBox(height: 25),
                        _buildSidebarHeader("CERTIFICATES"),
                        ...model.certificates.map((cert) =>
                            _buildSidebarCertificateItem(cert, iconFont)),
                      ],
                    ],
                  ),
                ),

                // --- የቀኝ ክፍል (Main Content) ---
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(40),
                        bottomLeft: pw.Radius.circular(40),
                      ),
                    ),
                    padding: const pw.EdgeInsets.fromLTRB(30, 40, 25, 30),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // 1. ስም
                        pw.Text(
                          "${model.firstName} ${model.lastName}".toUpperCase(),
                          style: _buildStyle(
                              size: 26, isBold: true, color: config.primary),
                        ),
                        // 2. የስራ መደብ
                        pw.Text(
                          model.jobTitle.toUpperCase(),
                          style:
                              _buildStyle(size: 12.5, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 20),
                        // 3. ማጠቃለያ
                        _buildSectionTitle("PROFESSIONAL SUMMARY"),
                        pw.Text(
                          model.summary,
                          textAlign: pw.TextAlign.justify,
                          style: _buildStyle(size: 11.5),
                        ),
                        pw.SizedBox(height: 20),
                        // 4. የስራ ልምድ
                        _buildSectionTitle("WORK EXPERIENCE"),
                        ...model.experience
                            .map((exp) => _buildExperienceItem(exp)),
                        pw.SizedBox(height: 20),
                        // 5. ክህሎቶች
                        _buildSectionTitle("SKILLS"),
                        pw.Wrap(
                          spacing: 15,
                          runSpacing: 10,
                          children: model.skills
                              .map((s) => pw.SizedBox(
                                    width: 140,
                                    child: _buildSkillItem(s, false, iconFont),
                                  ))
                              .toList(),
                        ),
                        pw.SizedBox(height: 20),
                        // 6. ቋንቋዎች
                        _buildSectionTitle("LANGUAGES"),
                        pw.Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: model.languages.map((l) {
                            final String name = l['name'] ?? '';
                            final String? level = l['level'];
                            return pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                    color: PdfColors.grey300, width: 0.5),
                                borderRadius: const pw.BorderRadius.all(
                                    pw.Radius.circular(4)),
                              ),
                              child: pw.Row(
                                mainAxisSize: pw.MainAxisSize.min,
                                children: [
                                  pw.Text(name,
                                      style:
                                          _buildStyle(size: 9.5, isBold: true)),
                                  if (level != null && level.isNotEmpty) ...[
                                    pw.SizedBox(width: 4),
                                    pw.Text("| $level",
                                        style: _buildStyle(
                                            size: 9, color: PdfColors.grey700)),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        // 7. ሪፈረንስ
                        if (model.user_references.isNotEmpty) ...[
                          pw.SizedBox(height: 20),
                          _buildSectionTitle("REFERENCES"),
                          pw.Wrap(
                            spacing: 20,
                            runSpacing: 15,
                            children: model.user_references.map((ref) {
                              return pw.SizedBox(
                                width: 155,
                                child: _buildReferenceItem(ref, iconFont),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );
    return pdf;
  }

// --- Sidebar Helpers ---
  PdfColor getContrastColor(PdfColor background) {
    // የከለሩን ብሩህነት (Luminance) በመጠቀም ተነባቢነቱን ማረጋገጥ
    final double luminance = (0.299 * background.red) +
        (0.587 * background.green) +
        (0.114 * background.blue);
    return luminance > 0.5 ? PdfColors.black : PdfColors.white;
  }

// ፎንት፣ ሳይዝ እና ቀለምን በአንድ ላይ የሚቆጣጠር ረዳት
// ስሙን ከ _s ወደ _buildStyle ቀይረነዋል
  pw.TextStyle _buildStyle(
      {double size = 11,
      bool isBold = false,
      bool isItalic = false,
      PdfColor? color}) {
    return AppFonts.getStyle(
      text: "s",
      size: size * (config.scale),
      isBold: isBold,
      isItalic: isItalic,
      color: color ?? config.textMain,
      preferredFamily: config.fontFamily,
    );
  }

  pw.Widget _buildSidebarEducationItem(
      Map<String, dynamic> edu, pw.Font iconFont) {
    // ቀለሙን በቀጥታ ጥቁር እናደርገዋለን
    const PdfColor textBlack = PdfColors.black;
    const PdfColor subTextBlack = PdfColors.grey900;

    // "Class of" Logic
    String displayYear = edu['gradYear'] ?? '';
    if (displayYear.isNotEmpty) {
      final int? yearInt = int.tryParse(displayYear);
      if (yearInt != null && yearInt > 12) {
        displayYear = "Class of $displayYear";
      } else if (!displayYear.toLowerCase().contains("grade") &&
          !displayYear.contains("-")) {
        displayYear = "Class of $displayYear";
      }
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // --- Sidebar Timeline ---
          pw.Column(
            children: [
              pw.Container(
                width: 6,
                height: 6,
                decoration: const pw.BoxDecoration(
                  color: textBlack, // ጥቁር ነጥብ
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Container(
                width: 0.8,
                height: 60,
                color: PdfColors.grey400, // ቀጭን ግራጫ መስመር
              ),
            ],
          ),
          pw.SizedBox(width: 10),

          // --- መረጃው ---
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. ዲግሪ እና ፊልድ (ተያይዘው እንዲወጡ)
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      // ዲግሪ (ለምሳሌ፡ BSC)
                      pw.TextSpan(
                        text: (edu['degree'] ?? '').toUpperCase(),
                        style: _buildStyle(
                          size: 12.5,
                          isBold: true,
                          color:
                              textBlack, // 'textBlack' የሚለው ቫሪያብል ከላይ መኖሩን አረጋግጥ
                        ),
                      ),

                      // " IN " የሚለው ቃል (ፊልድ ካለ ብቻ ይታያል)
                      if (edu['field'] != null &&
                          edu['field'].toString().isNotEmpty)
                        pw.TextSpan(
                          text: " IN ",
                          style: _buildStyle(
                            size: 11,
                            isBold: true,
                            color: config
                                .textMain, // በ 'textBlack' ፋንታ 'config.textMain' መጠቀም ይመረጣል
                          ),
                        ),

                      // የትምህርት ዘርፉ (ለምሳሌ፡ COMPUTER SCIENCE)
                      if (edu['field'] != null &&
                          edu['field'].toString().isNotEmpty)
                        pw.TextSpan(
                          text: edu['field'].toString().toUpperCase(),
                          style: _buildStyle(
                            size: 11.5,
                            isBold: true,
                            color: config
                                .textMain, // በ 'subTextBlack' ፋንታ ይህንን መጠቀም ይሻላል
                          ),
                        ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 3), // በዲግሪው እና በሚቀጥለው መረጃ መካከል ያለ ክፍተት
                // 3. ትምህርት ቤት ስም
                pw.Row(
                  children: [
                    pw.Text(String.fromCharCode(0xe80c), // School icon
                        style: pw.TextStyle(
                            font: iconFont, fontSize: 8, color: textBlack)),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                      child: pw.Text(
                        edu['school'] ?? '',
                        style: _buildStyle(
                          size: 11,
                          isBold: true,
                          color: config
                              .textMain, // በ 'textBlack' ፋንታ 'config.textMain' መጠቀም ይመረጣል
                        ),
                      ),
                    ),
                  ],
                ),

                // 4. CGPA & Year
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (displayYear.isNotEmpty)
                      pw.Text(
                        displayYear,
                        style: _buildStyle(
                          size: 11,
                          isBold: true,
                          color:
                              subTextBlack, // እዚህ ጋር 'subTextBlack' የሚለው ቫሪያብል ከላይ መኖሩን አረጋግጥ
                        ),
                      ),
                    if (edu['cgpa'] != null &&
                        edu['cgpa'].toString().isNotEmpty)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: const pw.BoxDecoration(
                          color: textBlack, // ጥቁር ባጅ
                          borderRadius:
                              pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text(
                          "GPA: ${edu['cgpa']}",
                          style: _buildStyle(
                            size: 11.5,
                            isBold: true,
                            color: PdfColors
                                .white, // ነጭነቱ እንዲቀጥል እዚህ ጋር በግልጽ እንጽፈዋለን
                          ),
                        ),
                      ),
                  ],
                ),

                // 5. Project (Italic & Bold)
                if (edu['project'] != null &&
                    edu['project'].toString().isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      "Project: ${edu['project']}",
                      style: _buildStyle(
                        size: 9.5,
                        isBold: true,
                        isItalic: true,
                        color: config
                            .textMain, // ወይም PdfColors.grey700 ለደብዘዝ ያለ ቀለም
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

  pw.Widget _buildSidebarCertificateItem(
      Map<String, dynamic> cert, pw.Font iconFont) {
    const PdfColor textBlack = PdfColors.black;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 1. አይኮን እና የሰርተፍኬት ስም
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                String.fromCharCode(0xe80b), // Verified/Award badge icon
                style: pw.TextStyle(
                  font: iconFont,
                  fontSize: 11,
                  color: textBlack,
                ),
              ),
              pw.SizedBox(width: 5),
              pw.Expanded(
                child: pw.Text(
                  cert['certName'] ?? '',
                  style: _buildStyle(
                    size: 11.5,
                    isBold: true,
                    color: config.textMain, // textBlack በሚለው ፋንታ
                  ),
                ),
              ),
            ],
          ),

          // 2. ተቋሙ (Organization) - ትንሽ ገባ ብሎ (Padding)
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 15),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  cert['organization'] ?? '',
                  style: _buildStyle(
                    size: 11.5,
                    isBold: true,
                    color: PdfColors.grey800, // ቀለሙን እንዳለ እንዲቀጥል አድርገነዋል
                  ),
                ),

                // 3. አመት (Year)
                if (cert['year'] != null && cert['year'].toString().isNotEmpty)
                  pw.Text(
                    cert['year'].toString(),
                    style: _buildStyle(
                      size: 11,
                      isBold: true,
                      color: config.textMain, // በ 'textBlack' ፋንታ
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReferenceItem(Map<String, dynamic> ref, pw.Font iconFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // የሪፈረንሱ ስም
          pw.Text(
            ref['name'] ?? '',
            style: _buildStyle(size: 10.5, isBold: true, color: config.primary),
          ),

          // የስራ መደብ እና ድርጅት
          pw.Row(
            children: [
              pw.Text(String.fromCharCode(0xe8f9),
                  style: pw.TextStyle(
                      font: iconFont, fontSize: 8, color: PdfColors.grey600)),
              pw.SizedBox(width: 4),
              pw.Text(
                "${ref['job']} @ ${ref['organization']}",
                style: _buildStyle(size: 10, color: PdfColors.grey700),
              ),
            ],
          ),

          pw.SizedBox(height: 3),

          // ስልክ እና ኢሜይል
          pw.Wrap(
            spacing: 10,
            children: [
              // ስልክ
              if (ref['phone']?.toString().isNotEmpty ?? false)
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(String.fromCharCode(0xe0b0),
                        style: pw.TextStyle(
                            font: iconFont,
                            fontSize: 8,
                            color: config.primary)),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      ref['phone'],
                      style: _buildStyle(size: 7.5),
                    ),
                  ],
                ),

              // ኢሜይል
              if (ref['email']?.toString().isNotEmpty ?? false)
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(String.fromCharCode(0xe158),
                        style: pw.TextStyle(
                            font: iconFont,
                            fontSize: 8,
                            color: config.primary)),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      ref['email'],
                      style: _buildStyle(size: 7.5),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProfileImage() {
    const double size = 100;
    if (model.profileImagePath.isNotEmpty &&
        File(model.profileImagePath).existsSync()) {
      return pw.Center(
        child: pw.Container(
          width: size,
          height: size,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: PdfColors.white, width: 2),
            image: pw.DecorationImage(
                image: pw.MemoryImage(
                    File(model.profileImagePath).readAsBytesSync()),
                fit: pw.BoxFit.cover),
          ),
        ),
      );
    }
    return pw.Center(
      child: pw.Container(
        width: size,
        height: size,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: PdfColors.white, width: 1.5),
          gradient: const pw.RadialGradient(
              colors: [PdfColors.grey400, PdfColors.grey700],
              stops: [0.3, 1.0]),
        ),
        child: pw.Text(
          "CV",
          style: _buildStyle(
            size: 34,
            isBold: true,
            color: config.primary, // 'primaryColor' ወደ 'config.primary' ተቀይሯል
          ),
        ),
      ),
    );
  }

  pw.Widget _buildSidebarHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: _buildStyle(
              size: 12.5,
              isBold: true,
              color: PdfColors.black,
            ),
          ),
          pw.Container(
            width: 20,
            height: 2,
            color: config.primary, // 'primaryColor' ወደ 'config.primary' ተቀይሯል
          ),
        ],
      ),
    );
  }

  pw.Widget _buildContactSubHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 15, bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.Container(
            width: 30,
            height: 1,
            color: PdfColors.grey400,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildContactInfo(int codePoint, String value, pw.Font iconFont,
      {String? url}) {
    final PdfColor textColor = url != null ? PdfColors.blue : PdfColors.black;

    final content = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: 15,
          child: pw.Text(String.fromCharCode(codePoint),
              style: pw.TextStyle(
                  font: iconFont, fontSize: 10, color: PdfColors.black)),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            value, // እዚህ ጋር 'value' መሆን አለበት
            style: _buildStyle(
              size: 9, // ለኮንታክት መረጃ ትንሽ ሳይዝ ይሻላል
              color: textColor,
            ),
          ),
        ),
      ],
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child:
          url != null ? pw.UrlLink(destination: url, child: content) : content,
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: _buildStyle(
            size: 12,
            isBold: true,
            color: config.primary, // 'primaryColor' ወደ 'config.primary' ተቀይሯል
          ),
        ),
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 5),
      ],
    );
  }

  pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    List<String> achievementList = [];
    if (exp['achievements'] != null &&
        exp['achievements'].toString().trim().isNotEmpty) {
      achievementList = exp['achievements']
          .toString()
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }

    final String dateRange =
        (exp['startDate'] != null || exp['endDate'] != null)
            ? "${exp['startDate'] ?? ''} - ${exp['endDate'] ?? ''}"
            : "";

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 0),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // --- Timeline በስተግራ ---
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Column(
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: pw.BoxDecoration(
                    color: config.primary, // config ተጠቀምን
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Container(
                  width: 1,
                  height: 35,
                  color: PdfColors.grey300,
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),

          // --- መረጃው በስተቀኝ ---
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. Job Title & Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        exp['jobTitle'] ?? 'Position Title',
                        style: _buildStyle(
                            size: 12, isBold: true), // ረዳት ሜቶዱን ተጠቀምን
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      dateRange,
                      style: _buildStyle(
                        size: 11.5,
                        isBold: true,
                        color: config.primary, // ደማቅ ቀን በ config color
                      ),
                    ),
                  ],
                ),

                // 2. Company Name & Duration
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      exp['companyName'] ?? '',
                      style: _buildStyle(
                        size: 12,
                        isBold: true,
                        color: PdfColors.grey700,
                      ),
                    ),
                    if (exp['duration'] != null &&
                        exp['duration'].toString().isNotEmpty)
                      pw.Text(
                        "(${exp['duration']})",
                        style: _buildStyle(size: 10),
                      ),
                  ],
                ),

                pw.SizedBox(height: 5),

                // 3. Job Description
                if (exp['jobDescription'] != null &&
                    exp['jobDescription'].toString().isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Text(
                      exp['jobDescription'],
                      style: _buildStyle(size: 10.5),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ),

                // 4. Achievements
                if (achievementList.isNotEmpty)
                  ...achievementList.map((achievement) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 4, bottom: 3),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.only(top: 3.5, right: 6),
                              child: pw.Container(
                                width: 3,
                                height: 3,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.grey600,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                achievement.trim(),
                                style: _buildStyle(size: 10.5),
                                textAlign: pw.TextAlign.justify,
                              ),
                            ),
                          ],
                        ),
                      )),
                pw.SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSkillItem(
      Map<String, dynamic> skill, bool isSidebar, pw.Font iconFont) {
    int starCount = 0;

    // 1. መጀመሪያ ተለዋዋጩን እዚህ ጋር ፍጠር
    String level = "";

    if (skill['level'] != null) {
      // 2. እዚህ ጋር እሴቱን (Value) ስጠው
      level = skill['level'].toString().toLowerCase();

      // 3. አሁን 'level' መታወቅ ስለቻለ እነዚህ ስራ ይሰራሉ
      if (level.contains('expert')) {
        starCount = 5;
      } else if (level.contains('intermediate')) {
        starCount = 3;
      } else if (level.contains('beginner')) {
        starCount = 2;
      }
    }

    // የጽሁፍ ቀለም
    final PdfColor textColor = isSidebar ? PdfColors.black : config.textMain;
    final PdfColor emptyStarColor =
        isSidebar ? PdfColors.grey400 : PdfColors.grey300;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // 1. የክህሎቱ ስም
          pw.Expanded(
            child: pw.Text(
              skill['name'] ?? '',
              style: _buildStyle(
                size: 11, // ሳይዙን ትንሽ አነስ ብናደርገው ለ Wrap ምቹ ይሆናል
                isBold: true,
                color: textColor,
              ),
            ),
          ),

          // 2. ኮከቦቹ
          if (starCount > 0)
            pw.Row(
              children: List.generate(5, (index) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 1),
                  child: pw.Text(
                    String.fromCharCode(0xe838),
                    style: pw.TextStyle(
                      font: iconFont,
                      fontSize: 10,
                      color: index < starCount
                          ? config.primary // የሞላው ኮከብ በሲቪው ዋና ቀለም እንዲሆን
                          : emptyStarColor,
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
