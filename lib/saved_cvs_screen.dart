import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'database_helper.dart'; // እንደ ፕሮጀክትህ አወቃቀር ፋይሉ ያለበትን ትክክለኛ ቦታ መሆኑን አረጋግጥ

class SavedCvsScreen extends StatefulWidget {
  const SavedCvsScreen({super.key});

  @override
  State<SavedCvsScreen> createState() =>
      _SavedCvsScreenState(); // ስሙ እዚህ ተስተካክሏል
}

class _SavedCvsScreenState extends State<SavedCvsScreen> {
  List<Map<String, dynamic>> _savedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  /// ዳታቤዝ ውስጥ ያሉትን ሲቪዎች መጫን
  Future<void> _loadFiles() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      final files = await DatabaseHelper.instance.getSavedCvs();
      if (mounted) {
        setState(() {
          _savedFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading files: $e");
    }
  }

  /// የፋይሉን መጠን (Size) ለማስላት
  Future<String> _getFileSize(String? path) async {
    if (kIsWeb || path == null || path.isEmpty) return "N/A";
    try {
      final file = File(path);
      if (await file.exists()) {
        int bytes = await file.length();
        if (bytes < 1024) return "$bytes B";
        if (bytes < 1024 * 1024) {
          return "${(bytes / 1024).toStringAsFixed(1)} KB";
        }
        return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
      }
      return "Missing";
    } catch (e) {
      return "Error";
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.indigo[900]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("My Saved CVs",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedFiles.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFiles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _savedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _savedFiles[index];
                      return _buildFileCard(file);
                    },
                  ),
                ),
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.05), // በ .withOpacity ምትክ የተተካ
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _openPdfFile(file['filePath']),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1), // በ .withOpacity ምትክ የተተካ
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
        ),
        title: Text(
          file['fileName'] ?? "Untitled CV",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Date: ${_formatDate(file['createdDate'])}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (!kIsWeb)
              FutureBuilder<String>(
                future: _getFileSize(file['filePath']),
                builder: (context, snapshot) {
                  return Text(
                    "Size: ${snapshot.data ?? '...'}",
                    style: TextStyle(color: Colors.blueGrey[300], fontSize: 11),
                  );
                },
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.redAccent, size: 22),
          onPressed: () => _confirmDelete(file),
        ),
      ),
    );
  }

  Future<void> _openPdfFile(String? path) async {
    if (path == null) return;
    final pdfFile = File(path);
    if (await pdfFile.exists()) {
      try {
        await Printing.layoutPdf(
          onLayout: (format) async => await pdfFile.readAsBytes(),
          name: path.split('/').last,
        );
      } catch (e) {
        _showSnackBar("Error opening PDF");
      }
    } else {
      _showSnackBar("File not found on device.");
    }
  }

  void _confirmDelete(Map<String, dynamic> fileData) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete CV?"),
        content: const Text("ይህ ሲቪ ለዘላለም እንዲጠፋ ይፈልጋሉ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("NO")),
          TextButton(
            onPressed: () async {
              Navigator.pop(c);
              await _deleteFile(fileData);
            },
            child:
                const Text("YES, DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFile(Map<String, dynamic> fileData) async {
    final int id = fileData['id'];
    final String? filePath = fileData['filePath'];

    await DatabaseHelper.instance.deleteCv(id);

    if (!kIsWeb && filePath != null) {
      final f = File(filePath);
      if (await f.exists()) await f.delete();
    }

    _loadFiles();
    _showSnackBar("ሲቪው ተሰርዟል!");
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return "Unknown";
    try {
      return DateTime.parse(dateStr.toString())
          .toLocal()
          .toString()
          .split(' ')[0];
    } catch (e) {
      return dateStr.toString();
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("No saved CVs found",
              style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
        ],
      ),
    );
  }
}
