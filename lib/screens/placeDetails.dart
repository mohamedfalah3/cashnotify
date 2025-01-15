import 'package:cashnotify/helper/placeDetailsHelper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final String id;

  const PlaceDetailsScreen({Key? key, required this.id}) : super(key: key);

  @override
  _PlaceDetailsScreenState createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final placeDetails =
          Provider.of<PlaceDetailsHelper>(context, listen: false);
      placeDetails.fetchPlaceDetails(widget.id, context);
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    final placeDetails = Provider.of<PlaceDetailsHelper>(context);
    if (placeDetails.placeSnapshot == null) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Loading..."),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentUser = placeDetails.placeSnapshot?['currentUser'];
    final previousUsers = List<Map<String, dynamic>>.from(
        placeDetails.placeSnapshot?['previousUsers'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text("Place Details"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          _buildDateFilter(),
          Expanded(
            child: ListView(
              children: [
                if (currentUser != null) ...[
                  const SizedBox(height: 16),
                  buildFilteredCurrentUserPaymentsSection(currentUser),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No current user for this place"),
                  ),
                ],
                const SizedBox(height: 24),
                _buildPreviousUsersSection(previousUsers),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
              onPressed: () {
                placeDetails.confirmAndMoveCurrentUserToPrevious(
                    context, widget.id);
              },
              backgroundColor: Colors.deepPurple,
              tooltip: "Move Current User to Previous Users",
              child: const Icon(Icons.person_remove),
            )
          : FloatingActionButton(
              onPressed: () => placeDetails.addCurrentUser(context, widget.id),
              backgroundColor: Colors.deepPurple,
              tooltip: "Add New User to Current User",
              child: const Icon(Icons.add),
            ),
    );
  }

  /// Build the date filter widget
  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // From Date Picker
          _buildDatePicker(
            label: "From",
            selectedDate: _fromDate,
            onDateSelected: (date) {
              setState(() {
                _fromDate = date;
              });
            },
          ),
          // To Date Picker
          _buildDatePicker(
            label: "To",
            selectedDate: _toDate,
            onDateSelected: (date) {
              setState(() {
                _toDate = date;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Helper function to build a single date picker
  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              onDateSelected(pickedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(selectedDate)
                  : "Select Date",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoSection(Map<String, dynamic> user, String userType) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: userType == "Previous User" ? Colors.grey[200] : null,
      // Light color for previous users
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Name: ${user['name']}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (userType == "Previous User") // Badge for previous users
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Text(
                      "Previous User",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (user['dateLeft'] != null)
              Text(
                "Date Left: ${user['dateLeft']}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildFilteredCurrentUserPaymentsSection(
      Map<String, dynamic> currentUser) {
    final placeDetails = Provider.of<PlaceDetailsHelper>(context);

    final payments = Map<String, dynamic>.from(currentUser['payments'] ?? {});
    final joinedDate = currentUser['joinedDate'] != null
        ? DateTime.tryParse(currentUser['joinedDate'])
        : null;

    if (joinedDate == null) {
      return const Text("Invalid joined date for current user.");
    }

    // Filter payments based on selected date range
    final filteredPayments = Map.fromEntries(
      payments.entries.where((entry) {
        final paymentDate = DateTime.tryParse(entry.key);
        if (paymentDate == null) return false;

        // Ensure the payment's date is within the selected range
        if (_fromDate != null && paymentDate.isBefore(_fromDate!)) return false;
        if (_toDate != null && paymentDate.isAfter(_toDate!)) return false;

        return true;
      }),
    );

    // Filter months to show only those in the range
    final filteredMonths =
        placeDetails.generatePagedMonthlyList(DateTime.now()).where((month) {
      final startDate = DateTime.parse(month['start']!);
      final endDate = DateTime.parse(month['end']!);

      // Only keep months that are within the selected date range
      if ((_fromDate != null && endDate.isBefore(_fromDate!)) ||
          (_toDate != null && startDate.isAfter(_toDate!))) {
        return false; // Exclude this month interval if it's outside the date range
      }
      return true;
    }).toList();

    // Pass filtered months and payments to buildPaymentsSection
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current User: ${currentUser['name'] ?? 'No name'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Now we use filtered months and filtered payments
            placeDetails.buildPaymentsSection(
              filteredPayments, // Pass only filtered payments
              'Filtered Current User Payments',
              widget.id,
              context,
              filteredMonths, // Pass filtered months to ensure only relevant intervals are shown
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousUserPaymentsSection(
      Map<String, dynamic> previousUserPayments) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Previous User Payments",
              style: TextStyle(
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
                ],
                rows: _buildPaymentRowsForPreviousUser(previousUserPayments),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _buildPaymentRowsForPreviousUser(
      Map<String, dynamic> previousUserPayments) {
    List<DataRow> rows = [];

    previousUserPayments.forEach((date, payment) {
      // Convert date string to DateTime object
      DateTime paymentDate = DateTime.parse(date);

      // Add 30 days to the payment date
      DateTime paymentPeriodEnd = paymentDate.add(const Duration(days: 30));

      // Check if the payment value exists and is not zero
      String paymentAmount =
          payment != null && payment != '0' ? payment.toString() : '0';
      String status = paymentAmount != '0' ? 'Paid' : 'Unpaid';

      // Add the row for the payment
      rows.add(
        DataRow(
          color: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            return Colors.grey[100]; // Light background for previous users
          }),
          cells: [
            DataCell(Text(
                "${paymentDate.toLocal().toString().split(' ')[0]} - ${paymentPeriodEnd.toLocal().toString().split(' ')[0]}")),
            DataCell(Text("\$$paymentAmount")),
            DataCell(Text(status)),
          ],
        ),
      );
    });

    return rows;
  }

  Widget _buildPreviousUsersSection(List<Map<String, dynamic>> previousUsers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Previous Users",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (previousUsers.isEmpty)
          const Text("No previous users found.")
        else
          ...previousUsers.map((user) {
            final payments = Map<String, dynamic>.from(user['payments'] ?? {});
            return Column(
              children: [
                _buildUserInfoSection(user, "Previous User"),
                const SizedBox(height: 16),
                _buildPreviousUserPaymentsSection(payments),
                const Divider(),
              ],
            );
          }).toList(),
      ],
    );
  }
}
