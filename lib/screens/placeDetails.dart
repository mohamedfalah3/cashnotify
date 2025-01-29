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
          Expanded(
            child: ListView(
              children: [
                (currentUser == null || currentUser == {})
                    ? const Center()
                    : _buildDateFilter(),
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
                buildPreviousUsersSection(previousUsers),
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
          const Text(
            "Filter by Date",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          _buildDateRangePicker(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// 🗓 Helper function to build the date range picker
  Widget _buildDateRangePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildRangePicker()),
        const SizedBox(width: 10),
        if (_fromDate != null || _toDate != null) _buildRemoveFilterButton(),
      ],
    );
  }

  /// 📅 Custom Date Picker Button
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple.shade300, width: 1.5),
          color: Colors.deepPurple.shade50,
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.shade100,
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today,
                color: Colors.deepPurple, size: 18),
            const SizedBox(width: 10),
            Text(
              _fromDate != null && _toDate != null
                  ? "${DateFormat('yyyy-MM-dd').format(_fromDate!)} → ${DateFormat('yyyy-MM-dd').format(_toDate!)}"
                  : "Select Date Range",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ❌ Remove Filter Button
  Widget _buildRemoveFilterButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _fromDate = null;
          _toDate = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade400,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.shade200,
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.close, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              "Clear Filter",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
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

  /// 🟣 Builds the Previous Users Section
  Widget buildPreviousUsersSection(List<Map<String, dynamic>> previousUsers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Previous Users",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 12),
        if (previousUsers.isEmpty) _buildEmptyState("No previous users found."),
        ...previousUsers.map((user) {
          final payments = Map<String, dynamic>.from(user['payments'] ?? {});
          final info = Map<String, dynamic>.from(user['information'] ?? {});
          return Column(
            children: [
              _buildUserInfoCard(user),
              const SizedBox(height: 12),
              _buildPreviousUserPaymentsCard(user, payments, info),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// 📌 Builds User Info Card
  Widget _buildUserInfoCard(Map<String, dynamic> user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey[100], // Soft background for previous users
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Name: ${user['name'] ?? 'Unknown'}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                _buildUserBadge(),
              ],
            ),
            if (user['dateLeft'] != null &&
                user['dateLeft'].toString().isNotEmpty)
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

  /// 🟣 Builds Payment Info Card (Excludes 0 Payments)
  Widget _buildPreviousUserPaymentsCard(
      Map<String, dynamic> user,
      Map<String, dynamic> previousUserPayments,
      Map<String, dynamic> informationMap) {
    final filteredPayments = previousUserPayments.entries
        .where((entry) => entry.value != null && entry.value.toString() != '0')
        .toList();

    if (filteredPayments.isEmpty) {
      return _buildEmptyState("No payments recorded for ${user['name']}");
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment History (${user['name']})",
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
                  DataColumn(label: Text('Information')),
                ],
                rows: _buildPaymentRowsForPreviousUser(
                    filteredPayments, informationMap),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔵 Builds Payment Row Data (Filters out zero payments)
  List<DataRow> _buildPaymentRowsForPreviousUser(
      List<MapEntry<String, dynamic>> previousUserPayments,
      Map<String, dynamic> informationMap) {
    return previousUserPayments.map((entry) {
      final date = entry.key;
      final payment = entry.value;

      DateTime paymentDate = DateTime.parse(date);
      DateTime paymentPeriodEnd = paymentDate.add(const Duration(days: 30));

      String paymentAmount = payment.toString();
      String status = paymentAmount != '0' ? 'Paid' : 'Unpaid';

      String information = (informationMap[date] == null ||
              informationMap[date].toString().trim().isEmpty)
          ? "No Info"
          : informationMap[date];

      return DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) => Colors.grey[100]),
        cells: [
          DataCell(Text(
              "${paymentDate.toLocal().toString().split(' ')[0]} - ${paymentPeriodEnd.toLocal().toString().split(' ')[0]}")),
          DataCell(Text("\$$paymentAmount")),
          DataCell(Text(status)),
          DataCell(Text(information)), // Info Column
        ],
      );
    }).toList();
  }

  /// 🔹 Creates a Badge for Previous Users
  Widget _buildUserBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
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
    );
  }

  /// ⚠️ Handles Empty State UI
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
