import 'package:cashnotify/helper/placeDetailsHelper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../helper/helper_class.dart';
import '../helper/place.dart';

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
    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);

    // Get the place by its ID (this should be passed or available)
    final place = paymentProvider.places?.firstWhere(
      (place) => place.id == widget.id,
      // Assuming you pass the placeId to this screen
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

    // Check if place data is available
    if (place == null) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text("Loading..."),
          backgroundColor: Color.fromARGB(255, 0, 122, 255),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Now you can access the currentUser and previousUsers directly from the place object
    final currentUser = place.currentUser;
    final previousUsers =
        List<Map<String, dynamic>>.from(place.previousUsers ?? []);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back)),
        backgroundColor: const Color.fromARGB(255, 0, 122, 255),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (currentUser != null && currentUser.isNotEmpty)
                  _buildDateFilter(),
                const SizedBox(height: 16),
                if (currentUser != null && currentUser.isNotEmpty)
                  buildFilteredCurrentUserPaymentsSection(currentUser)
                else
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 48, color: Colors.orange),
                      SizedBox(height: 12),
                      Text(
                        "ئەم مولکە کەسی تیا نیە",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                buildPreviousUsersSection(previousUsers),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton.extended(
              onPressed: () {
                placeDetails.confirmAndMoveCurrentUserToPrevious(
                    context, widget.id);
              },
              backgroundColor: Color.fromARGB(255, 0, 122, 255),
              icon: const Icon(Icons.person_remove, color: Colors.white),
              label: const Text(
                "دەرچوونی کرێچی",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () => placeDetails.addCurrentUser(context, widget.id),
              backgroundColor: Color.fromARGB(255, 0, 122, 255),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "هاتنی کرێچی",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
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
            "فلتەر کردن بە بەروار",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 122, 255),
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
          border:
              Border.all(color: Color.fromARGB(150, 0, 122, 255), width: 1.5),
          color: Colors.deepPurple.shade50,
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(100, 0, 122, 255),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today,
                color: Color.fromARGB(255, 0, 122, 255), size: 18),
            const SizedBox(width: 10),
            Text(
              _fromDate != null && _toDate != null
                  ? "${DateFormat('yyyy-MM-dd').format(_fromDate!)} → ${DateFormat('yyyy-MM-dd').format(_toDate!)}"
                  : "بەروار دابنێ",
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 0, 122, 255),
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
              "لابردنی فلتەر",
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

    // Fetch taminat field, return "None" if empty
    final taminat = (currentUser['taminat'] == null ||
            currentUser['taminat'].toString().trim().isEmpty)
        ? 'None'
        : currentUser['taminat'].toString();

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

    final paymentProvider =
        Provider.of<PaymentProvider>(context, listen: false);

    final place = paymentProvider.places?.firstWhere(
      (place) => place.id == widget.id,
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ناوی کرێچی: ${currentUser['name'] ?? 'نیە'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Build payments section using the PaymentProvider
            placeDetails.buildPaymentsSection(
              filteredPayments,
              widget.id,
              context,
              filteredMonths,
              joinedDate,
              place!.currentUser!['amount'].toString(),
            ),
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
          "کرێچی پێشوو",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 122, 255),
          ),
        ),
        const SizedBox(height: 12),
        if (previousUsers.isEmpty)
          _buildEmptyState("هیچ کرێچیەکی کۆن نەدۆزرایەوە"),
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
                  "ناو: ${user['name'] ?? 'Unknown'}",
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
                "بەرواری ڕۆشتن: ${user['dateLeft']}",
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
      return _buildEmptyState("هیچ پارە دانێک نیە بۆ :  ${user['name']}");
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
              "پارەدانی پێشوو (${user['name']})",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 122, 255),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("ماوە")),
                  DataColumn(label: Text("بڕی پارە")),
                  DataColumn(label: Text("دۆخ")),
                  DataColumn(label: Text('زانیاری زیاتر')),
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
      String status = paymentAmount != '0' ? 'دراوە' : 'نەدراوە';

      String information = (informationMap[date] == null ||
              informationMap[date].toString().trim().isEmpty)
          ? "نیە"
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
        color: Color.fromARGB(255, 0, 122, 255),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Text(
        "کرێچی پێشوو",
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
