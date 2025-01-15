import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlaceDetailsHelper extends ChangeNotifier {
  Map<String, dynamic>? placeSnapshot;

  Future<void> fetchPlaceDetails(String id, BuildContext context) async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance.collection('places').doc(id).get();

      if (docSnapshot.exists) {
        placeSnapshot = docSnapshot.data();
        notifyListeners();
      } else {
        throw "Place not found";
      }
    } catch (e) {
      debugPrint("Error fetching place details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load place details"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _moveCurrentUserToPrevious(
      String dateLeft, String id, BuildContext context) async {
    try {
      final currentUser = placeSnapshot?['currentUser'];
      if (currentUser == null) return;

      final previousUsers = List<Map<String, dynamic>>.from(
          placeSnapshot?['previousUsers'] ?? []);

      // Filter out payments with 0 or null values
      final payments = Map<String, dynamic>.from(currentUser['payments'] ?? {});
      final filteredPayments = Map<String, dynamic>.from(payments)
        ..removeWhere((key, value) => value == '0' || value == null);

      // Create the user object to move to previousUsers
      final updatedUser = {
        'name': currentUser['name'],
        'phone': currentUser['phone'],
        'payments': filteredPayments,
        'joinedDate': currentUser['joinedDate'],
        'dateLeft': dateLeft,
        'aqarat': currentUser['aqarat']
      };

      previousUsers.add(updatedUser);

      // Update Firestore: Remove currentUser and update previousUsers
      await FirebaseFirestore.instance.collection('places').doc(id).update({
        'currentUser': null,
        'previousUsers': previousUsers,
      });

      // Update local state

      placeSnapshot?['currentUser'] = null;
      placeSnapshot?['previousUsers'] = previousUsers;
      notifyListeners();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Current user moved to previous users successfully."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error moving current user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to move current user."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> confirmAndMoveCurrentUserToPrevious(
      BuildContext context, String id) async {
    final shouldMove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Action"),
          content: const Text(
            "Are you sure you want to move the current user to previous users?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );

    if (shouldMove == true) {
      // Show date picker
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (pickedDate != null) {
        final dateLeft = pickedDate.toIso8601String().split('T')[0];
        await _moveCurrentUserToPrevious(dateLeft, id, context);
      }
    }
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void addCurrentUser(BuildContext context, String id) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final aqaratController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Current User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
              TextField(
                controller: aqaratController,
                decoration: const InputDecoration(labelText: "Aqarat"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                final phone = phoneController.text;
                final amount = amountController.text;
                // final joinedDate = joinedDateController.text;
                final aqarat = aqaratController.text;
                if (name.isNotEmpty && phone.isNotEmpty) {
                  try {
                    // Add user to Firestore
                    await FirebaseFirestore.instance
                        .collection('places')
                        .doc(id)
                        .update({
                      'currentUser': {
                        'name': name,
                        'phone': phone,
                        'amount': amount,
                        'dateLeft': '',
                        'aqarat': aqarat,
                        'payments': {},
                        'joinedDate':
                            DateTime.now().toIso8601String().split('T')[0],
                      },
                    });

                    // Update local state

                    placeSnapshot?['currentUser'] = {
                      'name': name,
                      'phone': phone,
                      'amount': amount,
                      'aqarat': aqarat,
                      'dateLeft': '',
                      'payments': {},
                      'joinedDate':
                          DateTime.now().toIso8601String().split('T')[0],
                    };
                    notifyListeners();

                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(
                        content: Text("Current User added successfully!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    debugPrint("Error adding current user: $e");
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      const SnackBar(
                        content: Text("Failed to add current user"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> savePayment(String monthStart, String updatedValue,
      BuildContext context, String id) async {
    try {
      // Update the payment value in Firestore
      FirebaseFirestore.instance.collection('places').doc(id).update({
        'currentUser.payments.$monthStart': updatedValue,
      });

      // Update the local state (placeSnapshot) to reflect the change

      placeSnapshot?['currentUser']['payments'][monthStart] = updatedValue;
      notifyListeners();

      // Optionally, show a success message
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("Payment updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error updating payment: $e");
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("Failed to update payment"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void editPayment(
      BuildContext context, String monthStart, String currentValue, String id) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Payment for $monthStart"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: "Enter payment amount"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final updatedValue = controller.text;
                // Call the _savePayment method to handle saving the payment
                await savePayment(monthStart, updatedValue, context, id);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  int currentPage = 0; // Start at the first page
  int itemsPerPage = 12; // Show 12 months per page

  List<Map<String, String>> generatePagedMonthlyList(DateTime startDate) {
    List<Map<String, String>> months = [];
    DateTime currentStartDate =
        startDate.add(Duration(days: currentPage * itemsPerPage * 30));

    for (int i = 0; i < itemsPerPage; i++) {
      final currentEndDate = currentStartDate.add(Duration(days: 30));

      // Format as 'yyyy-MM-dd'
      String startFormatted =
          "${currentStartDate.toLocal().year}-${currentStartDate.month.toString().padLeft(2, '0')}-${currentStartDate.day.toString().padLeft(2, '0')}";
      String endFormatted =
          "${currentEndDate.toLocal().year}-${currentEndDate.month.toString().padLeft(2, '0')}-${currentEndDate.day.toString().padLeft(2, '0')}";

      months.add({
        'start': startFormatted,
        'end': endFormatted,
      });

      currentStartDate = currentEndDate; // Set next month's start date
    }

    return months;
  }

  Widget buildPaymentsSection(
    Map<String, dynamic> payments,
    String sectionTitle,
    String id,
    BuildContext context,
    List<Map<String, String>> filteredMonths, // Accept filtered months
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Period")),
                  DataColumn(label: Text("Amount")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: generatePaymentRows(
                  payments,
                  id,
                  context,
                  filteredMonths, // Pass filtered months here
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 0
                      ? () {
                          currentPage -= 1; // Go to the previous page
                          (context as Element)
                              .markNeedsBuild(); // Trigger UI update
                        }
                      : null,
                  child: const Text("Previous"),
                ),
                ElevatedButton(
                  onPressed: () {
                    currentPage += 1; // Go to the next page
                    (context as Element).markNeedsBuild(); // Trigger UI update
                  },
                  child: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DataRow> generatePaymentRows(Map<String, dynamic> payments, String id,
      BuildContext context, List<Map<String, String>> filteredMonths) {
    // Accept filtered months
    return filteredMonths.map((month) {
      final amount = payments[month['start']]?.toString() ?? '0';
      final isUnpaid = amount == '0';
      final isCurrentMonth = DateTime.now()
              .isAfter(DateTime.parse(month['start']!)) &&
          DateTime.now()
              .isBefore(DateTime.parse(month['end']!).add(Duration(days: 1)));

      return DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (isUnpaid) {
            return Colors.red.shade50; // Highlight unpaid rows
          }
          return null; // Default background color
        }),
        cells: [
          DataCell(
            Text(
              "${month['start']} - ${month['end']}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataCell(
            Text(
              "\$$amount",
              style: TextStyle(
                color: isUnpaid ? Colors.red : Colors.black,
                fontWeight: isUnpaid ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          DataCell(
            isUnpaid
                ? Card(
                    color: isCurrentMonth ? Colors.orange : Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: Text(
                        isCurrentMonth ? "Unpaid (This Month)" : "Unpaid",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : const Text("Paid"),
          ),
          DataCell(
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.deepPurple),
              onPressed: () {
                editPayment(context, month['start']!, amount, id);
              },
            ),
          ),
        ],
      );
    }).toList();
  }
}
