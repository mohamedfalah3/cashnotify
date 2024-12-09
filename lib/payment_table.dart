import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentTable extends StatefulWidget {
  const PaymentTable({Key? key}) : super(key: key);

  @override
  State<PaymentTable> createState() => _PaymentTableState();
}

class _PaymentTableState extends State<PaymentTable> {
  List<QueryDocumentSnapshot>? places;
  List<QueryDocumentSnapshot>? filteredPlaces;
  final TextEditingController searchController = TextEditingController();
  bool isRed = false;

  @override
  void initState() {
    super.initState();
    fetchPlaces();
    checkDate();
  }

  void checkDate() {
    DateTime now = DateTime.now();
    if (now.day == 9 && now.hour == 14) {
      setState(() {
        isRed = true;
      });
    }
    // print(now.day);
    // print(now.hour);
    // print(now.minute);
  }

  Future<void> fetchPlaces() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('places').get();
      setState(() {
        places = querySnapshot.docs;
        filteredPlaces = List.from(places!);
      });
    } catch (e) {
      showSnackBar('Error fetching data: $e');
    }
  }

  void filterSearch(String query) {
    setState(() {
      filteredPlaces = query.isEmpty
          ? List.from(places!)
          : places!.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name']?.toString().toLowerCase() ?? '';
              return name.contains(query.toLowerCase());
            }).toList();
    });
  }

  Future<void> exportToCSVWeb() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('places').get();
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
        ['Place Name', ...months]
      ];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Unknown Place';
        final payments = Map<String, dynamic>.from(data['payments'] ?? {});
        final row = [
          name,
          ...months.map((month) => payments[month] ?? 'Not Paid')
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

      showSnackBar('CSV downloaded successfully');
    } catch (e) {
      showSnackBar('Error exporting CSV: $e');
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _deletePayment(
      BuildContext context, DocumentSnapshot payment) async {
    // Show a confirmation dialog
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this payment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
              child: Text('Cancel'),
            ),
            TextButton(
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
      await FirebaseFirestore.instance
          .collection('places')
          .doc(payment.id)
          .delete();
      fetchPlaces();
    }
  }

  void showUpdateDialog(
      BuildContext context, String placeId, Map<String, dynamic> payments) {
    String selectedMonth = 'January'; // Default selected month
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedMonth,
                items: [
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
                  'December',
                ].map((month) {
                  return DropdownMenuItem(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedMonth = value;
                },
                decoration: InputDecoration(
                  labelText: 'Select Month',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter Payment Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final enteredAmount = amountController.text.trim();
                if (enteredAmount.isNotEmpty) {
                  updatePayment(context, placeId, selectedMonth,
                      double.parse(enteredAmount));
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void updatePayment(
      BuildContext context, String placeId, String month, double amount) {
    FirebaseFirestore.instance.collection('places').doc(placeId).update({
      'payments.$month': amount,
      // Firestore path syntax to update nested fields
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment updated for $month')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update payment: $error')),
      );
    });
    fetchPlaces();
  }

  // Fetch unpaid places for the current month
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

  void showUnpaidPlacesDialog(
      BuildContext context, List<Map<String, dynamic>> unpaidPlaces) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unpaid Places'),
          content: unpaidPlaces.isEmpty
              ? const Text('All places have paid for this month.')
              : SizedBox(
                  width: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: unpaidPlaces.length,
                    itemBuilder: (context, index) {
                      final place = unpaidPlaces[index];
                      return ListTile(
                        title: Text(place['name']),
                        subtitle: Text('Unpaid for: ${place['unpaidMonth']}'),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Your App Title'),
        actions: [
          isRed
              ? Stack(
                  clipBehavior: Clip.none,
                  // Allows the red dot to overflow the bounds of the icon
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        size: 32,
                      ),
                      color: Colors.grey,
                      onPressed: () async {
                        final unpaidPlaces = await getUnpaidPlaces();
                        showUnpaidPlacesDialog(context, unpaidPlaces);
                        setState(() {
                          isRed = false;
                        });
                      },
                    ),
                    Positioned(
                      top: -2, // Adjust to position the dot properly
                      right: -2,
                      child: Container(
                        width: 8, // Size of the red dot
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                )
              : IconButton(
                  icon: const Icon(
                    Icons.notifications,
                    size: 32,
                  ),
                  color: Colors.grey,
                  onPressed: () async {
                    final unpaidPlaces = await getUnpaidPlaces();
                    showUnpaidPlacesDialog(context, unpaidPlaces);
                  },
                ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Search Field and Export Button
                Row(
                  children: [
                    // Search Field
                    Flexible(
                      flex: 3,
                      child: TextField(
                        controller: searchController,
                        onChanged: filterSearch,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Export Button
                    ElevatedButton.icon(
                      onPressed: exportToCSVWeb,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 16.0),
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text('Export to Excel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredPlaces == null
                ? const Center(child: CircularProgressIndicator())
                : filteredPlaces!.isEmpty
                    ? const Center(child: Text('No places found.'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateColor.resolveWith(
                            (states) => Colors.deepPurpleAccent,
                          ),
                          // Distinct header background
                          // Alternating row colors with hover effect
                          columnSpacing: 20.0,
                          // Increased spacing between columns
                          columns: [
                            const DataColumn(
                              label: Text(
                                'Place Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Area Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            ...List.generate(
                              12,
                              (index) => DataColumn(
                                label: Text(
                                  monthName(index + 1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Actions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          rows: filteredPlaces!.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['name'] ?? 'Unknown Place';
                            final payments = Map<String, dynamic>.from(
                                data['payments'] ?? {});

                            return DataRow(
                              cells: [
                                DataCell(Text(
                                  name,
                                  style: const TextStyle(fontSize: 14),
                                )),
                                const DataCell(Text(
                                  'Code',
                                  style: TextStyle(fontSize: 14),
                                )),
                                ...List.generate(12, (index) {
                                  final month = monthName(index + 1);
                                  final paymentAmount = payments[month];
                                  return DataCell(Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: paymentAmount == null
                                          ? Colors.red[
                                              50] // Light red background for "Not Paid"
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                          5), // Rounded corners
                                    ),
                                    child: Text(
                                      paymentAmount?.toString() ?? 'Not Paid',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: paymentAmount == null
                                            ? Colors.red
                                            : Colors.black,
                                        fontWeight: paymentAmount == null
                                            ? FontWeight.bold
                                            : null,
                                      ),
                                    ),
                                  ));
                                }),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        tooltip: 'Edit',
                                        onPressed: () => showUpdateDialog(
                                            context, doc.id, payments),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: 'Delete',
                                        onPressed: () =>
                                            _deletePayment(context, doc),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
