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
          (currentUser == null || currentUser == {})
              ? const Center()
              : _buildDateFilter(),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Picker
          _buildDateRangePicker(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Helper function to build the date range picker
  Widget _buildDateRangePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Date Picker
        _buildRangePicker(),
        // Remove Filter Button
        if (_fromDate != null || _toDate != null) _buildRemoveFilterButton(),
      ],
    );
  }

  Widget _buildRangePicker() {
    return InkWell(
      onTap: () async {
        final DateTimeRange? pickedRange = await showDateRangePicker(
          context: context,
          initialDateRange: _fromDate != null && _toDate != null
              ? DateTimeRange(start: _fromDate!, end: _toDate!)
              : DateTimeRange(
                  start: DateTime.now(),
                  end: DateTime.now(),
                ),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedRange != null) {
          setState(() {
            _fromDate = pickedRange.start;
            _toDate = pickedRange.end;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.shade50,
              spreadRadius: 2,
              blurRadius: 6,
              offset: Offset(0, 2), // Shadow position
            ),
          ],
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Text(
          _fromDate != null && _toDate != null
              ? "${DateFormat('yyyy-MM-dd').format(_fromDate!)} - ${DateFormat('yyyy-MM-dd').format(_toDate!)}"
              : "Select Date Range",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Helper function to build the remove filter button
  Widget _buildRemoveFilterButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _fromDate = null;
          _toDate = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.shade200,
              blurRadius: 4,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          "Remove Filter",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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

    // Adjust _fromDate to consider joinedDate
    final effectiveFromDate =
        (_fromDate != null && _fromDate!.isAfter(joinedDate))
            ? _fromDate
            : joinedDate;
    final effectiveToDate = _toDate;

    // Generate months starting from joinedDate
    final allMonths = placeDetails.generatePagedMonthlyList(joinedDate);
    final filteredMonths = allMonths.where((month) {
      final monthStart = DateTime.tryParse(month['start']!);
      final monthEnd = DateTime.tryParse(month['end']!);

      if (monthStart == null || monthEnd == null) return false;

      if (effectiveFromDate != null && monthEnd.isBefore(effectiveFromDate)) {
        return false;
      }
      if (effectiveToDate != null && monthStart.isAfter(effectiveToDate)) {
        return false;
      }

      return true;
    }).toList();

    // Filter payments based on the effective date range
    final filteredPayments = Map.fromEntries(
      payments.entries.where((entry) {
        final paymentDate = DateTime.tryParse(entry.key);
        if (paymentDate == null) return false;

        if (effectiveFromDate != null &&
            paymentDate.isBefore(effectiveFromDate)) {
          return false;
        }
        if (effectiveToDate != null && paymentDate.isAfter(effectiveToDate)) {
          return false;
        }

        return true;
      }),
    );

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
            placeDetails.buildPaymentsSection(
                filteredPayments,
                'Filtered Current User Payments',
                widget.id,
                context,
                filteredMonths,
                joinedDate,
                placeDetails.placeSnapshot!['currentUser']['amount']
                    .toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousUserPaymentsSection(
      Map<String, dynamic> previousUserPayments,
      Map<String, dynamic> informationMap) {
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
                  DataColumn(label: Text('Information'))
                ],
                rows: _buildPaymentRowsForPreviousUser(
                    previousUserPayments, informationMap),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _buildPaymentRowsForPreviousUser(
      Map<String, dynamic> previousUserPayments,
      Map<String, dynamic> informationMap) {
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

      // Get the information for the specific date
      String information = informationMap[date] ?? "No info";

      // Add the row for the payment
      rows.add(
        DataRow(
          color: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            return Colors.grey[100]; // Light background for previous users
          }),
          cells: [
            DataCell(Text(
                "${paymentDate.toLocal().toString().split(' ')[0]} - ${paymentPeriodEnd.toLocal().toString().split(' ')[0]}")),
            DataCell(Text("\$$paymentAmount")),
            DataCell(Text(status)),
            DataCell(Text(information)), // New column for information
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
            final info = Map<String, dynamic>.from(user['information'] ?? {});
            return Column(
              children: [
                _buildUserInfoSection(user, "Previous User"),
                const SizedBox(height: 16),
                _buildPreviousUserPaymentsSection(payments, info),
                const Divider(),
              ],
            );
          }).toList(),
      ],
    );
  }
}
