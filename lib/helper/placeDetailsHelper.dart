import 'package:cashnotify/helper/place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'helper_class.dart';

class PlaceDetailsHelper extends ChangeNotifier {
  // Map<String, dynamic>? placeSnapshot;

  Future<void> fetchPlaceDetails(String id, BuildContext context) async {
    try {
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      final place = paymentProvider.places?.firstWhere(
        (place) => place.id == id,
        orElse: () => Place(
            id: '',
            name: 'Unknown',
            amount: 0.0,
            items: [],
            itemsString: '',
            place: '',
            phone: '',
            joinedDate: '',
            currentUser: null,
            year: 0,
            previousUsers: []), // Return a default Place object if not found
      );

      if (place?.id.isEmpty ?? true) {
        // Handle the case where place is not found (default place)
        throw "Place not found";
      } else {
        // Use the place object as normal
        notifyListeners();
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
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);

      // Fetch the place object from PaymentProvider using the id
      final place = paymentProvider.places?.firstWhere(
        (place) => place.id == id,
        orElse: () => Place(
          id: '',
          name: 'Unknown',
          amount: 0.0,
          items: [],
          itemsString: '',
          place: '',
          phone: '',
          joinedDate: '',
          currentUser: null,
          year: 0,
          previousUsers: [],
        ),
      );

      // Check if currentUser is null
      if (place?.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No current user to move."),
            backgroundColor: Colors.red,
          ),
        );
        return; // Exit early if no currentUser
      }

      final currentUser = place!.currentUser;
      final previousUsers =
          List<Map<String, dynamic>>.from(place.previousUsers ?? []);

      // Safely extract payments and filter out '0' or null values
      final payments =
          Map<String, dynamic>.from(currentUser?['payments'] ?? {});
      final filteredPayments = Map<String, dynamic>.from(payments)
        ..removeWhere((key, value) => value == '0' || value == null);

      // Construct updatedUser with currentUser details
      final updatedUser = {
        'name': currentUser?['name'] ?? 'Unknown',
        // Ensure non-null default
        'phone': currentUser?['phone'] ?? 'Unknown',
        // Ensure non-null default
        'payments': filteredPayments,
        'joinedDate': currentUser?['joinedDate'] ?? 'Unknown',
        // Default if null
        'dateLeft': dateLeft,
        'information': currentUser?['information'] ?? {},
        'aqarat': currentUser?['aqarat'] ?? 'N/A',
        // Default if null
      };

      // Add the updated user to previousUsers
      previousUsers.add(updatedUser);

      // Update the Firestore and PaymentProvider state
      place.currentUser = null; // Remove current user
      place.previousUsers = previousUsers; // Update the list of previous users

      // Update Firestore document with the changes
      await FirebaseFirestore.instance.collection('places').doc(id).update({
        'currentUser': null,
        'previousUsers': previousUsers,
      });

      // Notify listeners for UI update
      paymentProvider.notifyListeners();
      notifyListeners();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Current user moved to previous users successfully."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error moving current user: $e");
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
    final joinedDateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd')
            .format(DateTime.now())); // Default to today's date

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
              // Date picker for the joinedDate
              InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    joinedDateController.text = DateFormat('yyyy-MM-dd')
                        .format(pickedDate); // Set the picked date
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: joinedDateController,
                    decoration: const InputDecoration(labelText: "Joined Date"),
                  ),
                ),
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
                final aqarat = aqaratController.text;
                final joinedDate =
                    joinedDateController.text; // Get the joined date

                if (name.isNotEmpty &&
                    phone.isNotEmpty &&
                    joinedDate.isNotEmpty) {
                  try {
                    final paymentProvider =
                        Provider.of<PaymentProvider>(context, listen: false);

                    // Fetch the place from PaymentProvider using the id
                    final place = paymentProvider.places?.firstWhere(
                      (place) => place.id == id,
                      orElse: () => Place(
                          id: '',
                          name: 'Unknown',
                          amount: 0.0,
                          items: [],
                          itemsString: '',
                          place: '',
                          phone: '',
                          joinedDate: '',
                          currentUser: null,
                          year: 0,
                          previousUsers: []),
                    );

                    if (place == null) {
                      // Handle error if place is not found
                      debugPrint("Place not found");
                      return;
                    }

                    // Prepare the current user data
                    final currentUser = {
                      'name': name,
                      'phone': phone,
                      'amount': amount,
                      'aqarat': aqarat,
                      'dateLeft': '',
                      'payments': {},
                      'joinedDate': joinedDate,
                    };

                    // Update the currentUser in PaymentProvider
                    place?.currentUser = currentUser;

                    // Update Firestore
                    FirebaseFirestore.instance
                        .collection('places')
                        .doc(id)
                        .update({
                      'currentUser': currentUser,
                    });

                    // Notify listeners to refresh the UI
                    paymentProvider.notifyListeners();
                    notifyListeners();
                    // Navigator.of(context).pop();

                    // Show success message
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(
                    //     content: Text("Current User added successfully!"),
                    //     backgroundColor: Colors.green,
                    //   ),
                    // );
                  } catch (e) {
                    debugPrint("Error adding current user: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
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
      String updatedInfo, BuildContext context, String id) async {
    try {
      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);

      // Find the Place by id in PaymentProvider
      final place = paymentProvider.places?.firstWhere(
        (place) => place.id == id,
        orElse: () => Place(
            id: '',
            name: 'Unknown',
            amount: 0.0,
            items: [],
            itemsString: '',
            place: '',
            phone: '',
            joinedDate: '',
            currentUser: null,
            year: 0,
            previousUsers: []),
      );

      if (place == null) {
        // Handle the error if the place is not found
        debugPrint("Place not found");
        return;
      }

      // Update Firestore with the new payment and information
      await FirebaseFirestore.instance.collection('places').doc(id).update({
        'currentUser.payments.$monthStart': updatedValue,
        'currentUser.information.$monthStart': updatedInfo,
      });

      // Update the local state in PaymentProvider
      place.currentUser?['payments'][monthStart] = updatedValue;
      place.currentUser?['information'][monthStart] = updatedInfo;

      // Notify listeners to update the UI
      paymentProvider.notifyListeners();

      // Get the current context from Scaffold's parent to show the SnackBar
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text("Payment updated successfully"),
      //     backgroundColor: Colors.green,
      //   ),
      // );
    } catch (e) {
      debugPrint("Error updating payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update payment"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void editPayment(
      BuildContext context, String monthStart, String currentValue, String id) {
    final amountController = TextEditingController(text: currentValue);
    final infoController = TextEditingController(text: '');

    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);

    if (paymentProvider.places == null) {
      print("Error: paymentProvider.places is null");
      return;
    }

    final place = paymentProvider.places?.firstWhere(
      (place) {
        print("Checking place: ${place.id}");
        return place.id == id;
      },
      orElse: () {
        print("Place not found, returning default.");
        return Place(
            id: '',
            name: 'Unknown',
            amount: 0.0,
            items: [],
            itemsString: '',
            place: '',
            phone: '',
            joinedDate: '',
            currentUser: null,
            year: 0,
            previousUsers: []);
      },
    );

    print("Place selected: ${place?.id}");

    print('before');

    // Check if currentUser exists and handle gracefully
    if (place?.currentUser != null) {
      print("Current user found: ${place?.currentUser}");

      final infoMap =
          place?.currentUser?['information'] as Map<String, dynamic>? ?? {};
      final monthInfo = infoMap[monthStart] ?? '';

      print("Month Info: $monthInfo");

      infoController.text = monthInfo;
      print('inside');
    } else {
      print("Error: currentUser is null.");
    }

    print('after');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Payment for $monthStart"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Enter payment amount"),
              ),
              TextField(
                controller: infoController,
                decoration: const InputDecoration(
                    labelText: "Enter payment information"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final updatedValue = amountController.text;
                final updatedInfo = infoController.text;

                // Wait for savePayment to complete
                await savePayment(
                    monthStart, updatedValue, updatedInfo, context, id);

                // Close the dialog after saving
                notifyListeners();
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

  List<Map<String, String>> generatePagedMonthlyList(DateTime joinedDate) {
    List<Map<String, String>> months = [];

    // Start from the exact joinedDate.
    DateTime currentStartDate = joinedDate;

    // Adjust pagination based on currentPage and itemsPerPage.
    currentStartDate =
        currentStartDate.add(Duration(days: currentPage * itemsPerPage * 30));

    for (int i = 0; i < itemsPerPage; i++) {
      // Calculate the end date, 30 days from the start date.
      DateTime currentEndDate = currentStartDate.add(Duration(days: 30));

      // Format start and end dates as 'yyyy-MM-dd'.
      String startFormatted =
          "${currentStartDate.year}-${currentStartDate.month.toString().padLeft(2, '0')}-${currentStartDate.day.toString().padLeft(2, '0')}";
      String endFormatted =
          "${currentEndDate.year}-${currentEndDate.month.toString().padLeft(2, '0')}-${currentEndDate.day.toString().padLeft(2, '0')}";

      months.add({
        'start': startFormatted,
        'end': endFormatted,
      });

      // Move to the next 30-day period.
      currentStartDate =
          currentEndDate; // Start the next period 30 days after the current one
    }

    return months;
  }

  Widget buildPaymentsSection(
      Map<String, dynamic> payments,
      String sectionTitle,
      String id,
      BuildContext context,
      List<Map<String, String>> filteredMonths, // Use pre-filtered months
      DateTime joinedDate,
      String amount) {
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
                columns: [
                  DataColumn(label: Text("Period")),
                  DataColumn(label: Text("Amount ($amount)")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Information")), // New column
                  DataColumn(label: Text("Actions")),
                ],
                rows:
                    generatePaymentRows(payments, id, context, filteredMonths),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 0
                      ? () {
                          currentPage -= 1;
                          (context as Element).markNeedsBuild();
                        }
                      : null,
                  child: const Text("Previous"),
                ),
                ElevatedButton(
                  onPressed: () {
                    currentPage += 1;
                    (context as Element).markNeedsBuild();
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
    // Fetch the PaymentProvider to access the places
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);

    // Find the place by its id
    final place = paymentProvider.places?.firstWhere(
      (place) => place.id == id,
      orElse: () => Place(
          id: '',
          name: 'Unknown',
          amount: 0.0,
          items: [],
          itemsString: '',
          place: '',
          phone: '',
          joinedDate: '',
          currentUser: null,
          year: 0,
          previousUsers: []),
    );

    // Check if the place is null or does not have a currentUser
    if (place == null || place.currentUser == null) {
      return [];
    }

    final information =
        Map<String, dynamic>.from(place.currentUser?['information'] ?? {});

    return filteredMonths.map((month) {
      final amount = payments[month['start']]?.toString() ?? '0';
      final info = (information[month['start']] == null ||
              information[month['start']].toString().trim().isEmpty)
          ? 'N/A'
          : information[month['start']];
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
              style: const TextStyle(
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
            Text(
              info,
              style: const TextStyle(fontSize: 14),
            ),
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
