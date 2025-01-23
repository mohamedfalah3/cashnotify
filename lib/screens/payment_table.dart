import 'package:cashnotify/helper/dateTimeProvider.dart';
import 'package:cashnotify/helper/pdfHelper.dart' as wow;
import 'package:cashnotify/screens/placeDetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../helper/helper_class.dart';
import '../widgets/notificationIcon.dart';
import '../widgets/searchExportButton.dart';

class PaymentTable extends StatefulWidget {
  const PaymentTable({super.key});

  @override
  State<PaymentTable> createState() => _PaymentTableState();
}

class _PaymentTableState extends State<PaymentTable>
    with SingleTickerProviderStateMixin {
  Stream<QuerySnapshot>? filteredStream;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;

  bool isLoading = true;

  void fetchFilteredData(int year) async {
    setState(() {
      isLoading = true;
    });

    final placesProvider = Provider.of<PaymentProvider>(context, listen: false);
    // await placesProvider.fetchComments(year);

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();

    // Fetch initial data for places
    Future.microtask(() {
      final placesProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      placesProvider.fetchPlaces();
    });

    // Perform post-frame initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dateTimeProvider =
          Provider.of<DateTimeProvider>(context, listen: false);

      fetchFilteredData(dateTimeProvider.selectedYear);
    });

    // Initialize the animation controller
    _controller = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 700), // Duration for full animation
    )..repeat(reverse: true); // Repeat the animation

    // Define the scale animation (size bounce)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Define the rotation animation
    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Define the color animation (pulse effect)
    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.orange,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PaymentProvider>(context);
    final dateTimeProvider = Provider.of<DateTimeProvider>(context);

    final Map<String, int> prefixCounters = {};
    final List<Map<String, dynamic>> tableData =
        (placesProvider.filteredPlaces?.map((place) {
              // Access currentUser data directly from the Place model instance
              final currentUser = place.currentUser;

              // Safely access fields inside currentUser
              final id = place.id;
              final name = currentUser?['name'] ?? 'Unknown';
              final placeName = place.place ?? 'Unknown Place';
              final amount = currentUser?['amount'] ?? '0';
              final phone = currentUser?['phone'] ?? '0';
              final dateJoined = currentUser?['joinedDate'] ?? '0';
              final dateLeft = currentUser?['dateLeft'] ?? 'N/A';
              final aqarat = currentUser?['aqarat'] ?? 'N/A';

              // Assuming items is a List<String>
              final List<String>? items = place.items;
              final itemsString = items != null && items.isNotEmpty
                  ? items.join(', ')
                  : 'No code';

              // Get prefix: Allow either 2 or 3 letters as a prefix
              String prefix = itemsString.split('/').first;

              // Ensure we handle both 2-letter and 3-letter prefixes correctly
              if (prefix.length >= 3) {
                prefix = prefix.substring(0, 3).toUpperCase();
              } else if (prefix.length >= 2) {
                prefix = prefix.substring(0, 2).toUpperCase();
              } else {
                prefix = prefix.toUpperCase();
              }

              // Determine the starting value for the prefix
              if (!prefixCounters.containsKey(prefix)) {
                prefixCounters[prefix] = prefix.startsWith('C24') ? 0 : 1;
              } else {
                prefixCounters[prefix] = prefixCounters[prefix]! + 1;
              }

              return {
                'docId': id,
                'sequence': prefixCounters[prefix],
                'name': name,
                'place': placeName, // 'place' is the name of the place
                'itemsString': itemsString,
                'amountString': amount.toString(), // `amount` is a string
                'phone': phone,
                'dateJoined': dateJoined,
                'dateLeft': dateLeft,
                'aqarat': aqarat,
              };
            }).toList()) ??
            [];

    final List<String> manualPlaceNames = [
      'Ganjan City',
      'Ainkawa',
    ];

    dateTimeProvider.totalItems = tableData.length;
    final paginatedData = dateTimeProvider.getPaginatedData(tableData);

    List<DataRow> buildRows(List<Map<String, dynamic>> data) {
      return data.map((row) {
        return DataRow(
          onSelectChanged: (selected) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceDetailsScreen(id: row['docId']),
              ),
            );
          },
          cells: [
            DataCell(Text(row['name'] ?? 'No name')),
            DataCell(Text(row['itemsString'] ?? 'No code')),
            DataCell(Text(row['amountString'] ?? '0')),
            DataCell(Text(row['dateJoined'] ?? '0')),
            DataCell(Text(row['aqarat'] ?? '0')),
          ],
        );
      }).toList();
    }

    return GestureDetector(
      onTap: () {
        placesProvider.overlayEntry?.remove();
        placesProvider.overlayEntry = null;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Cash Collection'),
          actions: [
            // Notification Icon
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Notificationicon(onPressed: () {
                    placesProvider.toggleDropdown(context);
                  }),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _colorAnimation.value,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Filter Button
            // IconButton(
            //   icon: const Icon(Icons.filter_alt_outlined),
            //   onPressed: () => showFilterDialog(context, placesProvider),
            // ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Total Amount Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.deepPurple.shade100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount: \$${placesProvider.totalMoneyCollected.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SearchExport(
                searchController: placesProvider.searchController,
                onSearch: (query) {
                  placesProvider.filterData(
                      query, placesProvider.selectedPlaceName);
                },
                showFilter: showFilterDialog,
                paymentProvider: placesProvider,
              ),
              // Show/Hide Table Section
              if (showTable)
                isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.deepPurple,
                        ),
                      )
                    : Scrollbar(
                        thumbVisibility: true,
                        controller: placesProvider.scrollController,
                        child: SingleChildScrollView(
                          controller: placesProvider.scrollController,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(30),
                              child: DataTable(
                                columnSpacing: 20.0,
                                dataRowColor: WidgetStateColor.resolveWith(
                                  (states) => Colors.deepPurple.shade50,
                                ),
                                headingRowColor: WidgetStateColor.resolveWith(
                                  (states) => Colors.deepPurpleAccent.shade100,
                                ),
                                border: TableBorder.all(
                                    color: Colors.deepPurple, width: 1.0),
                                columns: placesProvider.buildColumns(),
                                rows: buildRows(paginatedData),
                              ),
                            ),
                          ),
                        ),
                      ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.deepPurple.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: dateTimeProvider.currentPage > 1
                              ? () =>
                                  setState(() => dateTimeProvider.currentPage--)
                              : null,
                          icon: Icon(
                            Icons.arrow_back,
                            color: dateTimeProvider.currentPage > 1
                                ? Colors.deepPurple
                                : Colors.grey,
                          ),
                          splashRadius: 24,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${dateTimeProvider.currentPage} / ${((dateTimeProvider.totalItems - 1) ~/ dateTimeProvider.itemsPerPage) + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: dateTimeProvider.currentPage *
                                      dateTimeProvider.itemsPerPage <
                                  dateTimeProvider.totalItems
                              ? () =>
                                  setState(() => dateTimeProvider.currentPage++)
                              : null,
                          icon: Icon(
                            Icons.arrow_forward,
                            color: dateTimeProvider.currentPage *
                                        dateTimeProvider.itemsPerPage <
                                    dateTimeProvider.totalItems
                                ? Colors.deepPurple
                                : Colors.grey,
                          ),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool showTable = true;

  String? selectedReportType = 'Custom Report'; // Default value
  List<String> reportTypes = [
    'Custom Report',
    'Yearly Report',
    'Summary Report',
    'Payment History',
    'Empty Places'
  ];

  void showFilterDialog(BuildContext context, PaymentProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                'Select Report Type',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple, // Deep purple title color
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedReportType,
                    isExpanded: true,
                    items: reportTypes.map((String report) {
                      return DropdownMenuItem<String>(
                        value: report,
                        child: Text(
                          report,
                          style: TextStyle(
                              color: Colors.deepPurple[800]), // Item color
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedReportType = value!;
                        print("Dropdown changed to: $selectedReportType");
                      });
                    },
                    dropdownColor: Colors.deepPurple[50],
                    // Dropdown background
                    iconEnabledColor: Colors.deepPurple, // Icon color
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.deepPurple, // Cancel button color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedReportType == null) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              'Error',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            content: Text(
                              'Please select a report type.',
                              style: TextStyle(
                                color: Colors
                                    .deepPurple[700], // Error content color
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'OK',
                                  style: TextStyle(color: Colors.deepPurple),
                                ),
                              ),
                            ],
                            backgroundColor: Colors.deepPurple[50],
                            // Error background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          );
                        },
                      );
                      return;
                    }

                    final pdf = pw.Document();
                    final font = await rootBundle.load(
                        "assets/fonts/Roboto-Italic-VariableFont_wdth,wght.ttf");
                    final ttf = pw.Font.ttf(font);
                    Navigator.of(context).pop();

                    switch (selectedReportType) {
                      case 'Custom Report':
                        wow.pdfHelper().generateCustomReport(context, provider);
                        break;
                      case 'Yearly Report':
                        wow
                            .pdfHelper()
                            .generateYearlyReport(pdf, provider, ttf, context);
                        break;
                      case 'Summary Report':
                        wow
                            .pdfHelper()
                            .generateSummaryReport(pdf, provider, ttf);
                        break;
                      case 'Payment History':
                        wow
                            .pdfHelper()
                            .generatePaymentHistory(pdf, provider, ttf);
                        break;
                      case 'Empty Places':
                        wow.pdfHelper().generateEmptyAndOccupiedPlacesReport(
                            pdf, provider, ttf);
                        break;
                      default:
                        break;
                    }
                    print(selectedReportType);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    // Button background color
                    foregroundColor: Colors.white,
                    // Button text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Button corners
                    ),
                  ),
                  child: Text('Generate Report'),
                ),
              ],
              backgroundColor: Colors.deepPurple[50],
              // Dialog background color
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16), // Dialog rounded corners
              ),
            );
          },
        );
      },
    );
  }
}
