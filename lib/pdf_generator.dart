import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart';

// Internal imports
import 'templates/master_template.dart';
import 'cv_model.dart';
import 'app_fonts.dart';
import 'database_helper.dart';

/// ⚠️ ይህ ከ Main UI thread ውጭ በ Isolate ውስጥ የሚሰራ ነው (Lag ይከላከላል)
Future<Uint8List> _buildPdfInBackground(Map<String, dynamic> args) async {
  try {
    final Map<String, Uint8List> fontBytesMap = args['fontBytes'];
    final CvModel model = args['model'];
    final int templateIndex = args['templateIndex'];
    final int colorValue = args['colorValue'];
    final String fontFamily = args['fontFamily'];

    // ፎንቶቹን በ Isolate ውስጥ ማስጀመር
    AppFonts.initFromBytes(fontBytesMap);

    final PdfColor primaryColor = PdfColor.fromInt(colorValue);
    CvDesign selectedDesign =
        CvDesign.values[templateIndex % CvDesign.values.length];

    final master = MasterTemplate(
      model: model,
      design: selectedDesign,
      primaryColor: primaryColor,
      fontFamily: fontFamily,
    );

    final pw.Document pdf = await master.generate();
    return await pdf.save();
  } catch (e) {
    debugPrint("Background PDF Generation Error: $e");
    rethrow;
  }
}

class PdfGenerator {
  static Future<Uint8List> generatePdf(
    CvModel model,
    int templateIndex,
    Color flutterColor,
    String fontFamily,
    String fontSizeString,
  ) async {
    // 1. ፎንቶቹን በ UI Thread ላይ መጫን (መጀመሪያ መደረግ ያለበት)
    await AppFonts.loadAllFontBytes();

    // 2. ስራውን ወደ compute (Background Thread) መላክ
    // ይህ በ J3 ስልክ ላይ UI እንዳይቆም (Lag እንዳይኖር) ያደርጋል
    return await compute(_buildPdfInBackground, {
      'model': model,
      'templateIndex': templateIndex,
      'colorValue': flutterColor.toARGB32(),
      'fontFamily': fontFamily,
      'fontBytes': AppFonts.fontBytesMap,
    });
  }

  /// ሎዲንግ ዲያሎግ - Robustness: ተጠቃሚው ወደ ኋላ እንዳይመለስ ይከለክላል
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // 👈 ስራው ሳይቆም እንዳይወጡ ይከላከላል
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 20),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  /// ፒዲኤፍን ሴቭ የሚያደርግ ፋንክሽን
  static Future<String?> downloadAndSaveCv(
      BuildContext context, Uint8List pdfBytes, String firstName) async {
    try {
      // 1. የፐርሚሽን ጥያቄ (Android 10 እና ከዚያ በታች ለሆኑ ስልኮች)
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Robustness: ፐርሚሽን ካልተሰጠ ለተጠቃሚው ማሳወቅ
          debugPrint("Storage permission denied");
        }
      }

      // 2. የፋይል ማስቀመጫ ቦታ ማግኘት
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) throw Exception("Could not access storage");

      // 3. ፋይሉን በሥርዓት መሰየም
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String safeName =
          firstName.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final String fileName =
          "${safeName.isEmpty ? "My" : safeName}_CV_$timestamp.pdf";
      final String filePath = "${directory.path}/$fileName";

      // 4. ፋይሉን መጻፍ
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes, flush: true);

      // 5. በዳታቤዝ ውስጥ ማስቀመጥ (ለታሪክ እንዲቀመጥ)
      await DatabaseHelper.instance.insertSavedCv(fileName, filePath);

      // 6. UI ማሳወቂያ (ገጹ ገና ክፍት ከሆነ ብቻ)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully saved: $fileName"),
            backgroundColor: Colors.teal[800],
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: "Open",
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(filePath),
            ),
          ),
        );
      }
      return filePath;
    } catch (e) {
      debugPrint("Save Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to save PDF"), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }
}
