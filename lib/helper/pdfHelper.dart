import 'package:cashnotify/helper/place.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../screens/PDFPreviewScreen.dart';
import 'helper_class.dart';

class pdfHelper {
  void showPlaceReportDialog(BuildContext context, List<Place> places) {
    final selectedPlaces = <String>{};
    bool includeAmount = true;
    bool includeCurrentUser = true;
    bool includePreviousUsers = true;
    bool includePayments = true;
    bool includeAqarat = true;
    bool includePlace = true;

    TextEditingController searchController = TextEditingController();
    List<Place> filteredPlaces = List.from(places);
    String? selectedPlaceId;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void filterSearchResults(String query) {
              setState(() {
                filteredPlaces = places
                    .where((place) =>
                        place.itemsString
                            ?.toLowerCase()
                            .contains(query.toLowerCase()) ??
                        false)
                    .toList();
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ڕاپۆرتی شوێنەکان',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 122, 255),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'شوێن هەڵبژێرە:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Searchable & Scrollable Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color.fromARGB(255, 0, 122, 255),
                            width: 1.5),
                      ),
                      child: Column(
                        children: [
                          // Dropdown Button to Open Modal
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (BuildContext context) {
                                  return StatefulBuilder(
                                    builder: (context, setModalState) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                            bottom: MediaQuery.of(context)
                                                .viewInsets
                                                .bottom),
                                        child: Container(
                                          height: 400,
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              // Search Field
                                              TextField(
                                                controller: searchController,
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: "گەڕان بۆ شوێن...",
                                                  prefixIcon:
                                                      Icon(Icons.search),
                                                  border: OutlineInputBorder(),
                                                ),
                                                onChanged: (query) {
                                                  setModalState(() {
                                                    filteredPlaces = places
                                                        .where((place) =>
                                                            place.itemsString
                                                                ?.toLowerCase()
                                                                .contains(query
                                                                    .toLowerCase()) ??
                                                            false)
                                                        .toList();
                                                  });
                                                },
                                              ),
                                              const SizedBox(height: 10),

                                              // Scrollable List
                                              Expanded(
                                                child: ListView.builder(
                                                  itemCount:
                                                      filteredPlaces.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    var place =
                                                        filteredPlaces[index];
                                                    return ListTile(
                                                      title: Text(
                                                          place.itemsString ??
                                                              'ناوی نیە'),
                                                      onTap: () {
                                                        setState(() {
                                                          selectedPlaceId =
                                                              place.id;
                                                          selectedPlaces
                                                              .clear();
                                                          selectedPlaces.add(
                                                              selectedPlaceId!);
                                                          errorMessage = null;
                                                        });
                                                        Navigator.pop(context);
                                                      },
                                                      selected:
                                                          selectedPlaceId ==
                                                              place.id,
                                                      selectedTileColor: Colors
                                                          .deepPurple
                                                          .withOpacity(0.2),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedPlaceId != null
                                        ? places
                                                .firstWhere((p) =>
                                                    p.id == selectedPlaceId)
                                                .itemsString ??
                                            "Unnamed Place"
                                        : "شوێن هەڵبژێرە",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Icon(Icons.arrow_drop_down,
                                      color: Color.fromARGB(255, 0, 122, 255)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorMessage!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),

                    const Divider(),
                    const SizedBox(height: 8),

                    // Fields to Include
                    const Text(
                      'داتا بۆ پیشاندان',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        _buildCheckbox("بڕی پارە", includeAmount, (value) {
                          setState(() => includeAmount = value ?? false);
                        }),
                        _buildCheckbox("کرێجی", includeCurrentUser, (value) {
                          setState(() => includeCurrentUser = value ?? false);
                        }),
                        _buildCheckbox("کرێجی پێشوو", includePreviousUsers,
                            (value) {
                          setState(() => includePreviousUsers = value ?? false);
                        }),
                        _buildCheckbox("پارەدان", includePayments, (value) {
                          setState(() => includePayments = value ?? false);
                        }),
                        _buildCheckbox("عقارات", includeAqarat, (value) {
                          setState(() => includeAqarat = value ?? false);
                        }),
                        _buildCheckbox("شوێن", includePlace, (value) {
                          setState(() => includePlace = value ?? false);
                        }),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'هەڵوەشاندنەوە',
                            style: TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 0, 122, 255),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            if (selectedPlaces.isEmpty) {
                              setState(() {
                                errorMessage = "Please select a place";
                              });
                              return;
                            }

                            final placeMaps = places
                                .map((place) => {
                                      'id': place.id,
                                      'name':
                                          place.itemsString ?? 'Unnamed Place',
                                      'amount': place.amount?.toString() ?? '0',
                                      'currentUser': place.currentUser,
                                      'previousUsers': place.previousUsers,
                                      'place': place.place,
                                    })
                                .toList();

                            Navigator.of(context).pop();

                            // Handle Report Generation (Your logic here)
                            _generateSpecificPlaceReportWithSelection(
                              context,
                              placeMaps
                                  .where((place) =>
                                      selectedPlaces.contains(place['id']))
                                  .toList(),
                              includeAmount,
                              includeCurrentUser,
                              includePreviousUsers,
                              includePayments,
                              includeAqarat,
                              includePlace,
                            );
                            print(
                                "Generating report for selected place ID: $selectedPlaceId");
                          },
                          child: const Text(
                            'پیشاندانی ڕاپۆرت',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      value: value,
      activeColor: const Color.fromARGB(255, 0, 122, 255),
      onChanged: onChanged,
    );
  }

  void _generateSpecificPlaceReportWithSelection(
    BuildContext context,
    List<Map<String, dynamic>> selectedPlaces,
    bool includeAmount,
    bool includeCurrentUser,
    bool includePreviousUsers,
    bool includePayments,
    bool includeAqarat,
    bool includePlace,
  ) async {
    final pdf = pw.Document();

    // Load fonts
    final font = await rootBundle
        .load("assets/fonts/Roboto-Italic-VariableFont_wdth,wght.ttf");
    final ttf = pw.Font.ttf(font);

    final newFont =
        await rootBundle.load("assets/fonts/NotoSansArabic-Regular.ttf");
    final newttf = pw.Font.ttf(newFont);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Report Title
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(
                  'ڕاپۆرتی مولکەکان',
                  style: pw.TextStyle(
                    font: newttf,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              for (final place in selectedPlaces)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Place Name
                    pw.Text(
                      '${place['name'] ?? "Unnamed Place"}',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    // Amount Section (if enabled)
                    if (includeAmount && place['currentUser'] != null)
                      pw.Row(
                        children: [
                          pw.Text(
                            '\$${place['currentUser']['amount'] ?? "N/A"}',
                            style: pw.TextStyle(font: ttf, fontSize: 16),
                          ),
                          pw.Directionality(
                            textDirection: pw.TextDirection.rtl,
                            child: pw.Text(
                              'بڕی پارە: ',
                              style: pw.TextStyle(font: newttf, fontSize: 16),
                            ),
                          ),
                        ],
                      ),

                    pw.SizedBox(height: 10),

                    // Current User Table (if enabled)
                    if (includeCurrentUser && place['currentUser'] != null)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Directionality(
                            textDirection: pw.TextDirection.rtl,
                            child: pw.Text(
                              'کریچی ئامادە:',
                              style: pw.TextStyle(
                                font: newttf,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),

                          // Table for Current User Info
                          pw.Table.fromTextArray(
                            headers: [
                              _tableHeader('ناو', newttf),
                              _tableHeader('ژمارە', newttf),
                              _tableHeader('عقارات', newttf),
                              _tableHeader('پارەدان', newttf),
                              _tableHeader('ناونیشان', newttf),
                            ],
                            headerStyle: pw.TextStyle(
                              font: newttf,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                            headerDecoration:
                                const pw.BoxDecoration(color: PdfColors.blue),
                            cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
                            data: [
                              [
                                _tableCell(
                                    place['currentUser']?['name'], newttf),
                                place['currentUser']?['phone'] ?? '',
                                includeAqarat
                                    ? _tableCell(
                                        place['currentUser']?['aqarat'], newttf)
                                    : '',
                                _getSortedPayments(
                                    place, includePayments, newttf, ttf),
                                _tableCell(place['place'], newttf),
                              ],
                            ],
                          ),
                          pw.SizedBox(height: 10),
                        ],
                      ),

                    pw.Divider(),
                  ],
                ),
            ],
          );
        },
      ),
    );

    // Convert PDF to bytes
    Uint8List pdfBytes = await pdf.save();

    // Navigate to preview screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFPreviewScreen(pdfBytes: pdfBytes),
      ),
    );
  }

  pw.Widget _tableCell(String? text, pw.Font font) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(
        text ?? '',
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    );
  }

  pw.Widget _tableHeader(String text, pw.Font font) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  String _getSortedPayments(Map<String, dynamic> place, bool includePayments,
      pw.Font newttf, pw.Font ttf) {
    if (!includePayments ||
        place['currentUser']?['payments'] == null ||
        place['currentUser']?['payments'] is! Map<String, dynamic>) {
      return 'N/A';
    }

    final paymentsMap =
        place['currentUser']!['payments'] as Map<String, dynamic>;

    final validPayments = paymentsMap.entries
        .where((entry) =>
            entry.key != null &&
            entry.value != null &&
            entry.value.toString() != '0')
        .map((entry) {
      final date = DateTime.tryParse(entry.key) ?? DateTime(1970);
      final amount = double.tryParse(entry.value.toString()) ?? 0;
      return MapEntry(date, amount);
    }).toList();

    // ✅ Sort payments by date (oldest to newest)
    validPayments.sort((a, b) => a.key.compareTo(b.key));

    // Convert to string format
    if (validPayments.isEmpty) return 'N/A';

    return validPayments.map((entry) {
      final startDate = entry.key;
      final endDate = startDate.add(Duration(days: 30));
      return '${startDate.toIso8601String().split("T").first} - '
          '${endDate.toIso8601String().split("T").first}: '
          '\$${entry.value}';
    }).join('\n');
  }

  Future<void> generateEmptyAndOccupiedPlacesReport(pw.Document pdf,
      PaymentProvider provider, pw.Font ttf, BuildContext context) async {
    final places = provider.places;

    // Categorize places
    final emptyPlaces =
        places?.where((place) => place.currentUser == null).toList() ?? [];

    final newfont =
        await rootBundle.load("assets/fonts/NotoSansArabic-Regular.ttf");
    final newttf = pw.Font.ttf(newfont);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Directionality(
            child: pw.Text(
              'شوینی بەتاڵ',
              style: pw.TextStyle(
                font: newttf,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 20),
          if (emptyPlaces.isNotEmpty)
            pw.Table.fromTextArray(
              headers: [
                pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: pw.Text('شوینی بەتاڵ',
                        style: pw.TextStyle(
                          font: newttf,
                        )))
              ],
              data: emptyPlaces.map((place) {
                return [
                  place.itemsString ?? 'N/A',
                ];
              }).toList(),
              border: pw.TableBorder.all(width: 1, color: PdfColors.grey),
              headerStyle: pw.TextStyle(
                font: ttf,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 12),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
              },
            )
          else
            pw.Directionality(
                child: pw.Text('هیچ شوینیکی بەتاڵ نیە',
                    style: pw.TextStyle(font: newttf)),
                textDirection: pw.TextDirection.rtl)
        ],
      ),
    );

    // Convert PDF to bytes
    Uint8List pdfBytes = await pdf.save();

    // Navigate to preview screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFPreviewScreen(pdfBytes: pdfBytes),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void showPlaceSelectionDialog(BuildContext context, List<Place> places) {
    // Define the three fixed places
    final selectedPlaces = <String, bool>{
      'گەنجان سیتی': false,
      'عەینکاوە': false,
      'کورانی عەینکاوە': false,
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5, // Adjust width
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'شوێن هەڵبژێرە',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 122, 255),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Checkboxes for fixed places
                    Column(
                      children: selectedPlaces.keys.map((place) {
                        return CheckboxListTile(
                          title: Text(place),
                          value: selectedPlaces[place],
                          onChanged: (bool? value) {
                            setState(() {
                              selectedPlaces[place] = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Buttons to generate the report
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'لابردن',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Get selected place names
                            final selectedPlaceNames = selectedPlaces.entries
                                .where((entry) => entry.value)
                                .map((entry) => entry.key)
                                .toList();

                            // Filter places to get itemsString for selected places
                            final filteredPlaces = places.where((place) {
                              return selectedPlaceNames.contains(place.place);
                            }).toList();

                            // Close dialog and generate the report
                            Navigator.of(context).pop();
                            generatePlacesReport(filteredPlaces, context);
                          },
                          child: const Text('پیشاندانی ڕاپۆرت'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> generatePlacesReport(
      List<Place> filteredPlaces, BuildContext context) async {
    final pdf = pw.Document();

    // Load fonts
    final englishFont =
        await PdfGoogleFonts.openSansRegular(); // English font for items
    final arabicFont =
        await rootBundle.load("assets/fonts/NotoSansArabic-Regular.ttf");
    final arabicTtf = pw.Font.ttf(arabicFont); // Arabic font for place names

    // Create table data where each item in itemsString is on a separate row
    List<List<pw.Widget>> tableData = [];

    for (var place in filteredPlaces) {
      String placeName = place.place ?? '';
      List<String> items = place.itemsString?.split(', ') ?? ['N/A'];

      for (var item in items) {
        tableData.add([
          pw.Text(item, style: pw.TextStyle(font: englishFont, fontSize: 12)),
          // English font for items
          pw.Text(placeName,
              style: pw.TextStyle(font: arabicTtf, fontSize: 12),
              textDirection: pw.TextDirection.rtl // RTL for Arabic text
              ),
        ]);
      }
    }

    // Generate the PDF with separate rows for each item
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl, // Keep overall text direction RTL
        build: (pw.Context context) => [
          pw.Text(
            'ڕاپۆرتی شوێنەکان',
            textDirection: pw.TextDirection.rtl, // RTL for title
            style: pw.TextStyle(
              font: arabicTtf, // Arabic font for the title
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),

          // Table with one item per row
          pw.TableHelper.fromTextArray(
            headers: [
              pw.Text('کۆد',
                  style: pw.TextStyle(
                      font: arabicTtf,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text('ناونیشان',
                  style: pw.TextStyle(
                      font: arabicTtf,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold))
            ],
            data: tableData,
            border: pw.TableBorder.all(width: 1, color: PdfColors.grey),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
            cellAlignments: {
              0: pw.Alignment.centerLeft, // English items aligned left
              1: pw.Alignment.centerRight, // Arabic place names aligned right
            },
          ),
        ],
      ),
    );

    // Convert PDF to bytes
    Uint8List pdfBytes = await pdf.save();

    // Navigate to preview screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFPreviewScreen(pdfBytes: pdfBytes),
      ),
    );
  }

  Future<void> generatePaymentHistory(pw.Document pdf, PaymentProvider provider,
      pw.Font ttf, BuildContext context) async {
    final places = provider.places;

    final newfont =
        await rootBundle.load("assets/fonts/NotoSansArabic-Regular.ttf");
    final newttf = pw.Font.ttf(newfont);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Directionality(
              child: pw.Text(
                'پارەدانەکان',
                style: pw.TextStyle(
                  font: newttf,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 20),
            for (final place in places!) ...[
              // Place Name
              pw.Text(
                '${place.itemsString}',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 10),

              // Current User Section
              if (place.currentUser != null) ...[
                pw.Directionality(
                  child: pw.Text(
                    'ناو : ${place.currentUser?['name']}',
                    style: pw.TextStyle(
                      font: newttf,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                if (place.currentUser?['payments']?.isEmpty ?? true)
                  pw.Directionality(
                    child: pw.Text(
                      'هیچ داتایەک بەردەست نیە',
                      style: pw.TextStyle(font: newttf, fontSize: 14),
                    ),
                    textDirection: pw.TextDirection.rtl,
                  )
                else
                  _buildPaymentTable(
                      place.currentUser?['payments'], ttf, newttf),
                pw.Divider(),
              ],

              // Previous Users Section
              if (place.previousUsers != null &&
                  place.previousUsers!.isNotEmpty) ...[
                pw.Directionality(
                  child: pw.Text(
                    'کریچی پیشتر',
                    style: pw.TextStyle(
                      font: newttf,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                for (final user in place.previousUsers!) ...[
                  pw.Directionality(
                    child: pw.Text(
                      'ناو: ${user['name']}',
                      style: pw.TextStyle(
                        font: newttf,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  if (user['payments']?.isEmpty ?? true)
                    pw.Directionality(
                      child: pw.Text(
                        'هیچ داتایەک بەردەست نیە',
                        style: pw.TextStyle(font: newttf, fontSize: 12),
                      ),
                      textDirection: pw.TextDirection.rtl,
                    )
                  else
                    _buildPaymentTable(user['payments'], ttf, newttf),
                  pw.Divider(),
                ],
              ],
            ],
          ];
        },
      ),
    );

    // Convert PDF to bytes
    Uint8List pdfBytes = await pdf.save();

    // Navigate to preview screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFPreviewScreen(pdfBytes: pdfBytes),
      ),
    );
  }

  /// 🔵 Builds Payment Table with 30-day Intervals
  pw.Widget _buildPaymentTable(
      Map<String, dynamic> payments, pw.Font ttf, pw.Font newttf) {
    // Filter out payments that are zero or empty
    final filteredPayments = payments.entries
        .where((entry) => entry.value != "0" && entry.value != 0)
        .toList();

    if (filteredPayments.isEmpty) {
      return pw.Text(
        "هیچ داتایەک بەردەست نیە",
        style: pw.TextStyle(font: ttf, fontSize: 12),
      );
    }

    return pw.Table.fromTextArray(
      headers: [
        // Kurdish Headers for the table
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Text(
            style: pw.TextStyle(font: newttf),

            'ماوەی پارەدان', // Payment period
          ),
        ),
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Text(
            style: pw.TextStyle(font: newttf),

            'بڕی پارە', // Amount of money
          ),
        ),
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Text(
            style: pw.TextStyle(font: newttf),
            'دۆخ', // Status
          ),
        ),
      ],
      headerStyle: pw.TextStyle(
        font: newttf,
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue500,
      ),
      cellStyle: pw.TextStyle(
        font: ttf,
        fontSize: 10,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      data: filteredPayments.map((entry) {
        final startDate = DateTime.tryParse(entry.key);
        if (startDate == null) {
          return ['بەروار هەڵەیە', '-', '-']; // Error message for invalid date
        }

        final endDate = startDate.add(const Duration(days: 30));
        final amount = entry.value.toString();
        final status =
            (amount != '0') ? "دراوە" : "نەدراوە"; // Paid or Not Paid

        return [
          // Display the formatted date range
          "${_formatDate(startDate)} - ${_formatDate(endDate)}",
          "\$$amount", // Display the amount in USD
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
              style: pw.TextStyle(font: newttf),
              status,
            ),
          ), // Status (Paid or Not Paid)
        ];
      }).toList(),
    );
  }
}
