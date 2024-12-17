import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
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

  List<DocumentSnapshot> wowplacess = [];
  Map<String, Map<String, String>> comments = {};

  Future<void> fetchComments() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('places').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final comment = data['comments'] as Map<String, dynamic>? ?? {};
        comments[doc.id] = Map<String, String>.from(comment);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<void> fetchPlaces() async {
    try {
      // Fetch and order by the derived field
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .orderBy('itemsString')
          .get();

      // Store results in filteredPlaces
      places = snapshot.docs;
      filteredPlaces = places;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching places: $e');
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
        ['Place Name', ...months],
      ];

      // Loop through the filtered or all places
      for (var doc in placesToExport!) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Unknown Place';
        final payments = Map<String, dynamic>.from(data['payments'] ?? {});

        // Generate row with payment status for each month
        final row = [
          name,
          ...months.map((month) => payments[month] ?? 'Not Paid'),
        ];
        rows.add(row);
      }

      final csvData = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
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

      final pdf = pw.Document();

      // Add a page to the PDF document
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text('Place Payment Report',
                    style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Place Name', ...months],
                  data: placesToExport!.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown Place';
                    final payments =
                        Map<String, dynamic>.from(data['payments'] ?? {});
                    return [
                      name,
                      ...months.map((month) => payments[month] ?? 'Not Paid')
                    ];
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );

      // Convert the PDF to a Uint8List
      final pdfFile = await pdf.save();

      // Use the printing package to show and print the PDF
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfFile);
    } catch (e) {
      print("Error generating PDF: $e");
    }
  }

  Future<void> updateCommentInFirestore(
      String id, String month, String comment) async {
    try {
      // Reference the document for the specific id
      final docRef = FirebaseFirestore.instance.collection('places').doc(id);

      // Update the comment field for the specific month
      await docRef.set(
        {
          'comments': {
            month: comment,
          },
        },
        SetOptions(
            merge: true), // Merge ensures you don't overwrite other fields
      );
    } catch (e) {
      // Handle any errors
      print('Error updating comment: $e');
    }
  }

  Future<void> deletePayment(BuildContext context, String id) async {
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
                Navigator.of(context).pop(false); // Return false
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    // If the user confirms, delete the payment
    if (confirmDelete == true) {
      await FirebaseFirestore.instance.collection('places').doc(id).delete();
      fetchPlaces();
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

  List<DataColumn> buildColumns() {
    return [
      const DataColumn(
        label: Text(
          'Seq',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      const DataColumn(
          label: Text(
        'Name',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
      const DataColumn(
          label: Text(
        'Place',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
      const DataColumn(
          label: Text(
        'Area Code',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
      const DataColumn(
          label: Text(
        'Amount',
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
          monthName(index + 1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        )),
      ),
      const DataColumn(
          label: Text(
        'Actions',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      )),
    ];
  }

  // void showUpdateDialog(
  //     BuildContext context, String placeId, Map<String, dynamic> payments) {
  //   String selectedMonth = 'January'; // Default selected month
  //   TextEditingController amountController = TextEditingController();
  //
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: Colors.white,
  //         title: Text(
  //           'Update Payment',
  //           style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 24),
  //         ),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             DropdownButtonFormField<String>(
  //               dropdownColor: Colors.white,
  //               value: selectedMonth,
  //               items: [
  //                 'January',
  //                 'February',
  //                 'March',
  //                 'April',
  //                 'May',
  //                 'June',
  //                 'July',
  //                 'August',
  //                 'September',
  //                 'October',
  //                 'November',
  //                 'December',
  //               ].map((month) {
  //                 return DropdownMenuItem(
  //                   value: month,
  //                   child: Text(
  //                     month,
  //                   ),
  //                 );
  //               }).toList(),
  //               onChanged: (value) {
  //                 if (value != null) selectedMonth = value;
  //               },
  //               decoration: InputDecoration(
  //                 labelText: 'Select Month',
  //                 border: OutlineInputBorder(),
  //               ),
  //             ),
  //             SizedBox(height: 16),
  //             TextField(
  //               controller: amountController,
  //               keyboardType: TextInputType.number,
  //               decoration: InputDecoration(
  //                 labelText: 'Enter Payment Amount',
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Close the dialog
  //             },
  //             child: Text('Cancel'),
  //           ),
  //           ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.deepPurpleAccent),
  //             onPressed: () {
  //               final enteredAmount = amountController.text.trim();
  //               if (enteredAmount.isNotEmpty) {
  //                 updatePayment(context, placeId, selectedMonth,
  //                     double.parse(enteredAmount));
  //               }
  //               Navigator.of(context).pop(); // Close the dialog
  //               fetchPlaces();
  //             },
  //             child: Text(
  //               'Update',
  //               style: TextStyle(color: Colors.white),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Future<void> updatePayment(BuildContext context, String documentId,
      Map<String, dynamic> updatedData) async {
    try {
      // Update the Firestore document with new data
      await FirebaseFirestore.instance
          .collection('places')
          .doc(documentId)
          .update(updatedData);

      // Notify user about successful update
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Optionally refresh local data (if you cache it)
      await fetchPlaces(); // Re-fetch data from Firestore if needed
    } catch (e) {
      // Notify user about the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // void updatePayment(
  //     BuildContext context, String placeId, String month, double amount) {
  //   FirebaseFirestore.instance.collection('places').doc(placeId).update({
  //     'payments.$month': amount,
  //     // Firestore path syntax to update nested fields
  //   }).then((_) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Payment updated for $month')),
  //     );
  //   }).catchError((error) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to update payment: $error')),
  //     );
  //   });
  // }

  Future<List<Map<String, dynamic>>> getUnpaidPlaces() async {
    final unpaidPlaces = <Map<String, dynamic>>[];

    // Get the current month name
    final now = DateTime.now();
    final currentMonth = DateFormat('MMMM').format(now);

    final snapshot =
        await FirebaseFirestore.instance.collection('places').get();

    // Iterate through all the places in the collection
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final map = data['payments'] as Map<String, dynamic>?;

      // Check if the map exists and if the current month is missing or if it is unpaid (null or 0)
      if (map == null || map[currentMonth] == null || map[currentMonth] == 0) {
        unpaidPlaces.add({
          'id': doc.id,
          'name': data['name'],
          'unpaidMonth': currentMonth,
        });
      }

      // Limit to 5 results
      if (unpaidPlaces.length >= 5) break;
    }

    return unpaidPlaces;
  }

  void checkDate() {
    DateTime now = DateTime.now();
    if (now.day == 9 && now.hour == 14) {
      isRed = true;
      notifyListeners();
    }
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
