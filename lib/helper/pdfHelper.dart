import 'package:cashnotify/helper/place.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'helper_class.dart';

class pdfHelper {
  void showPlaceReportDialog(BuildContext context, List<Place> places) {
    final selectedPlaces = <String>{};
    bool includeAmount = true;
    bool includeCurrentUser = true;
    bool includePreviousUsers = true;
    bool includePayments = true;
    bool includeAqarat = true;

    // Convert Place objects to maps
    final placeMaps = places
        .map((place) => {
              'id': place.id,
              'name': place.itemsString ?? 'Unnamed Place',
              'amount': place.amount?.toString() ?? '0',
              'currentUser': place.currentUser,
              'previousUsers': place.previousUsers,
            })
        .toList();

    String? selectedPlaceId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            String?
                errorMessage; // Initialize the errorMessage as null initially

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width *
                    0.5, // 80% of screen width
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generate Place Report',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Select Places
                    const Text(
                      'Select Places:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.deepPurple, width: 1.5),
                      ),
                      child: DropdownButton<String>(
                        value: selectedPlaceId,
                        isExpanded: true,
                        hint: const Text("Select a Place"),
                        underline: const SizedBox(),
                        items: placeMaps.map((place) {
                          return DropdownMenuItem<String>(
                            value: place['id'] as String,
                            child: Text(
                              place['name']?.toString() ?? 'Unnamed Place',
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPlaceId = value;
                            selectedPlaces.clear();
                            if (value != null) {
                              selectedPlaces.add(value);
                              errorMessage =
                                  null; // Clear error when a place is selected
                            }
                          });
                        },
                      ),
                    ),

                    // Show error message if no place is selected after pressing Generate
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
                      'Fields to Include:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        _buildCheckbox("Amount", includeAmount, (value) {
                          setState(() => includeAmount = value ?? false);
                        }),
                        _buildCheckbox("Current User", includeCurrentUser,
                            (value) {
                          setState(() => includeCurrentUser = value ?? false);
                        }),
                        _buildCheckbox("Previous Users", includePreviousUsers,
                            (value) {
                          setState(() => includePreviousUsers = value ?? false);
                        }),
                        _buildCheckbox("Payments", includePayments, (value) {
                          setState(() => includePayments = value ?? false);
                        }),
                        _buildCheckbox("Aqarat", includeAqarat, (value) {
                          setState(() => includeAqarat = value ?? false);
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
                            'Cancel',
                            style: TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // Check if a place is selected
                            if (selectedPlaces.isEmpty) {
                              setState(() {
                                errorMessage =
                                    "Please select a place"; // Set error message
                              });
                              return; // Prevent the report generation process
                            }

                            Navigator.of(context).pop();
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
                            );
                          },
                          child: const Text(
                            'Generate Report',
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
      activeColor: Colors.deepPurple,
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
    bool includeAqarat, // Added Aqarat parameter
  ) async {
    final pdf = pw.Document();

    // Load a font for the PDF
    final font = await rootBundle
        .load("assets/fonts/Roboto-Italic-VariableFont_wdth,wght.ttf");
    final ttf = pw.Font.ttf(font);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Report Title
              pw.Text(
                'Place Report',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              for (final place in selectedPlaces)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Place Name
                    pw.Text(
                      'Place: ${place['name'] ?? "Unnamed Place"}',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (includeAmount && place['currentUser'] != null)
                      pw.Text(
                        'Amount: \$${place['currentUser']['amount'] ?? "N/A"}',
                        style: pw.TextStyle(font: ttf),
                      ),
                    pw.SizedBox(height: 10),

                    // Current User Table
                    if (includeCurrentUser && place['currentUser'] != null)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Current User:',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Table.fromTextArray(
                              headers: ['Name', 'Phone', 'Aqarat', 'Payments'],
                              headerStyle: pw.TextStyle(
                                font: ttf,
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                              headerDecoration: pw.BoxDecoration(
                                color: PdfColors.blue,
                              ),
                              cellStyle: pw.TextStyle(
                                font: ttf,
                                fontSize: 10,
                              ),
                              data: [
                                [
                                  place['currentUser']?['name'] ?? 'N/A',
                                  place['currentUser']?['phone'] ?? 'N/A',
                                  includeAqarat
                                      ? (place['currentUser']?['aqarat'] ??
                                          'N/A') // If 'aqarat' is null, show 'N/A'
                                      : 'N/A',
                                  // If 'includeAqarat' is false, show 'N/A'
                                  includePayments &&
                                          place['currentUser']?['payments'] !=
                                              null
                                      ? (place['currentUser']?['payments']
                                              .entries
                                              .where((payment) =>
                                                  payment.value != '0' &&
                                                  payment.value !=
                                                      0) // Exclude 0 values
                                              .map((payment) =>
                                                  '${payment.key}: \$${payment.value}')
                                              .join('\n')) ??
                                          'N/A'
                                      : 'N/A',
                                ],
                              ]),
                          pw.SizedBox(height: 10),
                        ],
                      ),

                    // Previous Users Table
                    if (includePreviousUsers && place['previousUsers'] != null)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Previous Users:',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Table.fromTextArray(
                            headers: [
                              'Name',
                              'Phone',
                              'Date Left',
                              'Aqarat',
                              'Payments'
                            ],
                            headerStyle: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                            headerDecoration: pw.BoxDecoration(
                              color: PdfColors.green,
                            ),
                            cellStyle: pw.TextStyle(
                              font: ttf,
                              fontSize: 10,
                            ),
                            data: [
                              for (final user in place['previousUsers'] ?? [])
                                [
                                  user['name'] ?? 'N/A',
                                  user['phone'] ?? 'N/A',
                                  user['dateLeft'] ?? 'N/A',
                                  includeAqarat
                                      ? user['aqarat'] ?? 'N/A'
                                      : 'N/A',
                                  includePayments && user['payments'] != null
                                      ? (user['payments']
                                              .entries
                                              .where((payment) =>
                                                  payment.value != '0' &&
                                                  payment.value !=
                                                      0) // Exclude 0
                                              .map((payment) =>
                                                  '${payment.key}: \$${payment.value}')
                                              .join('\n') ??
                                          'N/A')
                                      : 'N/A',
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

    // Display PDF preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> generatePlacesReport(
      pw.Document pdf, PaymentProvider provider, pw.Font ttf) async {
    final places = provider.places ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text(
            'Places Report',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),

          // Table for all places
          pw.Table.fromTextArray(
            headers: ['Place Name', 'Place', 'Current User'],
            data: places.map((place) {
              final user = place.currentUser;
              return [
                place.itemsString ?? 'N/A',
                place.place ?? 'N/A',
                user?['name'] ?? 'N/A',
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
              2: pw.Alignment.centerLeft,
            },
          ),
        ],
      ),
    );

    // Preview the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> generateEmptyAndOccupiedPlacesReport(
      pw.Document pdf, PaymentProvider provider, pw.Font ttf) async {
    final places = provider.places;

    // Categorize places
    final emptyPlaces =
        places?.where((place) => place.currentUser == null).toList() ?? [];
    final occupiedPlaces =
        places?.where((place) => place.currentUser != null).toList() ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Text(
            'Empty and Occupied Places Report',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),

          // Table for empty places
          pw.Text(
            'Empty Places',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red,
            ),
          ),
          if (emptyPlaces.isNotEmpty)
            pw.Table.fromTextArray(
              headers: ['Place Name', 'Comments'],
              data: emptyPlaces.map((place) {
                return [
                  place.itemsString ?? 'N/A',
                  // place.comments?['general'] ?? 'No comments',
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
            pw.Text('No empty places.', style: pw.TextStyle(font: ttf)),

          pw.SizedBox(height: 30),

          // Table for occupied places
          pw.Text(
            'Occupied Places',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
          if (occupiedPlaces.isNotEmpty)
            pw.Table.fromTextArray(
              headers: ['Place Name', 'User Name', 'Payments'],
              data: occupiedPlaces.map((place) {
                final user = place.currentUser;
                final payments = user?['payments']
                        ?.entries
                        .map((entry) => '${entry.key}: \$${entry.value}')
                        .join(', ') ??
                    'No payments';
                return [
                  place.itemsString ?? 'N/A',
                  user?['name'] ?? 'N/A',
                  payments,
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
                2: pw.Alignment.centerLeft,
              },
            )
          else
            pw.Text('No occupied places.', style: pw.TextStyle(font: ttf)),
        ],
      ),
    );

    // Preview the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> generateSummaryReport(
      pw.Document pdf, PaymentProvider provider, pw.Font ttf) async {
    final totalPlaces = provider.places?.length ?? 0;

    // Calculate total current users
    final totalCurrentUsers =
        provider.places?.where((place) => place.currentUser != null).length ??
            0;

    // Calculate total previous users
    final totalPreviousUsers = provider.places?.fold<int>(
            0, (sum, place) => sum + (place.previousUsers?.length ?? 0)) ??
        0;

    // Calculate total payments from current users
    final totalPaymentsFromCurrentUsers = provider.places?.fold<double>(
          0,
          (sum, place) {
            final payments = place.currentUser?['payments']?.values
                    ?.map((e) => double.tryParse(e.toString()) ?? 0.0)
                    .toList() ??
                [];
            return sum + payments.fold(0.0, (prev, element) => prev + element);
          },
        ) ??
        0.0;

    // Calculate total payments from previous users
    final totalPaymentsFromPreviousUsers = provider.places?.fold<double>(
          0,
          (sum, place) {
            final payments = place.previousUsers?.fold<double>(
                  0,
                  (userSum, user) {
                    final userPayments = user['payments']
                            ?.values
                            ?.map((e) => double.tryParse(e.toString()) ?? 0.0)
                            .toList() ??
                        [];
                    return userSum +
                        userPayments.fold(
                            0.0, (prev, element) => prev + element);
                  },
                ) ??
                0.0;
            return sum + payments;
          },
        ) ??
        0.0;

    // Places with no users
    final placesWithNoCurrentUser =
        provider.places?.where((place) => place.currentUser == null).length ??
            0;
    final placesWithNoPreviousUser = provider.places
            ?.where((place) => (place.previousUsers?.isEmpty ?? true))
            .length ??
        0;

    // Add Summary Table to PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Summary Report',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.SizedBox(height: 20),

              // Summary Table
              pw.Table.fromTextArray(
                headers: [
                  'Metric',
                  'Value',
                ],
                headerStyle: pw.TextStyle(
                  font: ttf,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.deepPurple,
                ),
                cellStyle: pw.TextStyle(
                  font: ttf,
                  fontSize: 10,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                data: [
                  ['Total Places', totalPlaces.toString()],
                  ['Total Current Users', totalCurrentUsers.toString()],
                  ['Total Previous Users', totalPreviousUsers.toString()],
                  [
                    'Places with No Current User',
                    placesWithNoCurrentUser.toString()
                  ],
                  [
                    'Places with No Previous User',
                    placesWithNoPreviousUser.toString()
                  ],
                  [
                    'Total Payments from Current Users',
                    '\$${totalPaymentsFromCurrentUsers.toStringAsFixed(2)}'
                  ],
                  [
                    'Total Payments from Previous Users',
                    '\$${totalPaymentsFromPreviousUsers.toStringAsFixed(2)}'
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> generatePaymentHistory(
      pw.Document pdf, PaymentProvider provider, pw.Font ttf) async {
    final places = provider.places;

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Text(
              'Payment History',
              style: pw.TextStyle(
                font: ttf,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 20),
            for (final place in places!) ...[
              // Place Name
              pw.Text(
                'Place: ${place.itemsString}',
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
                pw.Text(
                  'Current User: ${place.currentUser?['name']}',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
                if (place.currentUser?['payments']?.isEmpty ?? true)
                  pw.Text(
                    'No payments recorded for this user.',
                    style: pw.TextStyle(font: ttf, fontSize: 14),
                  )
                else
                  _buildPaymentTable(place.currentUser?['payments'], ttf),
              ],

              // Previous Users Section
              if (place.previousUsers != null &&
                  place.previousUsers!.isNotEmpty) ...[
                pw.Text(
                  'Previous Users:',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
                for (final user in place.previousUsers!) ...[
                  pw.Text(
                    'Name: ${user['name']}',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (user['payments']?.isEmpty ?? true)
                    pw.Text(
                      'No payments recorded for this user.',
                      style: pw.TextStyle(font: ttf, fontSize: 12),
                    )
                  else
                    _buildPaymentTable(user['payments'], ttf),
                ],
              ],
              pw.Divider(),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// 🔵 Builds Payment Table with 30-day Intervals
  pw.Widget _buildPaymentTable(Map<String, dynamic> payments, pw.Font ttf) {
    final filteredPayments = payments.entries
        .where((entry) => entry.value != "0" && entry.value != 0)
        .toList();

    if (filteredPayments.isEmpty) {
      return pw.Text(
        "No valid payments available.",
        style: pw.TextStyle(font: ttf, fontSize: 12),
      );
    }

    return pw.Table.fromTextArray(
      headers: ['Interval', 'Amount', 'Status'],
      headerStyle: pw.TextStyle(
        font: ttf,
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColors.deepPurple,
      ),
      cellStyle: pw.TextStyle(
        font: ttf,
        fontSize: 10,
      ),
      cellAlignment: pw.Alignment.centerLeft,
      data: filteredPayments.map((entry) {
        final startDate = DateTime.tryParse(entry.key);
        if (startDate == null) return ['Invalid Date', '-', '-'];

        final endDate = startDate.add(const Duration(days: 30));
        final amount = entry.value.toString();
        final status = (amount != '0') ? "Paid" : "Unpaid";

        return [
          "${_formatDate(startDate)} - ${_formatDate(endDate)}",
          "\$$amount",
          status,
        ];
      }).toList(),
    );
  }
}
