import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sync;
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

class PdfMergeScreen extends StatefulWidget {
  const PdfMergeScreen({super.key});

  @override
  State<PdfMergeScreen> createState() => _PdfMergeScreenState();
}

class _PdfMergeScreenState extends State<PdfMergeScreen> {
  final List<PlatformFile> _selectedPdfs = [];
  bool _isMerging = false;

  // 1. ፋይሎችን መምረጫ (PDF only)
  Future<void> _pickPdfs() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedPdfs.addAll(result.files);
      });
    }
  }

  // 2. የተመረጠ ፋይልን ከዝርዝር ውስጥ ማስወገጃ
  void _removeFile(int index) {
    setState(() {
      _selectedPdfs.removeAt(index);
    });
  }

  // 3. ዋናው የማዋሃጃ ሎጂክ (ይዘቱ እንዳይቆረጥ የተስተካከለ)
  Future<void> _mergePdfs() async {
    if (_selectedPdfs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least 2 PDF files")),
      );
      return;
    }

    setState(() => _isMerging = true);

    try {
      final sync.PdfDocument finalDoc = sync.PdfDocument();

      for (var file in _selectedPdfs) {
        if (file.path == null) continue;
        final List<int> bytes = await File(file.path!).readAsBytes();
        final sync.PdfDocument tempDoc = sync.PdfDocument(inputBytes: bytes);

        for (int i = 0; i < tempDoc.pages.count; i++) {
          // የገጹን Template መፍጠር
          final sync.PdfTemplate template = tempDoc.pages[i].createTemplate();

          // አዲስ ገጽ መጨመር
          final sync.PdfPage page = finalDoc.pages.add();

          // ገጹን በሙሉ መጠኑ መሳል (ይህ መቆራረጥን ያስቀራል)
          page.graphics.drawPdfTemplate(
            template,
            const Offset(0, 0),
            page.getClientSize(), // አዲሱ ገጽ ባለው ሙሉ ስፋት ልክ እንዲሳል ያደርጋል
          );
        }
        tempDoc.dispose();
      }

      final directory = await getTemporaryDirectory();
      final String fullPath =
          "${directory.path}/Merged_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final File outputFile = File(fullPath);

      await outputFile.writeAsBytes(await finalDoc.save());
      finalDoc.dispose();

      if (mounted) {
        _showSuccessDialog(fullPath);
      }
    } catch (e) {
      debugPrint("Merge Error: $e");
    } finally {
      if (mounted) setState(() => _isMerging = false);
    }
  }

  // 4. የስኬት መልዕክት እና አማራጮች
  void _showSuccessDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Icon(Icons.check_circle, color: Color(0xFF009688), size: 60),
        content: const Text(
          "PDFs merged successfully!\nNo content was cut.",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openInternalViewer(path);
            },
            child: const Text("VIEW HERE"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              OpenFilex.open(path);
            },
            child: const Text("EXTERNAL APP",
                style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton(
            onPressed: () => Share.shareXFiles([XFile(path)]),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688)),
            child: const Text("SHARE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openInternalViewer(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PdfViewerPage(path: path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Merge Documents",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isMerging)
            const LinearProgressIndicator(color: Color(0xFF009688)),
          Expanded(
            child: _selectedPdfs.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _selectedPdfs.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx -= 1;
                        final item = _selectedPdfs.removeAt(oldIdx);
                        _selectedPdfs.insert(newIdx, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final file = _selectedPdfs[index];
                      return Card(
                        key: ValueKey(file.path ?? index),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf,
                              color: Colors.red),
                          title: Text(file.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.grey),
                                onPressed: () => _removeFile(index),
                              ),
                              const Icon(Icons.drag_handle, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("No PDF files selected",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickPdfs,
              icon: const Icon(Icons.add),
              label: const Text("ADD PDF"),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  (_selectedPdfs.length < 2 || _isMerging) ? null : _mergePdfs,
              icon: const Icon(Icons.call_merge),
              label: const Text("MERGE NOW"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Preview Page ---
class PdfViewerPage extends StatefulWidget {
  final String path;
  const PdfViewerPage({super.key, required this.path});
  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PdfController _pdfController;
  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(document: PdfDocument.openFile(widget.path));
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
        title: const Text("Merged PDF Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => OpenFilex.open(widget.path),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.shareXFiles([XFile(widget.path)]),
          ),
        ],
      ),
      body: PdfView(controller: _pdfController),
    );
  }
}
