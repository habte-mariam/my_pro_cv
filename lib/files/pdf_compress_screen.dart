import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync;
import 'package:pdfx/pdfx.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

class PdfCompressScreen extends StatefulWidget {
  const PdfCompressScreen({super.key});

  @override
  State<PdfCompressScreen> createState() => _PdfCompressScreenState();
}

class _PdfCompressScreenState extends State<PdfCompressScreen> {
  PlatformFile? _selectedFile;
  bool _isCompressing = false;
  String? _resultPath;
  String _compressedSizeLabel = "";

  // File size limit - 15MB
  final int _maxSizeBytes = 15 * 1024 * 1024;

  // Quality settings (75+ recommended for color preservation)
  int _imageQuality = 75;
  sync.PdfCompressionLevel _syncLevel = sync.PdfCompressionLevel.normal;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      final file = result.files.first;

      // Check 15MB limit
      if (file.size > _maxSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("File exceeds 15MB. Please select a smaller file."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedFile = file;
        _resultPath = null;
        _compressedSizeLabel = "";
      });
    }
  }

  // Fast and High-Quality Compression
  Future<void> _compressPdf() async {
    if (_selectedFile == null || _selectedFile!.path == null) return;
    setState(() => _isCompressing = true);

    try {
      final String inputPath = _selectedFile!.path!;
      final directory = await getTemporaryDirectory();
      final String finalPath =
          "${directory.path}/Compressed_${DateTime.now().millisecondsSinceEpoch}.pdf";

      // 1. Syncfusion Optimization
      final List<int> bytes = await File(inputPath).readAsBytes();
      final sync.PdfDocument document = sync.PdfDocument(inputBytes: bytes);
      document.compressionLevel = _syncLevel;

      // 2. Efficient Image Compression (JPEG for speed, Quality 75 for color)
      final pdfDoc = await PdfDocument.openData(Uint8List.fromList(bytes));
      final sync.PdfDocument newOutputDoc = sync.PdfDocument();

      for (int i = 1; i <= pdfDoc.pagesCount; i++) {
        final page = await pdfDoc.getPage(i);

        // Rendering Scale 1.5 (Balanced for speed and quality)
        final pageRender = await page.render(
          width: page.width * 1.5,
          height: page.height * 1.5,
          format: PdfPageImageFormat.jpeg,
        );

        if (pageRender != null) {
          final compressedImage = await FlutterImageCompress.compressWithList(
            pageRender.bytes,
            quality: _imageQuality,
            format: CompressFormat.jpeg,
          );

          final sync.PdfPage newPage = newOutputDoc.pages.add();
          newPage.graphics.drawImage(
            sync.PdfBitmap(compressedImage),
            Rect.fromLTWH(0, 0, newPage.getClientSize().width,
                newPage.getClientSize().height),
          );
        }
        await page.close();
      }

      final List<int> finalPdfBytes = await newOutputDoc.save();
      await File(finalPath).writeAsBytes(finalPdfBytes);

      newOutputDoc.dispose();
      document.dispose();
      await pdfDoc.close();

      final int finalSize = await File(finalPath).length();
      setState(() {
        _resultPath = finalPath;
        _compressedSizeLabel = "${(finalSize / 1024).toStringAsFixed(2)} KB";
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compression Successful!"),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  Future<void> _downloadFile() async {
    if (_resultPath == null) return;

    // Opens share sheet so user can "Save to Files" or send to other apps
    await Share.shareXFiles(
      [XFile(_resultPath!)],
      text: 'Compressed PDF File',
      subject: 'My Optimized PDF',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fast PDF Compressor"),
        backgroundColor: const Color(0xFF009688),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_selectedFile == null) ...[
              const SizedBox(height: 60),
              const Icon(Icons.cloud_upload_outlined,
                  size: 100, color: Colors.grey),
              const Text("No file selected",
                  style: TextStyle(color: Colors.grey)),
            ] else ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf,
                      color: Colors.red, size: 40),
                  title: Text(_selectedFile!.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "Original Size: ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB"),
                ),
              ),
              const SizedBox(height: 20),
              _buildQualitySelector(),
            ],
            const SizedBox(height: 30),
            if (_isCompressing)
              const Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF009688)),
                  SizedBox(height: 10),
                  Text("Optimizing... Please wait"),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _selectedFile == null ? _pickFile : _compressPdf,
                  icon: Icon(_selectedFile == null ? Icons.add : Icons.bolt),
                  label: Text(_selectedFile == null
                      ? "SELECT PDF (Max 15MB)"
                      : "COMPRESS NOW"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (_resultPath != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Quality Level:",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            _qButton("Recommended", 75, sync.PdfCompressionLevel.normal),
            const SizedBox(width: 10),
            _qButton("High Compression", 40, sync.PdfCompressionLevel.best),
          ],
        ),
      ],
    );
  }

  Widget _qButton(String label, int q, sync.PdfCompressionLevel level) {
    bool isSelected = _imageQuality == q;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _imageQuality = q;
          _syncLevel = level;
        }),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.white,
            border: Border.all(
                color: isSelected ? Colors.teal : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? Colors.teal : Colors.black,
                  fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Divider(),
        Text("New Size: $_compressedSizeLabel",
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => OpenFilex.open(_resultPath!),
                icon: const Icon(Icons.remove_red_eye),
                label: const Text("VIEW"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _downloadFile,
                icon: const Icon(Icons.download),
                label: const Text("DOWNLOAD"),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
