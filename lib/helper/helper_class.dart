import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../screens/notification_screen.dart';

class PaymentProvider with ChangeNotifier {
  List<QueryDocumentSnapshot>? places;
  List<QueryDocumentSnapshot>? filteredPlaces;
  final TextEditingController searchController = TextEditingController();
  bool isRed = true;
  final ScrollController scrollController = ScrollController();

  Future<void> updatePayment(BuildContext context, String documentId,
      Map<String, dynamic> updatedData, int selectedYear) async {
    try {
      // Reference to the document that needs to be updated
      final docRef =
          FirebaseFirestore.instance.collection('places').doc(documentId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final docData = docSnapshot.data() as Map<String, dynamic>?;
        final currentYear = docData?['year'] as int? ?? DateTime.now().year;

        // Ensure we are updating the correct year
        if (currentYear == selectedYear) {
          // Now, add or update the 'payments' data for the selected year
          final payments = updatedData['payments'] as Map<String, dynamic>;

          // Make sure we only update the payments for the selected year
          payments.forEach((month, amount) {
            if (amount != null) {
              updatedData['payments']![month] = amount;
            }
          });

          await docRef.update({
            ...updatedData,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          fetchPlaces(year: selectedYear);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document year does not match the selected year'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw 'Document not found';
      }
    } catch (e) {
      // Notify user about the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update payment: $e'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  Future<void> deletePayment(
      BuildContext context, String id, int selectedYear) async {
    try {
      // Show a confirmation dialog
      bool? confirmDelete = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Confirm Deletion',
              style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 24),
            ),
            content: const Text(
              'Are you sure you want to delete this payment?',
              style: TextStyle(color: Colors.deepPurpleAccent),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(false); // Return false if user cancels
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(true); // Return true if user confirms
                },
                child: Text('Delete'),
              ),
            ],
          );
        },
      );

      // If the user confirms, delete the payment
      if (confirmDelete == true) {
        // Fetch the document from Firestore based on the selected year and id
        final snapshot = await FirebaseFirestore.instance
            .collection('places')
            .where('year', isEqualTo: selectedYear)
            .where(FieldPath.documentId, isEqualTo: id)
            .get();

        if (snapshot.docs.isNotEmpty) {
          // Proceed to delete the document
          await FirebaseFirestore.instance
              .collection('places')
              .doc(id)
              .delete();

          // Optionally, refresh local data (if you cache it)
          fetchPlaces(year: selectedYear);

          // Notify the user that the payment was successfully deleted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // If the document wasn't found, show an error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No payment found for the selected year.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any error during the delete process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<DocumentSnapshot> wowplacess = [];
  Map<String, Map<String, String>> comment = {};

  int selectedYear = DateTime.now().year;
  int totalItems = 0;
  final int itemsPerPage = 10;

  int currentPage = 1;

  List<Map<String, dynamic>> getPaginatedData(
      List<Map<String, dynamic>> tableData) {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return tableData.sublist(
      startIndex,
      endIndex > tableData.length ? tableData.length : endIndex,
    );
  }

  List<int> availableYears = [];

  void initializeYears() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('places').get();
    final years =
        snapshot.docs.map((doc) => doc['year'] as int).toSet().toList()..sort();
    print('Available years: $years');

    availableYears = years;
    notifyListeners();
  }

  Future<void> fetchComments(int? selectedYear) async {
    try {
      final yearToFetch = selectedYear ?? DateTime.now().year;

      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .where('year', isEqualTo: yearToFetch)
          .get();

      if (snapshot.docs.isEmpty) {
        // print("No documents found for year $yearToFetch");
        return; // No documents found for the selected year
      }

      // Process each document
      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Check if the document has 'comments' field and is a map
        final comments = data['comments'] as Map<String, dynamic>? ?? {};
        if (comments.isEmpty) {
          // print('No comments found for document ${doc.id}');
        } else {
          // print('Comments for ${doc.id}: $comments');
        }

        comment[doc.id] = Map<String, String>.from(comments);
        notifyListeners();
      }

      print('Successfully fetched comments for year $yearToFetch');
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  double totalAmount = 0.0;
  Map<String, double> monthlyTotals = {};

  Future<void> fetchPlaces({int? year}) async {
    // debugPrint('fetchPlaces called'); // Log when the method starts

    try {
      final currentYear = year ?? DateTime.now().year;

      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .where('year', isEqualTo: currentYear)
          .orderBy('itemsString')
          .get();

      places = snapshot.docs;
      filteredPlaces = places;

      // Initialize totals
      totalAmount = 0.0;
      monthlyTotals = {
        'January': 0.0,
        'February': 0.0,
        'March': 0.0,
        'April': 0.0,
        'May': 0.0,
        'June': 0.0,
        'July': 0.0,
        'August': 0.0,
        'September': 0.0,
        'October': 0.0,
        'November': 0.0,
        'December': 0.0,
      };

      for (var doc in places!) {
        // debugPrint('Processing document: ${doc.data()}'); // Log each document

        // Convert the "amount" field from string to double
        final amountString = doc['amount'] ?? '0';
        final amount = double.tryParse(amountString) ?? 0.0;
        totalAmount += amount;

        // Process the "payments" map
        final payments = doc['payments'] as Map<String, dynamic>? ?? {};
        payments.forEach((month, value) {
          final valueString = value?.toString() ?? '0';
          final monthValue = double.tryParse(valueString) ?? 0.0;
          if (monthlyTotals.containsKey(month)) {
            monthlyTotals[month] = monthlyTotals[month]! + monthValue;
          }
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error in fetchPlaces: $e'); // Log any errors
    }
  }

  Future<void> updateCommentWithoutAffectingOtherFields(String id, String month,
      String comment, int selectedYear, BuildContext conte) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Query for the document matching the selected year
      final querySnapshot = await firestore
          .collection('places')
          .where('year', isEqualTo: selectedYear)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the document reference for the matching year
        final docRef = querySnapshot.docs.first.reference;

        await docRef.update({
          'comments.$month': comment, // Update only the specific field
        });

        print('Updated comment for $month in year $selectedYear.');
      } else {
        // If no document exists for the selected year, create a new one
        await firestore.collection('places').add({
          'year': selectedYear,
          'comments': {
            month: comment,
          },
        });
        ScaffoldMessenger.of(conte).showSnackBar(
          const SnackBar(
            content: Text('Comment updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        print(
            'Created a new document for year $selectedYear with the comment.');
      }
    } catch (e) {
      // Handle any errors
      print('Error updating comment for $selectedYear: $e');
    }
  }

  String monthName(int month) {
    return const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][month - 1];
  }

  Future<void> duplicateDataForNewYear() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final currentYear = now.year;

    try {
      // Only proceed if it's January 1st
      if (now.month != 1 || now.day != 1) {
        print('Data duplication only allowed on January 1st.');
        return;
      }

      // Check if the new year's data already exists
      final existingSnapshot = await firestore
          .collection('places')
          .where('year', isEqualTo: currentYear + 1)
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        print('Data for year ${currentYear + 1} already exists.');
        return;
      }

      // Fetch all documents for the current year
      final snapshot = await firestore
          .collection('places')
          .where('year', isEqualTo: currentYear)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No data found for year $currentYear to duplicate.');
        return;
      }

      final batch = firestore.batch();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Prepare new data
        final newData = {
          ...data,
          'year': currentYear + 1,
          'payments': {
            'January': null,
            'February': null,
            'March': null,
            'April': null,
            'May': null,
            'June': null,
            'July': null,
            'August': null,
            'September': null,
            'October': null,
            'November': null,
            'December': null,
          },
          'comments': {
            'January': '',
            'February': '',
            'March': '',
            'April': '',
            'May': '',
            'June': '',
            'July': '',
            'August': '',
            'September': '',
            'October': '',
            'November': '',
            'December': '',
          }, // Reset all months in comments
        };

        final newDocRef = firestore.collection('places').doc();
        batch.set(newDocRef, newData);
      }

      // Commit batch
      await batch.commit();
      print('Data duplicated for year ${currentYear + 1}');
    } catch (e) {
      print('Error duplicating data: $e');
    }
  }

  String? selectedPlaceName;

  void filterByPlaceName(String? placeName) {
    selectedPlaceName = placeName;
    if (placeName == null || placeName.isEmpty) {
      wowplacess = [];
    } else {
      wowplacess = places!.where((doc) {
        return doc['place'].toString().toLowerCase() == placeName.toLowerCase();
      }).toList();
    }
    notifyListeners();
  }

  void filterData(String searchQuery, String? placeName) {
    filteredPlaces = places!.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      final place = data['place']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          searchQuery.isEmpty || name.contains(searchQuery.toLowerCase());
      final matchesPlace = placeName == null ||
          placeName.isEmpty ||
          place == placeName.toLowerCase();

      return matchesSearch && matchesPlace;
    }).toList();

    notifyListeners();
  }

  Future<void> exportToCSVWeb() async {
    try {
      // Use filteredPlaces for export, if available
      final placesToExport = filteredPlaces ?? places;

      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      final rows = <List<dynamic>>[
        ['Name', 'Amount', 'Code', 'Place', ...months],
      ];

      // Loop through the filtered or all places
      for (var doc in placesToExport!) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Unknown';
        final code = data['items'].toString() ?? 'Unknown';
        final place = data['place'] ?? 'Unknown Place';
        final amount = data['amount'].toString() ?? 'Unknown';

        final payments = Map<String, dynamic>.from(data['payments'] ?? {});

        // Generate row with payment status for each month
        final row = [
          name,
          amount,
          code,
          place,
          ...months.map((month) => payments[month] ?? 'Not Paid'),
        ];
        rows.add(row);
      }

      // Convert rows to CSV with UTF-8 encoding and add BOM
      final csvData = const ListToCsvConverter().convert(rows);
      final bom = utf8.encode('\uFEFF'); // Add BOM for UTF-8
      final bytes = Uint8List.fromList([...bom, ...utf8.encode(csvData)]);

      // Create Blob for download
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = 'payment_table.csv'
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print("Error exporting CSV: $e");
    }
  }

  Future<void> exportToPDF(BuildContext context) async {
    try {
      // Use filteredPlaces for export, if available
      final placesToExport = filteredPlaces ?? places ?? [];

      const months = [
        'کانونی دووەم',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      final pdf = pw.Document();

      // Load a custom font that supports Kurdish
      final fontData =
          await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
      final customFont = pw.Font.ttf(fontData);

      // Add a page to the PDF document
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text(
                  'Place Payment Report',
                  style: pw.TextStyle(fontSize: 24, font: customFont),
                  textDirection: pw.TextDirection.ltr,
                ),
                pw.SizedBox(height: 20),
                // Create a table with headers
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Add header row
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Name',
                        ),
                        pw.Text(
                          'Amount',
                        ),
                        pw.Text(
                          'Code',
                        ),
                        pw.Text(
                          'Place',
                        ),
                        ...months
                            .map((month) => pw.Text(
                                  month,
                                  style: pw.TextStyle(font: customFont),
                                  textDirection: pw.TextDirection.rtl,
                                ))
                            .toList(),
                      ],
                    ),
                    // Add data rows
                    ...placesToExport.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown Place';
                      final code = data['items']?.toString() ?? 'Unknown';
                      final place = data['place'] ?? 'Unknown Place';
                      final amount = data['amount']?.toString() ?? 'Unknown';
                      final payments =
                          Map<String, dynamic>.from(data['payments'] ?? {});

                      // Process bidirectional text
                      final bidiName = Bidi.stripHtmlIfNeeded(name);
                      final bidiPlace = Bidi.stripHtmlIfNeeded(place);

                      return pw.TableRow(
                        children: [
                          pw.Text(
                            bidiName,
                            style: pw.TextStyle(font: customFont),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          pw.Text(
                            amount,
                            textDirection: pw.TextDirection.ltr,
                          ),
                          pw.Text(
                            code,
                            textDirection: pw.TextDirection.ltr,
                          ),
                          pw.Text(
                            bidiPlace,
                            style: pw.TextStyle(font: customFont),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          ...months.map((month) => pw.Text(
                                payments[month] ?? 'Not Paid',
                                textDirection: pw.TextDirection.ltr,
                              )),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final pdfFile = await pdf.save();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfFile,
      );
    } catch (e, stackTrace) {
      print("Error generating PDF: $e");
      print("Stack trace: $stackTrace");
    }
  }

  List<DataColumn> buildColumns() {
    String months(int month) {
      return const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][month - 1];
    }

    return [
      const DataColumn(
        label: Text(
          'ژمارە',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      const DataColumn(
          label: Text(
        'ناو',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
      const DataColumn(
          label: Text(
        'شوێن',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
      const DataColumn(
          label: Text(
        'ژمارەی یەکە',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
      const DataColumn(
          label: Text(
        'بڕی پارە',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
      ...List.generate(
        12,
        (index) => DataColumn(
            label: Text(
          months(index + 1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        )),
      ),
      const DataColumn(
          label: Text(
        'کردارەکان',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
    ];
  }

  Future<List<Map<String, dynamic>>> getUnpaidPlaces() async {
    final unpaidPlaces = <Map<String, dynamic>>[];

    // Get the current month and year
    final now = DateTime.now();
    final currentMonth = DateFormat('MMMM').format(now);
    final currentYear = now.year;

    final snapshot =
        await FirebaseFirestore.instance.collection('places').get();

    // Iterate through all the places in the collection
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final map = data['payments'] as Map<String, dynamic>?;

      // Ensure the name exists and is not empty
      final name = data['name'] as String?;
      if (name == null || name.trim().isEmpty) continue;

      // Check if the year matches the current year
      final year = data['year'] as int?;
      if (year != currentYear) continue;

      // Check if the map exists and if the current month is missing or unpaid (null or 0)
      if (map == null || map[currentMonth] == null || map[currentMonth] == 0) {
        unpaidPlaces.add({
          'id': doc.id,
          'name': name,
          'unpaidMonth': currentMonth,
          'year': currentYear,
        });
      }

      // Limit to 5 results
      if (unpaidPlaces.length >= 5) break;
    }

    return unpaidPlaces;
  }

  void checkDate() {
    DateTime now = DateTime.now();

    if (now.day == 25 && now.hour == 15 && now.year == DateTime.now().year) {
      isRed = true;
    } else {
      isRed = false;
    }

    notifyListeners();
  }

  void filterSearch(String query) {
    filteredPlaces = query.isEmpty
        ? List.from(places!)
        : places!.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name']?.toString().toLowerCase() ?? '';
            return name.contains(query.toLowerCase());
          }).toList();
    notifyListeners();
  }

  OverlayEntry? overlayEntry;
  bool isLoading = false;
  List<Map<String, dynamic>> unpaidPlaces = [];

  /// Toggles the notification dropdown
  void toggleDropdown(BuildContext context) async {
    if (overlayEntry == null) {
      isLoading = true;
      notifyListeners();

      unpaidPlaces = await getUnpaidPlaces();

      isLoading = false;
      notifyListeners();

      overlayEntry = createOverlayEntry(context);
      Overlay.of(context).insert(overlayEntry!);
    } else {
      overlayEntry?.remove();
      overlayEntry = null;
    }
  }

  /// Creates the notification dropdown using OverlayEntry
  OverlayEntry createOverlayEntry(BuildContext context) {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        right: 20,
        width: 350,
        child: GestureDetector(
          // This GestureDetector will listen for taps outside the overlay
          onTap: () {
            overlayEntry?.remove(); // Close the overlay
            overlayEntry = null;
          },
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              // This GestureDetector inside the overlay will catch taps inside the overlay content.
              onTap: () {},
              // Do nothing when tapping inside the overlay content
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: isLoading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : unpaidPlaces.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "🎉 All places have paid for this month!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Displaying the unpaid places
                              ...unpaidPlaces.map((place) {
                                return ListTile(
                                  leading: Icon(Icons.warning_amber,
                                      color: Colors.red),
                                  title: Text(
                                    place['name'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "Unpaid for ${place['unpaidMonth']}",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Selected ${place['name']}")),
                                    );
                                    overlayEntry?.remove();
                                    overlayEntry = null;
                                  },
                                );
                              }).toList(),

                              // Show more button when we have 5 items
                              if (unpaidPlaces.length >= 5)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: TextButton(
                                    onPressed: () {
                                      //Navigate to another screen (example)
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              UnpaidRemindersScreen(),
                                        ),
                                      );
                                      // Provider.of<PaymentProvider>(context,
                                      //         listen: false)
                                      //     .updateIndex(2);
                                    },
                                    child: Text(
                                      'Show More',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                ),
                            ],
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
