import 'dart:io';
import 'dart:typed_data'; // Correct library for Uint8List
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';
import 'package:pdfx/pdfx.dart' as reader;
import 'package:open_filex/open_filex.dart';


class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final List<File> _selectedImages = [];
  bool _isProcessing = false;
  String _pageFormat = 'A4';

  Future<void> _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedImages
            .addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Optimized image processing for PDF
  Future<Uint8List?> _processImageForPdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      // High quality JPEG encoding (CamScanner style optimization)
      return Uint8List.fromList(img.encodeJpg(decodedImage, quality: 85));
    } catch (e) {
      debugPrint("Process Error: $e");
      return null;
    }
  }

  Future<void> _convertToPdf() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final pdf = pw.Document();
      final format =
          _pageFormat == 'A4' ? PdfPageFormat.a4 : PdfPageFormat.letter;

      for (var imageFile in _selectedImages) {
        final imageBytes = await _processImageForPdf(imageFile);
        if (imageBytes != null) {
          final pdfImage = pw.MemoryImage(imageBytes);
          pdf.addPage(
            pw.Page(
              pageFormat: format,
              build: (pw.Context context) => pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              ),
            ),
          );
        }
      }

      final directory = await getTemporaryDirectory();
      final String filePath =
          "${directory.path}/IMG_PDF_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        _showSuccessDialog(filePath);
      }
      setState(() => _selectedImages.clear());
    } catch (e) {
      debugPrint("Conversion Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openWithExternalApp(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open file: ${result.message}")),
      );
    }
  }

  void _showSuccessDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_outline,
            color: Color(0xFF009688), size: 60),
        content: const Text(
          "Your PDF is ready! How would you like to proceed?",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _viewPdf(path);
            },
            child: const Text("VIEW HERE"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openWithExternalApp(path);
            },
            child: const Text("OPEN WITH...",
                style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton(
            onPressed: () =>
                Share.shareXFiles([XFile(path)], text: 'Image to PDF'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688)),
            child: const Text("SHARE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewPdf(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SimplePdfReader(path: path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Images to PDF",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          if (_isProcessing)
            const LinearProgressIndicator(color: Color(0xFF009688)),
          _buildFormatSelector(),
          Expanded(
            child: _selectedImages.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _selectedImages.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx -= 1;
                        final item = _selectedImages.removeAt(oldIdx);
                        _selectedImages.insert(newIdx, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      return Card(
                        key: ValueKey(_selectedImages[index].path),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.file(_selectedImages[index],
                                width: 50, height: 50, fit: BoxFit.cover),
                          ),
                          title: Text("Page ${index + 1}",
                              style: const TextStyle(fontSize: 14)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () => _removeImage(index),
                              ),
                              const Icon(Icons.drag_handle, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ToggleButtons(
        isSelected: [_pageFormat == 'A4', _pageFormat == 'Letter'],
        onPressed: (index) =>
            setState(() => _pageFormat = index == 0 ? 'A4' : 'Letter'),
        borderRadius: BorderRadius.circular(10),
        selectedColor: Colors.white,
        fillColor: const Color(0xFF009688),
        children: const [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 30), child: Text("A4")),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text("Letter")),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("No images selected",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const Text("Add images to start conversion",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text("ADD IMAGES"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (_selectedImages.isEmpty || _isProcessing)
                  ? null
                  : _convertToPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("CONVERT"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Internal PDF Reader Page ---
class SimplePdfReader extends StatefulWidget {
  final String path;
  const SimplePdfReader({super.key, required this.path});

  @override
  State<SimplePdfReader> createState() => _SimplePdfReaderState();
}

class _SimplePdfReaderState extends State<SimplePdfReader> {
  late reader.PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = reader.PdfController(
      document: reader.PdfDocument.openFile(widget.path),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview PDF"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: "Open with external app",
            icon: const Icon(Icons.open_in_new),
            onPressed: () => OpenFilex.open(widget.path),
          ),
          IconButton(
            tooltip: "Share PDF",
            icon: const Icon(Icons.share),
            onPressed: () => Share.shareXFiles([XFile(widget.path)]),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[200],
        child: reader.PdfView(
          controller: _pdfController,
          scrollDirection: Axis.vertical,
        ),
      ),
    );
  }
}
