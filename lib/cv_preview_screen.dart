import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:my_new_cv/templates/master_template.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Internal Imports
import 'cv_model.dart';
import 'pdf_generator.dart';
import 'database_helper.dart';
import 'database_service.dart';
import 'app_fonts.dart';

class CvPreviewScreen extends StatefulWidget {
  final CvModel cvModel;
  final int templateIndex;
  final Color primaryColor;
  final String fontFamily;
  final double scale;

  const CvPreviewScreen({
    super.key,
    required this.cvModel,
    required this.templateIndex,
    required this.primaryColor,
    this.fontFamily = 'JetBrains Mono',
    this.scale = 1.0,
  });

  @override
  State<CvPreviewScreen> createState() => _CvPreviewScreenState();
}

class _CvPreviewScreenState extends State<CvPreviewScreen> {
  Uint8List? _currentPdfBytes;
  bool _isSyncing = false;
  bool _hasSynced = false;

  /// ክላውድ ላይ ሴቭ ለማድረግ
  Future<void> _autoSyncToCloud() async {
    if (_hasSynced || _isSyncing) return;
    if (mounted) setState(() => _isSyncing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await DatabaseService().saveCompleteCv(widget.cvModel);
      if (mounted) {
        setState(() {
          _hasSynced = true;
          _isSyncing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSyncing = false);
      debugPrint("Cloud Sync Failed: $e");
    }
  }

  /// ፒዲኤፉን ዳውንሎድ ሲያደርጉ ዳታቤዝ ላይ መመዝገብ
  Future<void> _handleDownload() async {
    if (_currentPdfBytes == null) return;

    PdfGenerator.showLoadingDialog(context, "Saving PDF to Downloads...");

    try {
      final String fullFileName =
          "${widget.cvModel.firstName}_${widget.cvModel.lastName}";

      final String? savedPath = await PdfGenerator.downloadAndSaveCv(
        context,
        _currentPdfBytes!,
        fullFileName,
      );

      if (savedPath != null) {
        await DatabaseHelper.instance
            .insertSavedCv("$fullFileName.pdf", savedPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("CV Successfully Saved!"),
              backgroundColor: Colors.green));
        }
      }
    } finally {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // ይበልጥ ንጹህ የሆነ ዳራ
      appBar: AppBar(
        title: const Text("CV Preview",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          if (_isSyncing)
            const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)))),
          if (_hasSynced)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.cloud_done, color: Colors.green, size: 20),
            ),
          IconButton(
            icon: const Icon(Icons.download_for_offline,
                color: Colors.indigo, size: 28),
            onPressed: _handleDownload,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PdfPreview(
        key: ValueKey(
            '${widget.templateIndex}-${widget.primaryColor.toARGB32()}-${widget.fontFamily}-${widget.scale}'),

        // --- Gridline ለማጥፋትና ዲዛይኑን ለማስተካከል የተጨመሩ ---
        maxPageWidth: 700,
        build: (PdfPageFormat format) async {
          try {
            await AppFonts.loadAllFontBytes();
            final selectedDesign = CvDesign.values[widget.templateIndex];
            final pdfPrimaryColor =
                PdfColor.fromInt(widget.primaryColor.toARGB32());

            final template = MasterTemplate(
              model: widget.cvModel,
              design: selectedDesign,
              primaryColor: pdfPrimaryColor,
              fontFamily: widget.fontFamily,
              scale: widget.scale,
            );

            final doc = await template.generate();
            final pdfBytes = await doc.save();
            _currentPdfBytes = pdfBytes;

            if (!_hasSynced && !_isSyncing) {
              Future.microtask(() => _autoSyncToCloud());
            }

            return pdfBytes;
          } catch (e) {
            debugPrint("PDF Generation Error: $e");
            return await _errorPdf(
                "Error generating CV. Please check your data.");
          }
        },

        // --- UI ማስተካከያዎች ---
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
        canDebug: false, // 👈 ይህ Gridline እና ሰማያዊ መስመሮችን ያጠፋል
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        pdfFileName:
            "${widget.cvModel.firstName}_${widget.cvModel.lastName}_CV.pdf",
        loadingWidget: _buildLoadingWidget(),
        allowPrinting: true,
        allowSharing: !kIsWeb,

        // የገጽ ዳራውን ነጭ በማድረግ መስመሮቹን መደበቅ
        onPrinted: (context) => debugPrint("Printed"),
        onShared: (context) => debugPrint("Shared"),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.indigo, strokeWidth: 3),
          const SizedBox(height: 20),
          Text("Preparing your CV...",
              style: TextStyle(
                  color: Colors.blueGrey[800], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<Uint8List> _errorPdf(String message) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
        build: (pw.Context context) => pw.Center(
            child: pw.Text(message,
                style: const pw.TextStyle(color: PdfColors.red)))));
    return pdf.save();
  }
}
