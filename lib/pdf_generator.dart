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

Future<Uint8List> _buildPdfInBackground(Map<String, dynamic> args) async {
  try {
    // ⚠️ እዚህ ውስጥ WidgetsFlutterBinding.ensureInitialized() በፍጹም አትጥራ!
    
    final Map<String, Uint8List> fontBytesMap = args['fontBytes'];
    final CvModel model = args['model'];
    final int templateIndex = args['templateIndex'];
    final int colorValue = args['colorValue'];
    final String fontFamily = args['fontFamily'];

    AppFonts.initFromBytes(fontBytesMap);

    final PdfColor primaryColor = PdfColor.fromInt(colorValue);
    CvDesign selectedDesign = CvDesign.values[templateIndex % CvDesign.values.length];

    final master = MasterTemplate(
      model: model,
      design: selectedDesign,
      primaryColor: primaryColor,
      fontFamily: fontFamily, // MasterTemplate ውስጥ ዩኒኮድ ፎንት መጠቀሙን አረጋግጥ
    );

    final pw.Document pdf = await master.generate();
    return await pdf.save();
  } catch (e) {
    // ስህተቱን ለዋናው thread መላክ
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
    // ሀ. መጀመሪያ ፎንቶቹን ወደ Bytes ይጭናል (ይህ የሚሆነው በ Main Isolate/UI Thread ላይ ነው)
    await AppFonts.loadAllFontBytes();

    // ለ. ውሂቡን ወደ compute (Isolate) ይልካል
    return await compute(_buildPdfInBackground, {
      'model': model,
      'templateIndex': templateIndex,
      // .value በ .toARGB32() ተተክቷል
      'colorValue': flutterColor.toARGB32(),
      'fontFamily': fontFamily,
      'fontBytes': AppFonts.fontBytesMap,
    });
  }

  /// ተጠቃሚው መጠበቅ እንዳለበት የሚያሳይ ሎዲንግ ዲያሎግ
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(message,
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
      if (Platform.isAndroid) {
        // ለአንድሮይድ 13 እና ከዚያ በላይ ተጨማሪ ፐርሚሽን አያስፈልግ ይሆናል
        await Permission.storage.request();
      }

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

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String safeName =
          firstName.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final String fileName =
          "${safeName.isEmpty ? "My" : safeName}_CV_$timestamp.pdf";
      final String filePath = "${directory.path}/$fileName";

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes, flush: true);

      // በዳታቤዝ ውስጥ ማስቀመጥ
      await DatabaseHelper.instance.insertSavedCv(fileName, filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully saved: $fileName"),
            backgroundColor: Colors.teal[800],
            action: SnackBarAction(
              label: "Open",
              textColor: Colors.yellow,
              onPressed: () => OpenFilex.open(filePath),
            ),
          ),
        );
      }
      return filePath;
    } catch (e) {
      debugPrint("Save Error: $e");
      return null;
    }
  }
}
