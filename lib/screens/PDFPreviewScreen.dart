import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PDFPreviewScreen extends StatefulWidget {
  final Uint8List pdfBytes;

  const PDFPreviewScreen({Key? key, required this.pdfBytes}) : super(key: key);

  @override
  _PDFPreviewScreenState createState() => _PDFPreviewScreenState();
}

class _PDFPreviewScreenState extends State<PDFPreviewScreen> {
  void _downloadPDF() {
    final blob = html.Blob([widget.pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'places_report.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _printPDF() {
    Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => widget.pdfBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Softer background
      appBar: AppBar(
        title: const Text(
          "ڕاپۆرت",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4, // Adds shadow for a modern look
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                // Rounded preview edges
                child: PdfPreview(
                  build: (PdfPageFormat format) async => widget.pdfBytes,
                  useActions: false,
                  // Hides default buttons
                  allowSharing: false,
                  // Disables sharing option
                  canChangePageFormat: false,
                  // Locks page format
                  scrollViewDecoration: BoxDecoration(
                    color: Colors.white, // Background color
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _downloadPDF,
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text("داگرتن"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _printPDF,
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text("چاپکردن"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}
