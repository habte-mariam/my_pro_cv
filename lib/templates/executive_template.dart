import 'package:my_new_cv/app_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../cv_model.dart';

class ExecutiveTemplate {
  final CvModel model;
  final PdfColor primaryColor;
  final String fontFamily;
  final double scale;

  ExecutiveTemplate({
    required this.model,
    required this.primaryColor,
    required this.fontFamily,
    this.scale = 1.0,
  });

  // --- ዋናው የ Generate ሜተድ ---
  Future<pw.Document> generate() async {
    final pdf = pw.Document();

    final mainFont =
        AppFonts.fontMap["$fontFamily-Regular"] ?? AppFonts.fontMap['Amharic']!;
    final boldFont = AppFonts.fontMap["$fontFamily-Bold"] ?? mainFont;
    final italicFont = AppFonts.fontMap["$fontFamily-Italic"] ?? mainFont;
    final iconFont = await PdfGoogleFonts.materialIcons();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        theme: pw.ThemeData.withFont(
          base: mainFont,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (pw.Context context) {
          return [
            // Header Section
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text("${model.firstName} ${model.lastName}".toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 26 * scale,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor)),
                  if (model.jobTitle.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(model.jobTitle.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 12 * scale, letterSpacing: 1.2)),
                    ),
                  pw.SizedBox(height: 12),
                  _buildContactHeader(iconFont),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Divider(thickness: 1, color: primaryColor),
            pw.SizedBox(height: 15),

            // Professional Summary
            if (model.summary.isNotEmpty) ...[
              _buildSectionTitle("Professional Summary"),
              pw.Text(model.summary,
                  style: pw.TextStyle(fontSize: 10 * scale),
                  textAlign: pw.TextAlign.justify),
              pw.SizedBox(height: 15),
            ],

            // Work Experience
            if (model.experience.isNotEmpty) ...[
              _buildSectionTitle("Work Experience"),
              ...model.experience.map((exp) => _buildExperienceItem(exp)),
              pw.SizedBox(height: 5),
            ],

            // Education
            if (model.education.isNotEmpty) ...[
              _buildSectionTitle("Education"),
              ...model.education.map((edu) => _buildEducationItem(edu)),
              pw.SizedBox(height: 5),
            ],

            // Skills & Languages
            _buildGrids(),

            // Certificates
            if (model.certificates.isNotEmpty) ...[
              _buildSectionTitle("Certificates"),
              ...model.certificates.map((cert) => _buildBulletItem(
                  "${cert['certName']} - ${cert['organization']} (${cert['year']})")),
              pw.SizedBox(height: 15),
            ],

            // References (ከአይኮን ጋር)
            if (model.user_references.isNotEmpty) ...[
              _buildSectionTitle("References"),
              pw.Wrap(
                spacing: 40,
                runSpacing: 15,
                children: model.user_references
                    .map((ref) => _buildReferenceItem(ref, iconFont))
                    .toList(),
              ),
            ],
          ];
        },
      ),
    );
    return pdf;
  }

  // --- 1. Experience Item (Null-Safe) ---
  pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    final String jobTitle = exp['jobTitle']?.toString() ?? '';
    final String company = exp['companyName']?.toString() ?? '';
    final String startDate = exp['startDate']?.toString() ?? '';
    final String endDate = exp['endDate']?.toString() ?? '';
    final String duration = exp['duration']?.toString() ?? '';
    final String description = exp['jobDescription']?.toString() ?? '';
    final String achievements = exp['achievements']?.toString() ?? '';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(jobTitle,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10.5 * scale)),
              pw.Text(
                "$startDate${endDate.isNotEmpty ? ' - $endDate' : ''}${duration.isNotEmpty ? ' ($duration)' : ''}",
                style: pw.TextStyle(fontSize: 8.5 * scale),
              ),
            ],
          ),
          if (company.isNotEmpty)
            pw.Text(company,
                style: pw.TextStyle(
                    color: primaryColor,
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 9.5 * scale)),
          if (description.isNotEmpty && description != 'null')
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(description,
                  style: pw.TextStyle(fontSize: 9 * scale),
                  textAlign: pw.TextAlign.justify),
            ),
          if (achievements.isNotEmpty && achievements != 'null')
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text("• Key Achievement: $achievements",
                  style: pw.TextStyle(fontSize: 8.5 * scale)),
            ),
        ],
      ),
    );
  }

  // --- 2. Reference Item (With Icons & Null-Safe) ---
  pw.Widget _buildReferenceItem(Map<String, dynamic> ref, pw.Font iconFont) {
    final String name = ref['name']?.toString() ?? '';
    final String job = ref['job']?.toString() ?? '';
    final String org = ref['organization']?.toString() ?? '';
    final String phone = ref['phone']?.toString() ?? '';
    final String email = ref['email']?.toString() ?? '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(name,
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 9.5 * scale)),
        if (job.isNotEmpty || org.isNotEmpty)
          pw.Text("$job ${org.isNotEmpty ? 'at $org' : ''}",
              style: pw.TextStyle(fontSize: 8 * scale)),
        if (phone.isNotEmpty && phone != 'null')
          _buildIconInfo(iconFont, 0xe0b0, phone),
        if (email.isNotEmpty && email != 'null')
          _buildIconInfo(iconFont, 0xe0be, email),
      ],
    );
  }

  // --- 4. Contact Header ---
  pw.Widget _buildContactHeader(pw.Font iconFont) {
    return pw.Wrap(
      alignment: pw.WrapAlignment.center,
      spacing: 12,
      runSpacing: 5,
      children: [
        if (model.phone.isNotEmpty)
          _buildIconInfo(iconFont, 0xe0b0, model.phone),
        if (model.phone2.isNotEmpty)
          _buildIconInfo(iconFont, 0xe0b0, model.phone2),
        if (model.email.isNotEmpty)
          _buildIconInfo(iconFont, 0xe0be, model.email),
        if (model.address.isNotEmpty)
          _buildIconInfo(iconFont, 0xe0c8, model.address),
        if (model.gender.isNotEmpty)
          _buildIconInfo(iconFont, 0xef4c, model.gender),
        if (model.age.isNotEmpty)
          _buildIconInfo(iconFont, 0xef5e, "${model.age} Years"),
        if (model.nationality.isNotEmpty)
          _buildIconInfo(iconFont, 0xe153, model.nationality),
        if (model.linkedin.isNotEmpty)
          _buildLinkInfo(iconFont, 0xe899, "LinkedIn", model.linkedin),
        if (model.portfolio.isNotEmpty)
          _buildLinkInfo(iconFont, 0xe051, "Portfolio", model.portfolio),
      ],
    );
  }

  // --- 5. Link Info ---
  pw.Widget _buildLinkInfo(
      pw.Font iconFont, int iconCode, String label, String url) {
    return pw.UrlLink(
      destination: url,
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Icon(pw.IconData(iconCode),
              font: iconFont, size: 8 * scale, color: primaryColor),
          pw.SizedBox(width: 4),
          pw.Text(label,
              style: pw.TextStyle(
                fontSize: 8 * scale,
                color: PdfColors.blue700,
                decoration: pw.TextDecoration.underline,
              )),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title.toUpperCase(),
            style: pw.TextStyle(
                fontSize: 11 * scale,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 2),
        pw.Container(
            height: 1,
            color: PdfColor(
                primaryColor.red, primaryColor.green, primaryColor.blue, 0.3)),
        pw.SizedBox(height: 7),
      ],
    );
  }

  // --- 3. Education Item (Null-Safe) ---
  pw.Widget _buildEducationItem(Map<String, dynamic> edu) {
    final String school = edu['school']?.toString() ?? '';
    final String degree = edu['degree']?.toString() ?? '';
    final String field = edu['field']?.toString() ?? '';
    final String gradYear = edu['gradYear']?.toString() ?? '';
    final String cgpa = edu['cgpa']?.toString() ?? '';
    final String project = edu['project']?.toString() ?? '';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  degree.isNotEmpty ? "$degree in $field" : field,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10 * scale),
                ),
              ),
              if (gradYear.isNotEmpty)
                pw.Text(gradYear, style: pw.TextStyle(fontSize: 9 * scale)),
            ],
          ),
          pw.Text(school,
              style: pw.TextStyle(
                  fontSize: 9.5 * scale,
                  color: primaryColor,
                  fontStyle: pw.FontStyle.italic)),
          if (cgpa.isNotEmpty && cgpa != 'null')
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text("CGPA: $cgpa",
                  style: pw.TextStyle(fontSize: 8.5 * scale)),
            ),
          if (project.isNotEmpty && project != 'null')
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text("Final Project: $project",
                  style: pw.TextStyle(
                      fontSize: 8.5 * scale, color: PdfColors.grey700)),
            ),
        ],
      ),
    );
  }

  // --- 6. Skills & Languages Grid ---
  pw.Widget _buildGrids() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (model.skills.isNotEmpty)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Skills"),
                ...model.skills.map((s) {
                  final String name = s['name']?.toString() ?? '';
                  final String level = s['level']?.toString() ?? '';
                  return _buildBulletItem(
                      level.isNotEmpty ? "$name - $level" : name);
                }),
              ],
            ),
          ),
        if (model.skills.isNotEmpty && model.languages.isNotEmpty)
          pw.SizedBox(width: 25),
        if (model.languages.isNotEmpty)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Languages"),
                ...model.languages.map((l) {
                  final String name = l['name']?.toString() ?? '';
                  final String level = l['level']?.toString() ?? '';
                  return _buildBulletItem(
                      level.isNotEmpty ? "$name ($level)" : name);
                }),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _buildIconInfo(pw.Font iconFont, int iconCode, String text) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Icon(pw.IconData(iconCode),
            font: iconFont, size: 8 * scale, color: primaryColor),
        pw.SizedBox(width: 4),
        pw.Text(text, style: pw.TextStyle(fontSize: 8 * scale)),
      ],
    );
  }

  pw.Widget _buildBulletItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3.5, right: 6),
            child: pw.Container(
              width: 3,
              height: 3,
              decoration: pw.BoxDecoration(
                color: primaryColor,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(fontSize: 9 * scale),
            ),
          ),
        ],
      ),
    );
  }
}
