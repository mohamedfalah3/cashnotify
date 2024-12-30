import 'dart:convert';
import 'dart:html' as html;

import 'package:cashnotify/helper/place.dart';
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
  List<Place>? places;
  List<Place>? filteredPlaces;
  final TextEditingController searchController = TextEditingController();
  bool isRed = true;
  final ScrollController scrollController = ScrollController();

  Future<void> updatePayment(BuildContext context, String documentId,
      Map<String, dynamic> updatedData, int selectedYear) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('places').doc(documentId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final docData = docSnapshot.data() as Map<String, dynamic>?;

        // Get current year from Firestore document data
        final currentYear = docData?['year'] as int? ?? DateTime.now().year;

        if (currentYear == selectedYear) {
          // Update Firestore
          await docRef.update(updatedData);

          // Find the place in the local list
          final index = places?.indexWhere((place) => place.id == documentId);
          if (index != null && index != -1) {
            // Retrieve the existing Place object
            final place = places![index];

            // Merge updated payment data into the existing `Place` object
            if (updatedData.containsKey('payments')) {
              final updatedPayments =
                  updatedData['payments'] as Map<String, dynamic>;
              updatedPayments.forEach((month, value) {
                place.payments?[month] =
                    value.toString(); // Update payments map
              });
            }

            // Optionally, handle other fields like amount, comments, etc.
            if (updatedData.containsKey('amount')) {
              place.amount = updatedData['amount'] as String;
            }
            if (updatedData.containsKey('comments')) {
              place.comments =
                  Map<String, String>.from(updatedData['comments']);
            }
            if (updatedData.containsKey('items')) {
              place.items = List<String>.from(updatedData['items']);
            }

            if (updatedData.containsKey('name')) {
              // Check if the updated name is not null before assigning it
              place.name = updatedData['name'] as String?;
            }

            // Update the year and itemsString if necessary
            if (updatedData.containsKey('year')) {
              place.year = updatedData['year'] as int;
            }
            if (updatedData.containsKey('itemsString')) {
              place.itemsString = updatedData['itemsString'] as String;
            }

            // Recalculate totals
            recalculateTotals();

            // Notify listeners to refresh the UI
            notifyListeners();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update payment: $e'),
          backgroundColor: Colors.grey,
        ),
      );
      print(e);
    }
  }

  double totalAmount = 0.0;
  Map<String, double> monthlyTotals = {};

  Future<void> fetchPlaces({int? year}) async {
    try {
      final currentYear = year ?? DateTime.now().year;

      // Fetch documents from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .where('year', isEqualTo: currentYear)
          .orderBy('itemsString')
          .get();

      // Convert Firestore documents into Place models
      places = snapshot.docs.map((doc) {
        final data = doc.data();
        return Place(
          id: doc.id,
          name: data['name'],
          // Nullable name
          amount: data['amount'],
          // Nullable amount
          comments: data['comments'] != null
              ? Map<String, String>.from(data['comments'])
              : null,
          // Nullable comments
          items:
              data['items'] != null ? List<String>.from(data['items']) : null,
          // Nullable items
          payments: data['payments'] != null
              ? Map<String, String>.from(data['payments'])
              : null,
          // Nullable payments
          year: data['year'] ?? currentYear,
          itemsString: data['itemsString'],
          // Nullable itemsString
          place: data['place'], // Nullable place
        );
      }).toList();

      // print(places?[1].payments);

      filteredPlaces = List.from(places!);

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

      // Calculate totals from places
      for (var place in places!) {
        totalAmount += double.tryParse(place.amount ?? '0.0') ??
            0.0; // Handle null or empty amount

        // Convert payments from String to double for calculation
        place.payments?.forEach((month, value) {
          final monthValue =
              double.tryParse(value!) ?? 0.0; // Convert String to double
          if (monthlyTotals.containsKey(month)) {
            monthlyTotals[month] = monthlyTotals[month]! + monthValue;
          }
        });
      }

      // Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error in fetchPlaces: $e');
    }
  }

  void recalculateTotals() {
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

    // Calculate totals from places
    for (var place in places!) {
      totalAmount += double.tryParse(place.amount ?? '0.0') ?? 0.0;

      place.payments?.forEach((month, value) {
        final monthValue = double.tryParse(value!) ?? 0.0;
        if (monthlyTotals.containsKey(month)) {
          monthlyTotals[month] = monthlyTotals[month]! + monthValue;
        }
      });
    }
  }

  Future<void> deletePayment(
      BuildContext context, String id, int selectedYear) async {
    try {
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
                  Navigator.of(context).pop(false); // Cancel
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Confirm
                },
                child: Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmDelete == true) {
        final docRef = FirebaseFirestore.instance.collection('places').doc(id);
        await docRef.delete();

        // Update the local list
        places?.removeWhere((doc) => doc.id == id);
        filteredPlaces = [...places!];
        notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  Future<void> updateCommentWithoutAffectingOtherFields(
    String id,
    String month,
    String comment,
    int selectedYear,
    BuildContext context,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Query for the document matching the selected year and ID
      final querySnapshot = await firestore
          .collection('places')
          .where('year', isEqualTo: selectedYear)
          .where(FieldPath.documentId, isEqualTo: id)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the document reference
        final docRef = querySnapshot.docs.first.reference;

        // Update the specific comment for the month
        await docRef.update({
          'comments.$month': comment,
        });

        print('Updated comment for $month in year $selectedYear.');

        // Optionally update the local Place instance if required
        final placeIndex = places?.indexWhere((p) => p.id == id);
        if (placeIndex != null && placeIndex >= 0) {
          final updatedPlace = places![placeIndex];
          updatedPlace.comments?[month] = comment;
          notifyListeners();
        }
      } else {
        // If no document exists for the selected year, create a new one
        final newDocRef = await firestore.collection('places').add({
          'year': selectedYear,
          'comments': {
            month: comment,
          },
        });

        // Add the new Place locally
        places?.add(Place(
          id: newDocRef.id,
          year: selectedYear,
          comments: {month: comment},
        ));

        notifyListeners();

        print(
            'Created a new document for year $selectedYear with the comment.');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      // Check if data for the current year already exists
      final existingSnapshot = await firestore
          .collection('places')
          .where('year', isEqualTo: currentYear)
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        print('Data for year $currentYear already exists.');
        return;
      }

      // Fetch all documents for the previous year
      final previousYear = currentYear - 1;
      final snapshot = await firestore
          .collection('places')
          .where('year', isEqualTo: previousYear)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No data found for year $previousYear to duplicate.');
        return;
      }

      // Start a Firestore batch
      final batch = firestore.batch();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Create a new Place instance with the current year and reset fields
        final newPlace = Place(
          id: firestore.collection('places').doc().id,
          // Generate a new ID
          name: data['name'] ?? 'Unknown',
          // Handle null values
          amount: data['amount'] ?? '0',
          comments: {
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
          },
          items: List<String>.from(data['items'] ?? []),
          payments: {
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
          year: currentYear,
          itemsString: data['itemsString'] ?? '',
          place: data['place'] ?? 'Unknown',
        );

        // Add the new document to the batch
        final newDocRef = firestore.collection('places').doc(newPlace.id);
        batch.set(newDocRef, {
          'name': newPlace.name,
          'amount': newPlace.amount,
          'comments': newPlace.comments,
          'items': newPlace.items,
          'payments': newPlace.payments,
          'year': newPlace.year,
          'itemsString': newPlace.itemsString,
          'place': newPlace.place,
        });
      }

      // Commit the batch
      await batch.commit();
      print('Data duplicated successfully for year $currentYear.');
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
      wowplacess = places!
          .where((place) {
            return place.name?.toLowerCase() == placeName.toLowerCase();
          })
          .cast<DocumentSnapshot<Object?>>()
          .toList();
    }

    notifyListeners();
  }

  void filterData(String searchQuery, String? placeName) {
    filteredPlaces = places!.where((place) {
      final name = place.name?.toLowerCase();
      final placeField = place.place?.toLowerCase();

      final matchesSearch =
          searchQuery.isEmpty || name!.contains(searchQuery.toLowerCase());
      final matchesPlace = placeName == null ||
          placeName.isEmpty ||
          placeField == placeName.toLowerCase();

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
        ['ناو', 'بڕی پارە', 'ژمارەی یەکە', 'شوێن', ...months],
      ];

      // Loop through the filtered or all places
      for (var place in placesToExport!) {
        final name = place.name ?? 'Unknown';
        final code = place.items?.join(', ') ??
            'No Items'; // Assuming items is a list of strings
        final placeLocation = place.place ??
            'Unknown Place'; // Assuming place is a field in the model
        final amount = place.amount?.toString() ??
            '0'; // Assuming amount is a string in the model

        final payments = Map<String, dynamic>.from(place.payments ?? {});

        // Generate row with payment status for each month
        final row = [
          name,
          amount,
          code,
          placeLocation,
          ...months.map((month) => payments[month] ?? 'Not Paid'),
          // Will show 'Not Paid' if no payment is found for the month
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
                    ...placesToExport.map((place) {
                      final name = place.name ?? 'Unknown Place';
                      final code = place.items?.join(', ') ??
                          'Unknown'; // Assuming items is a list of strings
                      final placeLocation = place.place ?? 'Unknown Place';
                      final amount = place.amount?.toString() ?? 'Unknown';

                      // Assuming payments is a Map<String, dynamic>
                      final payments =
                          Map<String, dynamic>.from(place.payments ?? {});

                      // Process bidirectional text using the Bidi class
                      final bidiName = Bidi.stripHtmlIfNeeded(name);
                      final bidiPlace = Bidi.stripHtmlIfNeeded(placeLocation);

                      return pw.TableRow(
                        children: [
                          pw.Text(
                            bidiName,
                            style: pw.TextStyle(font: customFont),
                            textDirection:
                                pw.TextDirection.rtl, // For right-to-left text
                          ),
                          pw.Text(
                            amount,
                            textDirection:
                                pw.TextDirection.ltr, // For left-to-right text
                          ),
                          pw.Text(
                            code,
                            textDirection: pw.TextDirection.ltr,
                          ),
                          pw.Text(
                            bidiPlace,
                            style: pw.TextStyle(font: customFont),
                            textDirection:
                                pw.TextDirection.rtl, // For right-to-left text
                          ),
                          ...months.map((month) => pw.Text(
                                payments[month] ?? 'Not Paid',
                                textDirection: pw.TextDirection
                                    .ltr, // For left-to-right text
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
        : places!.where((place) {
            // Assuming `place` is an object of your Place model
            final name = place.name?.toLowerCase() ?? '';
            return name.contains(query.toLowerCase());
          }).toList();

    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getUnpaidPlaces() async {
    final unpaidPlaces = <Map<String, dynamic>>[];

    final now = DateTime.now();
    final currentMonth =
        DateFormat('MMMM').format(now); // Adjust format if necessary
    final currentYear = now.year;

    final snapshot =
        await FirebaseFirestore.instance.collection('places').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'] as String?;
      if (name == null || name.trim().isEmpty) continue;

      final year = data['year'] as int? ?? currentYear;
      if (year != currentYear) continue;

      final map = data['payments'] as Map<String, dynamic>?;

      // Safely parse payment value
      final paymentValue =
          double.tryParse(map?[currentMonth]?.toString() ?? '0') ?? 0;

      if (paymentValue == 0) {
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
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : unpaidPlaces.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
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
                                  leading: const Icon(Icons.warning_amber,
                                      color: Colors.red),
                                  title: Text(
                                    place['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "Unpaid for ${place['unpaidMonth']}",
                                    style:
                                        const TextStyle(color: Colors.black54),
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
                                    child: const Text(
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
