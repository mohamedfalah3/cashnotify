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
      backgroundColor: Colors.grey[100], // Soft background color
      appBar: AppBar(
        title: const Text(
          "ڕاپۆرت",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4, // Adds shadow for a modern look
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // Rounded preview edges
          child: PdfPreview(
            build: (PdfPageFormat format) async => widget.pdfBytes,
            useActions: false, // Removes default buttons for a cleaner look
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  children: [
                    ListTile(
                      leading: Icon(Icons.download, color: Colors.blueAccent),
                      title: Text("داگرتن"),
                      onTap: () {
                        Navigator.pop(context);
                        _downloadPDF();
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.print, color: Colors.green),
                      title: Text("چاپکردن"),
                      onTap: () {
                        Navigator.pop(context);
                        _printPDF();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.more_vert),
        label: const Text("کردارەکان"),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
