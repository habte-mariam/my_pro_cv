import 'dart:io';

import 'package:flutter/services.dart';
import 'package:my_new_cv/app_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../cv_model.dart';

class MinimalistSplitTemplate {
  final CvModel model;
  final PdfColor primaryColor;
  final String fontFamily;
  final double scale;

  MinimalistSplitTemplate({
    required this.model,
    required this.primaryColor,
    required this.fontFamily,
    this.scale = 1.0,
  });

  pw.TextStyle _buildStyle({
    required double size,
    bool isBold = false,
    bool isItalic = false, // 1. እዚህ ጋር ፓራሜትሩን ጨምረናል
    PdfColor color = PdfColors.black,
    double? letterSpacing,
    String text = "",
  }) {
    final style = AppFonts.getStyle(
      size: size * scale,
      color: color,
      isBold: isBold,
      isItalic:
          isItalic, // 2. እዚህ ጋር 'bool' የሚለውን ቃል አስወግደናል (ስህተት የነበረው እሱ ነው)
      preferredFamily: fontFamily,
      text: text,
    );

    return letterSpacing != null
        ? style.copyWith(letterSpacing: letterSpacing)
        : style;
  }

  Future<pw.Document> generate() async {
    final pdf = pw.Document();

    // 1. የ Material Icons ፎንትን መጫን
    final iconFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/MaterialIcons-Regular.ttf"));

    // 2. ፕሮፋይል ፎቶውን ማዘጋጀት
    pw.MemoryImage? profileImage;
    if (model.profileImagePath.isNotEmpty) {
      final imageFile = File(model.profileImagePath);
      if (await imageFile.exists()) {
        profileImage = pw.MemoryImage(await imageFile.readAsBytes());
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) => [
          // --- 1. Header Section ---
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(40, 40, 40, 20),
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (profileImage != null)
                  pw.Container(
                    width: 100,
                    height: 100,
                    margin: const pw.EdgeInsets.only(bottom: 15),
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.rectangle,
                      borderRadius: pw.BorderRadius.circular(8),
                      image: pw.DecorationImage(
                        image: profileImage,
                        fit: pw.BoxFit.cover,
                      ),
                      border: pw.Border.all(color: primaryColor, width: 2),
                    ),
                  ),
                pw.Text(
                  "${model.firstName} ${model.lastName}".toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: _buildStyle(
                    size: 28,
                    isBold: true,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  model.jobTitle.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: _buildStyle(
                      size: 14, color: PdfColors.grey700, isBold: true),
                ),
              ],
            ),
          ),

          pw.Partitions(
            children: [
              // --- 2. Sidebar (Auto-sizing logic applied) ---
              pw.Partition(
                // እዚህ ጋር widthን እንደ አስፈላጊነቱ በ scale ማባዛት ይቻላል
                width: 190 * scale,
                child: pw.Container(
                  // auto-size እንዲሆን minHeightን እናስወግደዋለን ወይም በይዘቱ ልክ እንዲሆን እናደርጋለን
                  margin:
                      const pw.EdgeInsets.only(left: 20, right: 10, bottom: 20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF8F9FA),
                    borderRadius: pw.BorderRadius.circular(15),
                  ),
                  padding: const pw.EdgeInsets.all(
                      15), // paddingን ትንሽ ቀነስ አድርገነዋል ለተሻለ auto-size
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisSize: pw.MainAxisSize.min, // ይዘቱ ባለበት ብቻ እንዲቆም
                    children: [
                      _buildSidebarSection("CONTACT", [
                        _sidebarItem(model.phone, 0xe0b0, iconFont),
                        if (model.phone2.isNotEmpty)
                          _sidebarItem(model.phone2, 0xe88a, iconFont),
                        if (model.email.isNotEmpty)
                          _sidebarItem(model.email, 0xe158, iconFont),
                        if (model.address.isNotEmpty)
                          _sidebarItem(model.address, 0xe0c8, iconFont),
                        if (model.linkedin.isNotEmpty)
                          _sidebarItem("LinkedIn", 0xe894, iconFont),
                        if (model.portfolio.isNotEmpty)
                          _sidebarItem("Portfolio", 0xe0e1, iconFont),
                      ]),
                      if (model.nationality.isNotEmpty ||
                          model.gender.isNotEmpty ||
                          model.age.isNotEmpty)
                        _buildSidebarSection("DETAILS", [
                          if (model.nationality.isNotEmpty)
                            _sidebarDetailItemWithIcon("Nationality",
                                model.nationality, 0xe894, iconFont),
                          if (model.gender.isNotEmpty)
                            _sidebarDetailItemWithIcon(
                                "Gender", model.gender, 0xe63d, iconFont),
                          if (model.age.isNotEmpty)
                            _sidebarDetailItemWithIcon(
                                "Age", model.age, 0xe916, iconFont),
                        ]),
                      if (model.skills.isNotEmpty)
                        _buildSidebarSection(
                            "SKILLS",
                            model.skills
                                .map((s) => _skillItem(s['name'], s['level']))
                                .toList()),
                      if (model.languages.isNotEmpty)
                        _buildSidebarSection(
                            "LANGUAGES",
                            model.languages
                                .map((l) =>
                                    _sidebarText(l['name'] ?? l.toString()))
                                .toList()),
                      if (model.certificates.isNotEmpty)
                        _buildSidebarSection(
                            "CERTIFICATES",
                            model.certificates
                                .map((c) => _certificateSidebarItem(c))
                                .toList()),
                    ],
                  ),
                ),
              ),

              // --- 3. Main Content Section ---
              pw.Partition(
                child: pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(15, 0, 35, 40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (model.summary.isNotEmpty)
                        _buildMainSection("PROFESSIONAL SUMMARY", [
                          pw.Text(model.summary,
                              style: _buildStyle(size: 10.5),
                              textAlign: pw.TextAlign.justify),
                        ]),
                      if (model.experience.isNotEmpty)
                        _buildMainSection(
                          "WORK EXPERIENCE",
                          model.experience
                              .map((exp) => _buildExperienceItem(exp))
                              .toList(),
                        ),
                      if (model.education.isNotEmpty)
                        _buildMainSection(
                          "EDUCATION",
                          model.education
                              .map((edu) => _buildEducationItem(edu))
                              .toList(),
                        ),
                      if (model.user_references.isNotEmpty)
                        _buildMainSection("REFERENCES", [
                          pw.Wrap(
                            spacing: 15,
                            runSpacing: 10,
                            children: model.user_references
                                .map((r) => _buildReferenceItem(r, iconFont))
                                .toList(),
                          )
                        ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildSidebarSection(String title, List<pw.Widget> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            // በ opacity ፋንታ የግራ መስመርን (Accent) ብቻ በመጠቀም ጽሑፉን እናድምቀው
            border: pw.Border(
              left: pw.BorderSide(color: primaryColor, width: 3),
            ),
            // ቀለሙን በ Hex ዋጋ በትንሹ እንዲታይ ማድረግ (ለምሳሌ፡ 20% opacity)
            color: primaryColor.shade(100),
          ),
          child: pw.Text(
            title.toUpperCase(),
            style: _buildStyle(
              size: 11,
              isBold: true,
              color: PdfColors.white, // ጥቁር ዳራ (Dark Navy) ላይ ስለሆነ ነጭ ይሁን
              text: title,
            ),
          ),
        ),
        pw.SizedBox(height: 2),
        ...items,
        pw.SizedBox(height: 5),
      ],
    );
  }

  pw.Widget _skillItem(String name, String level) {
    int starCount = 0;
    String lvl = level.toLowerCase();

    // የደረጃ አወሳሰን (Logic)
    if (lvl.contains('expert')) {
      starCount = 5;
    } else if (lvl.contains('advanced')) {
      starCount = 4;
    } else if (lvl.contains('inter')) {
      starCount = 3;
    } else if (lvl.contains('begin') || lvl.isNotEmpty) {
      starCount = 2;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        // 👈 ከጎን ለጎን ለማድረግ ወደ Row ተቀይሯል
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween, // 👈 ስሙን እና ኮከቡን ያራርቃል
        children: [
          // 1. የክህሎቱ ስም
          pw.Expanded(
            // 👈 ስሙ ረጅም ከሆነ ኮከቡን እንዳይገፋው
            child: pw.Text(
              name,
              style: _buildStyle(
                size: 9,
                color: PdfColors.black,
                text: name,
              ),
            ),
          ),

          // 2. ኮከቦቹ (ደረጃው ካለ ብቻ)
          if (starCount > 0)
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: List.generate(5, (index) {
                return pw.Container(
                  margin:
                      const pw.EdgeInsets.only(left: 2), // 👈 በኮከቦች መካከል ክፍተት
                  width: 5,
                  height: 5,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    // የተመረጠው primaryColor እዚህ ጋር ይሰራል
                    color: index < starCount ? primaryColor : PdfColors.grey800,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  // --- Main Content Helpers ---
  pw.Widget _buildMainSection(String title, List<pw.Widget> items) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 25),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // 1. የግራ "L" ቅርጽ ያለው ዲዛይን
              pw.Container(
                width: 12,
                height: 22,
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: primaryColor, width: 3),
                    top: pw.BorderSide(color: primaryColor, width: 3),
                  ),
                ),
              ),

              // 2. ዋናው ርዕስ (መሃል ላይ)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                child: pw.Text(
                  title.toUpperCase(),
                  style: _buildStyle(
                    size: 15,
                    isBold: true,
                    color: PdfColor.fromInt(0xFF1E293B),
                    text: title,
                  ),
                ),
              ),

              // 3. የቀኝ "L" ቅርጽ (የተገለበጠ) - "Xerfref" እንዲሆን
              pw.Expanded(
                child: pw.Container(
                  height: 10,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                      // እዚህ ጋር ?? የሚለውን እና ተከታዩን አጥፋው
                      right: pw.BorderSide(color: primaryColor, width: 3),
                    ),
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 0),

          // የይዘቱ ክፍል (Items)
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12), // ከግራው መስመር ጋር እንዲሰለፍ
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: items,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    final String description = exp['jobDescription'] ?? "";
    final List<String> descBullets = description
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    final String achievements = exp['achievements'] ?? "";
    final List<String> achiBullets = achievements
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Stack(
        children: [
          // 1. የTimeline መስመር (ከጀርባ የሚቀመጥ)
          // IntrinsicHeight ስለሌለ Positioned.fill በመጠቀም ቁመቱን እንዲያውቅ እናደርጋለን
          pw.Positioned.fill(
            child: pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                margin: const pw.EdgeInsets.only(
                    right: 72.5, top: 10), // ከቀኑ ጽሁፍ ጋር ለማስተካከል
                width: 1,
                color: PdfColors.grey300,
              ),
            ),
          ),

          // 2. ዋናው ይዘት (Row)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- የግራ ክፍል፡ የስራ ዝርዝር ---
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      exp['jobTitle'] ?? "",
                      style: _buildStyle(size: 10.5, isBold: true),
                    ),
                    pw.Text(
                      exp['companyName'] ?? "",
                      style:
                          _buildStyle(size: 9.5, color: PdfColors.blueGrey800),
                    ),
                    if (descBullets.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 5),
                        child: pw.Column(
                          children: descBullets
                              .map((point) => pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 2),
                                    child: pw.Bullet(
                                      text: point.trim(),
                                      style: _buildStyle(size: 9),
                                      bulletSize: 2.5,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    if (achiBullets.isNotEmpty) ...[
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 6),
                        child: pw.Text("Key Achievements:",
                            style: _buildStyle(
                                size: 8.5,
                                isBold: true,
                                color: PdfColors.blue900)),
                      ),
                      pw.Column(
                        children: achiBullets
                            .map((point) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 2),
                                  child: pw.Bullet(
                                    text: point.trim(),
                                    style: _buildStyle(size: 9),
                                    bulletSize: 2.5,
                                    bulletColor: PdfColors.blue700,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // --- የመካከለኛ ክፍል፡ የTimeline ነጥብ ---
              pw.Container(
                width: 25,
                alignment: pw.Alignment.topCenter,
                child: pw.Container(
                  width: 6,
                  height: 6,
                  margin: const pw.EdgeInsets.only(top: 4),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
              ),

              // --- የቀኝ ክፍል፡ አመተ ምህረት ---
              pw.SizedBox(
                width: 60,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${exp['startDate'] ?? ''}\n${exp['isCurrentlyWorking'] == 1 ? 'Present' : (exp['endDate'] ?? '')}",
                      style: _buildStyle(
                          size: 8, isBold: true, color: PdfColors.blueGrey900),
                    ),
                    if (exp['duration'] != null &&
                        exp['duration'].toString().isNotEmpty)
                      pw.Text(
                        "(${exp['duration']})",
                        style: _buildStyle(
                            size: 7, color: PdfColors.red900, isItalic: true),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// --- 2. Reference Item (With Icons & Null-Safe) ---
  pw.Widget _buildReferenceItem(Map<String, dynamic> ref, pw.Font iconFont) {
    // ዳታዎችን ከ Map ውስጥ ማውጣት (Null safe በሆነ መንገድ)
    final String name = ref['name']?.toString() ?? '';
    final String job = ref['job']?.toString() ?? '';
    final String org = ref['organization']?.toString() ?? '';
    final String phone = ref['phone']?.toString() ?? '';
    final String email = ref['email']?.toString() ?? '';

    return pw.Container(
      width: 160, // በ Wrap ውስጥ በቂ ቦታ እንዲኖረው
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 1. ስም (Bold)
          pw.Text(name,
              style: _buildStyle(
                  size: 9.5, isBold: true, color: PdfColors.blue900)),

          // 2. የስራ መደብ እና ድርጅት (ከ DB)
          if (job.isNotEmpty || org.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1, bottom: 4),
              child: pw.Text(
                "$job${org.isNotEmpty ? ' at $org' : ''}",
                style: _buildStyle(
                    size: 8.5, isItalic: true, color: PdfColors.grey800),
              ),
            ),

          // 3. ስልክ ቁጥር (ከአይኮን ጋር)
          if (phone.isNotEmpty && phone != 'null')
            _buildIconInfo(iconFont, 0xe88a, phone),

          pw.SizedBox(height: 2),

          // 4. ኢሜይል (ከአይኮን ጋር)
          if (email.isNotEmpty && email != 'null')
            _buildIconInfo(iconFont, 0xe0be, email),
        ],
      ),
    );
  }

// አይኮን እና ጽሁፍን ጎን ለጎን የሚያሰልፍ ረዳት
  pw.Widget _buildIconInfo(pw.Font iconFont, int codePoint, String text) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Icon(
          pw.IconData(codePoint),
          font: iconFont,
          size: 9,
          color: PdfColors.blue700,
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          text,
          style: _buildStyle(size: 8, color: PdfColors.grey800),
        ),
      ],
    );
  }

  pw.Widget _certificateSidebarItem(Map<String, dynamic> cert) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10, left: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 1. የቡሌት ዲዛይን
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            width: 3.5,
            height: 3.5,
            decoration: pw.BoxDecoration(
              color: primaryColor.shade(200), // የቀድሞው ቀለም
              shape: pw.BoxShape.circle,
            ),
          ),

          // 2. የጽሑፍ ይዘት
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // የሰርተፊኬቱ ስም - Bold እና ትልቅ መጠን
                pw.Text(
                  cert['certName'] ?? "",
                  style: _buildStyle(
                    size: 9.5,
                    color: primaryColor.shade(200), // የቀድሞው ቀለም
                    isBold: true,
                    text: cert['certName'] ?? "",
                  ),
                ),
                // በሁለቱ መካከል ያለውን ክፍተት በትንሹ (1.5) በመጨመር መለየት
                pw.SizedBox(height: 1.5),

                // ድርጅቱ እና አመተ ምህረቱ - ትንሽ መጠን እና Bold ያልሆነ
                pw.Text(
                  "${cert['organization'] ?? ""} | ${cert['year'] ?? ""}",
                  style: _buildStyle(
                    size: 8, // 👈 መጠኑን በትንሹ ዝቅ አድርገነዋል
                    color: primaryColor.shade(200), // የቀድሞው ቀለም
                    isBold: false, // 👈 Bold ባለማድረግ ከስሙ እንለየዋለን
                    text: "${cert['organization'] ?? ""} ${cert['year'] ?? ""}",
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
    final String projectText = edu['project'] ?? "";
    final List<String> projectBullets = projectText
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Stack(
        children: [
          // 1. የTimeline መስመር (ከጀርባ የሚቀመጥ)
          pw.Positioned.fill(
            child: pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                // በቀኝ በኩል ካለው ጽሑፍ ጋር እንዲገጣጠም (65px ለቀኑ + 12.5px ለነጥቡ መሃል)
                margin: const pw.EdgeInsets.only(right: 77.5, top: 10),
                width: 1,
                color: PdfColors.grey300,
              ),
            ),
          ),

          // 2. ዋናው ይዘት (Row)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- የግራ ክፍል፡ የትምህርት ዝርዝር ---
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${edu['degree'] ?? ''}${edu['field'] != null ? ' in ${edu['field']}' : ''}",
                      style: _buildStyle(size: 10.5, isBold: true),
                    ),
                    pw.Text(
                      edu['school'] ?? "",
                      style:
                          _buildStyle(size: 9.5, color: PdfColors.blueGrey800),
                    ),
                    if (edu['cgpa'] != null &&
                        edu['cgpa'].toString().isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          "CGPA: ${edu['cgpa']}",
                          style: _buildStyle(
                              size: 8.5,
                              isBold: true,
                              color: PdfColors.grey700),
                        ),
                      ),
                    if (projectBullets.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 5),
                        child: pw.Column(
                          children: projectBullets
                              .map((point) => pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 2),
                                    child: pw.Bullet(
                                      text: "Project: ${point.trim()}",
                                      style: _buildStyle(size: 9),
                                      bulletSize: 2.5,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),

              // --- የመካከለኛ ክፍል፡ የTimeline ነጥብ ---
              pw.Container(
                width: 25,
                alignment: pw.Alignment.topCenter,
                child: pw.Container(
                  width: 6,
                  height: 6,
                  margin: const pw.EdgeInsets.only(top: 4),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
              ),

              // --- የቀኝ ክፍል፡ የምረቃ ዓመት ---
              pw.SizedBox(
                width: 65,
                child: pw.Text(
                  (edu['degree'] != null &&
                          edu['degree'].toString().startsWith('G'))
                      ? (edu['gradYear'] ?? "")
                      : (edu['gradYear'] != null && edu['gradYear'] != ""
                          ? "Class of ${edu['gradYear']}"
                          : ""),
                  style: _buildStyle(
                    size: 8,
                    isBold: true,
                    color: PdfColors.redAccent700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1. ለቋንቋዎች እና ለቀላል ጽሁፎች የሚሆን Helper
  pw.Widget _sidebarText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        text,
        style: _buildStyle(
          size: 9,
          color: PdfColors.black,
          text: text,
        ),
      ),
    );
  }

  // 2. ለስልክ፣ ኢሜይል እና ሊንክዲን የሚሆን Helper (ከአይኮን ጋር)
  pw.Widget _sidebarItem(String text, int iconCode, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        children: [
          pw.Icon(
            pw.IconData(iconCode),
            font: font,
            size: 12,
            color: primaryColor,
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              text,
              style: _buildStyle(size: 9, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  // ለ DETAILS ክፍል አይኮን ያለው Helper
  pw.Widget _sidebarDetailItemWithIcon(
      String label, String value, int iconCode, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Icon(
            pw.IconData(iconCode),
            font: font,
            size: 11,
            color: primaryColor.shade(400),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label.toUpperCase(),
                  style: _buildStyle(
                      size: 7, color: PdfColors.grey600, isBold: true),
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  value,
                  style: _buildStyle(size: 9, color: PdfColors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
