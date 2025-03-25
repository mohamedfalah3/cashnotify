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
          content: Text("داتا بوونی نیە"),
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

      // Fetch the place object
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

      if (place?.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          _customSnackBar('هیچ کەسێک نیە بۆ گواستنەوە', Colors.red),
        );
        return;
      }

      final currentUser = place!.currentUser;
      final previousUsers =
          List<Map<String, dynamic>>.from(place.previousUsers ?? []);

      // Extract payments and remove '0' or null values
      final payments =
          Map<String, dynamic>.from(currentUser?['payments'] ?? {});
      final filteredPayments = Map<String, dynamic>.from(payments)
        ..removeWhere((key, value) => value == '0' || value == null);

      // Create updated user data
      final updatedUser = {
        'name': currentUser?['name'] ?? 'Unknown',
        'phone': currentUser?['phone'] ?? 'Unknown',
        'payments': filteredPayments,
        'joinedDate': currentUser?['joinedDate'] ?? 'Unknown',
        'dateLeft': dateLeft,
        'amount': currentUser?['amount'] ?? 'N/A',
        'taminat': currentUser?['taminat'] ?? 'N/A',
        'information': currentUser?['information'] ?? {},
        'aqarat': currentUser?['aqarat'] ?? 'N/A',
      };

      previousUsers.add(updatedUser);

      // Update Firestore and UI state
      place.currentUser = null;
      place.previousUsers = previousUsers;

      await FirebaseFirestore.instance.collection('places').doc(id).update({
        'currentUser': null,
        'previousUsers': previousUsers,
      });

      // Notify UI
      paymentProvider.notifyListeners();
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        _customSnackBar(
          "بە سەرکەوتویی گۆڕدرا",
          const Color.fromARGB(255, 0, 122, 255),
        ),
      );
    } catch (e) {
      debugPrint("Error moving current user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        _customSnackBar("گۆڕانەکە سەرکەوتوو نەبوو", Colors.red),
      );
    }
  }

  Future<void> confirmAndMoveCurrentUserToPrevious(
      BuildContext context, String id) async {
    final shouldMove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "دڵنیابوون",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 122, 255),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: const Text(
            "دڵنیای لە گواستنەوەی کرێچی؟",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("نەخێر", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 122, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("بەڵێ"),
            ),
          ],
        );
      },
    );

    if (shouldMove == true) {
      // Show custom-styled date picker
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: const Color.fromARGB(255, 0, 122, 255),
              colorScheme: const ColorScheme.light(
                primary: Color.fromARGB(255, 0, 122, 255),
              ),
              buttonTheme:
                  const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        final dateLeft = DateFormat('yyyy-MM-dd').format(pickedDate);
        await _moveCurrentUserToPrevious(dateLeft, id, context);
      }
    }
  }

// Custom snack bar for better messages
  SnackBar _customSnackBar(String message, Color color) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    );
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void addCurrentUser(BuildContext context, String id) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final aqaratController = TextEditingController();
    final taminatController = TextEditingController();
    final joinedDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()), // Default to today
    );

    final formKey = GlobalKey<FormState>(); // Form key for validation

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "زیادکردنی کرێچی",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 122, 255),
            ),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey, // Wrap with Form widget
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    nameController,
                    "ناو",
                    Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ناوەکە پێویستە بنووسیت';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    phoneController,
                    "ژمارە",
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ژمارەی موبایل داواکراوە';
                      }
                      final RegExp iraqPhoneRegex = RegExp(r'^07[0-9]{9}$');
                      if (!iraqPhoneRegex.hasMatch(value)) {
                        return 'تکایە ژمارەی دروست بنوسە (11 ژمارە بەپێی 07)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    amountController,
                    "بڕێ پارە",
                    Icons.monetization_on,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(taminatController, "تامینات", Icons.person,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  _buildTextField(aqaratController, "عقارات", Icons.home),
                  const SizedBox(height: 10),
                  _buildDateField(
                      context, joinedDateController, "بەرواری هاتن"),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("لابردن", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return; // Prevent submission if form is invalid
                }

                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final amount = amountController.text.trim();
                final aqarat = aqaratController.text.trim();
                final taminat = taminatController.text.trim();
                final joinedDate = joinedDateController.text.trim();

                try {
                  final paymentProvider =
                      Provider.of<PaymentProvider>(context, listen: false);

                  // Find place
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
                  if (place == null) {
                    debugPrint("❌ Place not found");
                    return;
                  }

                  final currentUser = {
                    'name': name,
                    'phone': phone,
                    'amount': amount,
                    'aqarat': aqarat,
                    'dateLeft': '',
                    'taminat': taminat,
                    'payments': {},
                    'information': {},
                    'joinedDate': joinedDate,
                  };

                  // Update the place in memory
                  place.currentUser = currentUser;

                  // Update Firestore
                  await FirebaseFirestore.instance
                      .collection('places')
                      .doc(id)
                      .update({
                    'currentUser': currentUser,
                  });

                  // Notify UI
                  paymentProvider.notifyListeners();
                  notifyListeners();
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint("⚠️ Error adding current user: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('سەرکەوتوو نەبوو'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("زیادکردن"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator, // Optional validator
    TextInputType keyboardType = TextInputType.text, // Default text input
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: keyboardType,
      validator: validator, // Apply validation if provided
    );
  }

  Widget _buildDateField(
      BuildContext context, TextEditingController controller, String label) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
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

      // Update the local state in PaymentProvider
      place.currentUser?['payments'][monthStart] = updatedValue;
      place.currentUser?['information'][monthStart] = updatedInfo;

      // Update Firestore with the new payment and information
      FirebaseFirestore.instance.collection('places').doc(id).update({
        'currentUser.payments.$monthStart': updatedValue,
        'currentUser.information.$monthStart': updatedInfo,
      });

      // Notify listeners to update the UI
      paymentProvider.notifyListeners();
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating payment: $e");
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

      final infoMap = place?.currentUser?['information'] != null
          ? Map<String, dynamic>.from(place!.currentUser!['information'])
          : {};
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
          title: Text("$monthStart"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "بڕی پارە"),
              ),
              TextField(
                controller: infoController,
                decoration: const InputDecoration(labelText: "زانیاری زیاتر"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text("لابردن"),
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
              child: const Text("دڵنیابونەوە"),
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
      DateTime currentEndDate = currentStartDate.add(const Duration(days: 30));

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
    String id,
    BuildContext context,
    List<Map<String, String>> filteredMonths,
    DateTime joinedDate,
    String amount,
  ) {
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
        previousUsers: [],
      ),
    );

    // Fetch 'taminat' from currentUser
    final taminat = place?.currentUser?['taminat']?.toString().trim();
    final displayTaminat =
        (taminat == null || taminat.isEmpty) ? "نیە" : taminat;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display 'amount' and 'taminat' in a clearer way
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "\$ $amount",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Text(
                  "بڕی پارە",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    place?.place ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const Text(
                  "ناونیشان",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$ $displayTaminat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          displayTaminat == "نیە" ? Colors.red : Colors.green,
                    ),
                  ),
                ),
                const Text(
                  "تامینات",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("ماوە")),
                  DataColumn(label: Text("بڕی پارە ")),
                  DataColumn(label: Text("دۆخ")),
                  DataColumn(label: Text("زانیاری زیاتر")),
                  DataColumn(label: Text("کردارەکان")),
                ],
                rows:
                    generatePaymentRows(payments, id, context, filteredMonths),
              ),
            ),

            const SizedBox(height: 16),

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
                  child: const Text("پێشوو"),
                ),
                ElevatedButton(
                  onPressed: () {
                    currentPage += 1;
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text("دواتر"),
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
          previousUsers: []),
    );

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
        color: MaterialStateProperty.resolveWith<Color?>((states) {
          if (isUnpaid) return Colors.red.shade50;
          return null;
        }),
        cells: [
          DataCell(
            Text(
              "${month['start']} - ${month['end']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: isUnpaid ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "\$${double.parse(amount).toStringAsFixed(2)}",
                style: TextStyle(
                  color: isUnpaid ? Colors.red : Colors.green[900],
                  fontWeight: FontWeight.bold,
                ),
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
                        isCurrentMonth ? "نەدراوە (ئەم مانگە)" : "نەدراوە",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "دراوە",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ),
          DataCell(
            Text(
              info,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          DataCell(
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Color.fromARGB(255, 0, 122, 255),
              ),
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
