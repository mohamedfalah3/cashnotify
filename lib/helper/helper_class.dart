import 'package:cashnotify/helper/place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screens/notification_screen.dart';

class PaymentProvider with ChangeNotifier {
  List<Place>? places;
  List<Place>? filteredPlaces;
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Future<void> updatePayment(BuildContext context, String documentId,
  //     Map<String, dynamic> updatedPayments, int selectedYear) async {
  //   try {
  //     final docRef =
  //         FirebaseFirestore.instance.collection('places').doc(documentId);
  //     final docSnapshot = await docRef.get();
  //
  //     if (docSnapshot.exists) {
  //       final docData = docSnapshot.data();
  //
  //       // Get current year from Firestore document data
  //       final currentYear = docData?['year'] as int? ?? DateTime.now().year;
  //
  //       if (currentYear == selectedYear) {
  //         // Retrieve current user data
  //         final currentUser = docData?['currentUser'] as Map<String, dynamic>?;
  //
  //         if (currentUser != null) {
  //           // Merge new payments into existing payments
  //           final existingPayments =
  //               Map<String, dynamic>.from(currentUser['payments'] ?? {});
  //           updatedPayments.forEach((month, value) {
  //             existingPayments[month] = value; // Update or add payment
  //           });
  //
  //           // Update Firestore
  //           await docRef.update({
  //             'currentUser.payments': existingPayments,
  //           });
  //
  //           // Update the local Place object
  //           final index = places?.indexWhere((place) => place.id == documentId);
  //           if (index != null && index != -1) {
  //             final place = places![index];
  //
  //             place.currentUser ??= {};
  //             place.currentUser!['payments'] = existingPayments;
  //
  //             recalculateTotals();
  //             notifyListeners();
  //           }
  //
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(
  //               content: Text('Payment updated successfully'),
  //               backgroundColor: Colors.green,
  //             ),
  //           );
  //         } else {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(
  //               content: Text('Current user data not found'),
  //               backgroundColor: Colors.orange,
  //             ),
  //           );
  //         }
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Document year does not match the selected year'),
  //             backgroundColor: Colors.orange,
  //           ),
  //         );
  //       }
  //     } else {
  //       throw 'Document not found';
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Failed to update payment'),
  //         backgroundColor: Colors.grey,
  //       ),
  //     );
  //     print(e);
  //   }
  // }

  double totalAmount = 0.0;
  Map<String, double> monthlyTotals = {};
  double totalMoneyCollected = 0.0;

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

        // Handling 'currentUser' and 'previousUsers' fields
        final currentUser = data['currentUser'] != null
            ? Map<String, dynamic>.from(data['currentUser'])
            : null;

        return Place(
          id: doc.id,
          name: currentUser?['name'],
          amount: data['amount'] != null
              ? double.tryParse(data['amount'].toString())
              : null,
          items: List<String>.from(data['items'] ?? []),
          itemsString: data['itemsString'],
          place: data['place'],
          phone: currentUser?['phone'],
          joinedDate: currentUser?['joinedDate'],
          currentUser: currentUser,
          year: data['year'] ?? currentYear,
          previousUsers: (data['previousUsers'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList(),
        );
      }).toList();

      filteredPlaces = List.from(places!);

      recalculateTotals();
      notifyListeners();
    } catch (e) {
      debugPrint('Error in fetchPlaces: $e');
    }
  }

  void recalculateTotals() {
    totalMoneyCollected = 0.0;
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

    for (var place in places!) {
      totalAmount += place.amount ?? 0.0;

      final payments = place.currentUser?['payments'] as Map<String, dynamic>?;

      payments?.forEach((month, value) {
        final monthValue = double.tryParse(value?.toString() ?? '0.0') ?? 0.0;
        if (monthlyTotals.containsKey(month)) {
          monthlyTotals[month] = monthlyTotals[month]! + monthValue;
        }
        totalMoneyCollected += monthValue;
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
              'سڕینەوە',
              style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 24),
            ),
            content: const Text(
              'ئایا دڵنیای لە سڕینەوە',
              style: TextStyle(color: Colors.deepPurpleAccent),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Cancel
                },
                child: const Text('لابردن'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Confirm
                },
                child: const Text('سڕینەوە'),
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
            content: Text('بە سەرکەوتویی سڕایەوە'),
            backgroundColor: Colors.green,
          ),
        );
        recalculateTotals();
        notifyListeners();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سەرکەوتوو نەبوو'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<DocumentSnapshot> wowplacess = [];
  Map<String, Map<String, String>> comment = {};

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

  // Future<void> updateCommentWithoutAffectingOtherFields(
  //   String id,
  //   String month,
  //   String comment,
  //   int selectedYear,
  //   BuildContext context,
  // ) async {
  //   try {
  //     final firestore = FirebaseFirestore.instance;
  //
  //     // Query for the document matching the selected year and ID
  //     final querySnapshot = await firestore
  //         .collection('places')
  //         .where('year', isEqualTo: selectedYear)
  //         .where(FieldPath.documentId, isEqualTo: id)
  //         .get();
  //
  //     if (querySnapshot.docs.isNotEmpty) {
  //       // Get the document reference
  //       final docRef = querySnapshot.docs.first.reference;
  //
  //       // Update the specific comment for the month
  //       await docRef.update({
  //         'comments.$month': comment,
  //       });
  //
  //       print('Updated comment for $month in year $selectedYear.');
  //
  //       // Optionally update the local Place instance if required
  //       final placeIndex = places?.indexWhere((p) => p.id == id);
  //       if (placeIndex != null && placeIndex >= 0) {
  //         final updatedPlace = places![placeIndex];
  //         updatedPlace.comments?[month] = comment;
  //         notifyListeners();
  //       }
  //     } else {
  //       // If no document exists for the selected year, create a new one
  //       final newDocRef = await firestore.collection('places').add({
  //         'year': selectedYear,
  //         'comments': {
  //           month: comment,
  //         },
  //       });
  //
  //       // Add the new Place locally
  //       places?.add(Place(
  //         id: newDocRef.id,
  //         year: selectedYear,
  //         comments: {month: comment},
  //       ));
  //
  //       notifyListeners();
  //
  //       print(
  //           'Created a new document for year $selectedYear with the comment.');
  //     }
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Comment updated successfully!'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to update comment: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     print('Error updating comment for $selectedYear: $e');
  //   }
  // }

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

  // Future<void> exportToCSVWeb() async {
  //   try {
  //     // Use filteredPlaces for export, if available
  //     final placesToExport = filteredPlaces ?? places;
  //
  //     const months = [
  //       'January',
  //       'February',
  //       'March',
  //       'April',
  //       'May',
  //       'June',
  //       'July',
  //       'August',
  //       'September',
  //       'October',
  //       'November',
  //       'December'
  //     ];
  //
  //     final rows = <List<dynamic>>[
  //       ['ناو', 'بڕی پارە', 'ژمارەی یەکە', 'شوێن', ...months],
  //     ];
  //
  //     // Loop through the filtered or all places
  //     for (var place in placesToExport!) {
  //       final name = place.name ?? 'Unknown';
  //       final code = place.items?.join(', ') ??
  //           'No Items'; // Assuming items is a list of strings
  //       final placeLocation = place.place ??
  //           'Unknown Place'; // Assuming place is a field in the model
  //       final amount = place.amount?.toString() ??
  //           '0'; // Assuming amount is a string in the model
  //
  //       final payments = Map<String, dynamic>.from(place.payments ?? {});
  //
  //       // Generate row with payment status for each month
  //       final row = [
  //         name,
  //         amount,
  //         code,
  //         placeLocation,
  //         ...months.map((month) => payments[month] ?? 'Not Paid'),
  //         // Will show 'Not Paid' if no payment is found for the month
  //       ];
  //
  //       rows.add(row);
  //     }
  //
  //     // Convert rows to CSV with UTF-8 encoding and add BOM
  //     final csvData = const ListToCsvConverter().convert(rows);
  //     final bom = utf8.encode('\uFEFF'); // Add BOM for UTF-8
  //     final bytes = Uint8List.fromList([...bom, ...utf8.encode(csvData)]);
  //
  //     // Create Blob for download
  //     final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  //     final url = html.Url.createObjectUrlFromBlob(blob);
  //     final anchor = html.AnchorElement(href: url)
  //       ..target = 'blank'
  //       ..download = 'payment_table.csv'
  //       ..click();
  //     html.Url.revokeObjectUrl(url);
  //   } catch (e) {
  //     print("Error exporting CSV: $e");
  //   }
  // }

  // Future<void> exportToPDF(BuildContext context) async {
  //   try {
  //     // Use filteredPlaces for export, if available
  //     final placesToExport = filteredPlaces ?? places ?? [];
  //
  //     const months = [
  //       'کانونی دووەم',
  //       'February',
  //       'March',
  //       'April',
  //       'May',
  //       'June',
  //       'July',
  //       'August',
  //       'September',
  //       'October',
  //       'November',
  //       'December'
  //     ];
  //
  //     final pdf = pw.Document();
  //
  //     // Load a custom font that supports Kurdish
  //     final fontData =
  //         await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
  //     final customFont = pw.Font.ttf(fontData);
  //
  //     // Add a page to the PDF document
  //     pdf.addPage(
  //       pw.Page(
  //         pageFormat: PdfPageFormat.a4.landscape,
  //         build: (pw.Context context) {
  //           return pw.Column(
  //             children: [
  //               pw.Text(
  //                 'Place Payment Report',
  //                 style: pw.TextStyle(fontSize: 24, font: customFont),
  //                 textDirection: pw.TextDirection.ltr,
  //               ),
  //               pw.SizedBox(height: 20),
  //               // Create a table with headers
  //               pw.Table(
  //                 border: pw.TableBorder.all(),
  //                 children: [
  //                   // Add header row
  //                   pw.TableRow(
  //                     children: [
  //                       pw.Text(
  //                         'Name',
  //                       ),
  //                       pw.Text(
  //                         'Amount',
  //                       ),
  //                       pw.Text(
  //                         'Code',
  //                       ),
  //                       pw.Text(
  //                         'Place',
  //                       ),
  //                       ...months.map((month) => pw.Text(
  //                             month,
  //                             style: pw.TextStyle(font: customFont),
  //                             textDirection: pw.TextDirection.rtl,
  //                           )),
  //                     ],
  //                   ),
  //                   // Add data rows
  //                   ...placesToExport.map((place) {
  //                     final name = place.name ?? 'Unknown Place';
  //                     final code = place.items?.join(', ') ??
  //                         'Unknown'; // Assuming items is a list of strings
  //                     final placeLocation = place.place ?? 'Unknown Place';
  //                     final amount = place.amount?.toString() ?? 'Unknown';
  //
  //                     // Assuming payments is a Map<String, dynamic>
  //                     final payments =
  //                         Map<String, dynamic>.from(place.payments ?? {});
  //
  //                     // Process bidirectional text using the Bidi class
  //                     final bidiName = Bidi.stripHtmlIfNeeded(name);
  //                     final bidiPlace = Bidi.stripHtmlIfNeeded(placeLocation);
  //
  //                     return pw.TableRow(
  //                       children: [
  //                         pw.Text(
  //                           bidiName,
  //                           style: pw.TextStyle(font: customFont),
  //                           textDirection:
  //                               pw.TextDirection.rtl, // For right-to-left text
  //                         ),
  //                         pw.Text(
  //                           amount,
  //                           textDirection:
  //                               pw.TextDirection.ltr, // For left-to-right text
  //                         ),
  //                         pw.Text(
  //                           code,
  //                           textDirection: pw.TextDirection.ltr,
  //                         ),
  //                         pw.Text(
  //                           bidiPlace,
  //                           style: pw.TextStyle(font: customFont),
  //                           textDirection:
  //                               pw.TextDirection.rtl, // For right-to-left text
  //                         ),
  //                         ...months.map((month) => pw.Text(
  //                               payments[month] ?? 'Not Paid',
  //                               textDirection: pw.TextDirection
  //                                   .ltr, // For left-to-right text
  //                             )),
  //                       ],
  //                     );
  //                   }),
  //                 ],
  //               ),
  //             ],
  //           );
  //         },
  //       ),
  //     );
  //
  //     final pdfFile = await pdf.save();
  //
  //     await Printing.layoutPdf(
  //       onLayout: (PdfPageFormat format) async => pdfFile,
  //     );
  //   } catch (e, stackTrace) {
  //     print("Error generating PDF: $e");
  //     print("Stack trace: $stackTrace");
  //   }
  // }

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
      // const DataColumn(
      //   label: Text(
      //     'ژمارە',
      //     style: TextStyle(
      //       fontWeight: FontWeight.bold,
      //       fontSize: 16,
      //       color: Colors.white,
      //     ),
      //   ),
      // ),
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
        'ژمارەی یەکە',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
      const DataColumn(
          label: Text(
        'amount',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
      const DataColumn(
          label: Text(
        'date',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
      const DataColumn(
          label: Text(
        'aqarat',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
      // ...List.generate(
      //   12,
      //   (index) => DataColumn(
      //       label: Text(
      //     months(index + 1),
      //     style: const TextStyle(
      //       fontWeight: FontWeight.bold,
      //       fontSize: 16,
      //       color: Colors.white,
      //     ),
      //   )),
      // ),
      // const DataColumn(
      //     label: Text(
      //   'کردارەکان',
      //   style: TextStyle(
      //     fontWeight: FontWeight.bold,
      //     fontSize: 16,
      //     color: Colors.white,
      //   ),
      // )),
    ];
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
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    print('Current Date: $now');
    print('30 Days Ago: $thirtyDaysAgo');

    final snapshot =
        await FirebaseFirestore.instance.collection('places').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentUser = data['currentUser'] as Map<String, dynamic>?;

      // Ensure that currentUser and name exist
      final name = currentUser?['name'] as String?;
      if (name == null || name.trim().isEmpty) continue;

      final year = data['year'] as int? ?? now.year;
      if (year != now.year) continue;

      final payments = currentUser?['payments'] as Map<String, dynamic>?;

      bool isPaidRecently =
          false; // Flag to track if payment is within the last 30 days
      bool hasUnpaidAmount = false; // Flag to check if there's a payment of 0

      // Loop over the payments and check if any payment was made within the last 30 days or if it's 0
      payments?.forEach((date, amount) {
        // Parse the date string from payments
        final paymentDate = DateTime.tryParse(date);

        // If paymentDate is null or unable to parse, skip it
        if (paymentDate == null) {
          print('Invalid Date: $date');
          return;
        }

        print('Payment Date: $paymentDate');

        // Check if the payment date is within the last 30 days
        if (paymentDate.isAfter(thirtyDaysAgo) &&
            paymentDate.isBefore(now.add(const Duration(days: 1)))) {
          print('Payment is within the last 30 days.');
          isPaidRecently = true;
        } else {
          print('Payment is outside the last 30 days.');
        }

        // Check if the amount is 0 or '0' (as a string)
        if (amount == 0 || amount == '0') {
          print('Payment amount is 0 or "0"');
          hasUnpaidAmount = true;
        }
      });

      // If the payment for this place is either not paid recently or has a zero amount, mark it as unpaid
      if (!isPaidRecently || hasUnpaidAmount) {
        print('Marking ${name} as unpaid');
        unpaidPlaces.add({
          'id': doc.id,
          'name': name,
          'unpaidPeriod': 'Last 30 Days or Zero Payment',
        });
      }

      // Limit to 5 results
      if (unpaidPlaces.length >= 5) break;
    }

    return unpaidPlaces;
  }

  OverlayEntry? overlayEntry;
  bool isLoading = false;
  List<Map<String, dynamic>> unpaidPlacess = [];

  /// Toggles the notification dropdown
  void toggleDropdown(BuildContext context) async {
    if (overlayEntry == null) {
      isLoading = true;
      notifyListeners();

      unpaidPlacess = await getUnpaidPlaces();

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
                    : unpaidPlacess.isEmpty
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
                              ...unpaidPlacess.map((place) {
                                return ListTile(
                                  leading: const Icon(Icons.warning_amber,
                                      color: Colors.red),
                                  title: Text(
                                    place['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "Unpaid until today",
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
                              }),

                              // Show more button when we have 5 items
                              if (unpaidPlacess.length >= 5)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: TextButton(
                                    onPressed: () {
                                      //Navigate to another screen (example)
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const UnpaidRemindersScreen(),
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
