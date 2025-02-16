import 'package:cashnotify/helper/place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screens/notification_screen.dart';

class PaymentProvider with ChangeNotifier {
  List<Place>? places;
  List<Place>? filteredPlaces;
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  double totalAmount = 0.0;
  Map<String, double> monthlyTotals = {};
  double totalMoneyCollected = 0.0;

  Future<void> fetchPlaces() async {
    try {
      final currentYear = DateTime.now().year;

      // Fetch documents from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .orderBy('itemsString')
          .get();

      // Convert Firestore documents into Place models
      final fetchedPlaces = snapshot.docs.map((doc) {
        final data = doc.data();

        // Parse currentUser
        final currentUser = data['currentUser'] != null
            ? Map<String, dynamic>.from(data['currentUser'])
            : null;

        // Parse previousUsers
        final previousUsers = (data['previousUsers'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList();

        return Place(
          id: doc.id,
          name: currentUser?['name'] ?? 'Unknown',
          amount: data['amount'] != null
              ? double.tryParse(data['amount'].toString())
              : 0.0,
          items: List<String>.from(data['items'] ?? []),
          itemsString: data['itemsString'] ?? '',
          place: data['place'] ?? '',
          phone: currentUser?['phone'] ?? '',
          joinedDate: currentUser?['joinedDate'] ?? '',
          currentUser: currentUser,
          year: data['year'] ?? currentYear,
          previousUsers: previousUsers,
        );
      }).toList();

      // Assign fetchedPlaces to the places variable
      places = fetchedPlaces;

      // Update filteredPlaces and recalculate totals
      filteredPlaces = List.from(places!);
      recalculateTotals();

      // Notify listeners to update the UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error in fetchPlaces: $e');
    }
  }

  Map<String, double> getTotalPaymentsPerPlace() {
    Map<String, double> totalPayments = {}; // {placeName: totalAmount}

    if (places == null || places!.isEmpty) {
      print("No places available.");
      return totalPayments; // Return empty map if no places are found
    }

    for (var place in places!) {
      if (place.currentUser != null) {
        final placeName = place.name ?? "Unknown"; // Ensure it's not null
        final payments =
            place.currentUser!['payments'] ?? {}; // Get payments map

        double totalAmount = 0.0;
        payments.forEach((date, amount) {
          // Ensure amount is a string and convert it to double safely
          final parsedAmount = double.tryParse(amount.toString());
          if (parsedAmount != null) {
            totalAmount += parsedAmount; // Sum all payments
          } else {
            print("Invalid payment amount: $amount");
          }
        });

        totalPayments[placeName] = totalAmount;
      } else {
        print("No current user found for place: ${place.name ?? 'Unknown'}");
      }
    }

    return totalPayments;
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

  void filterData(String searchQuery, String? placeName) {
    filteredPlaces = places!.where((place) {
      final name = place.name?.toLowerCase() ?? '';
      final placeField = place.itemsString?.toLowerCase() ?? '';

      final matchesSearch = searchQuery.isEmpty ||
          name.contains(searchQuery.toLowerCase()) ||
          placeField
              .contains(searchQuery.toLowerCase()); // ✅ Search in both fields

      final matchesPlace = placeName == null ||
          placeName.isEmpty ||
          placeField == placeName.toLowerCase();

      return matchesSearch && matchesPlace;
    }).toList();

    notifyListeners();
  }

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

      bool isPaidRecently = false;

      // Check if any payment in the last 30 days is valid
      payments?.forEach((date, amount) {
        final paymentDate = DateTime.tryParse(date);
        if (paymentDate == null) {
          print('Invalid Date: $date');
          return;
        }

        final parsedAmount = double.tryParse(amount.toString()) ?? 0;

        if (paymentDate.isAfter(thirtyDaysAgo) &&
            paymentDate.isBefore(now.add(const Duration(days: 1))) &&
            parsedAmount > 0) {
          isPaidRecently = true;
        }
      });

      if (!isPaidRecently) {
        print('Marking $name as unpaid');
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
