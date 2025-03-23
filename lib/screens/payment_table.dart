import 'package:cashnotify/helper/dateTimeProvider.dart';
import 'package:cashnotify/helper/pdfHelper.dart' as wow;
import 'package:cashnotify/screens/placeDetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../helper/helper_class.dart';
import '../widgets/searchExportButton.dart';
import '../widgets/slider.dart';

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
              final name = currentUser?['name'] ?? 'بەتاڵ';
              final placeName = place.place ?? 'نیە';
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

    dateTimeProvider.totalItems = tableData.length;
    final paginatedData = dateTimeProvider.getPaginatedData(tableData);

    List<DataRow> buildRows(List<Map<String, dynamic>> data) {
      return data.map((row) {
        final bool isEmptyUser = row['name'] == 'بەتاڵ';

        return DataRow(
          color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (isEmptyUser) {
                return Colors.red.withOpacity(0.2); // Light red background
              }
              return null; // Default background
            },
          ),
          onSelectChanged: (selected) async {
            await Navigator.push(
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
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              double screenHeight = constraints.maxHeight;
              bool isMobile = screenWidth < 600;

              // Calculate available height after subtracting AppBar and SafeArea
              double appBarHeight = AppBar().preferredSize.height;
              double safeAreaHeight = screenHeight -
                  appBarHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom;

              return Column(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 16.0),
                    child: SearchExport(
                      searchController: placesProvider.searchController,
                      onSearch: (query) {
                        placesProvider.filterData(
                            query, placesProvider.selectedPlaceName);
                      },
                      showFilter: showFilterDialog,
                      paymentProvider: placesProvider,
                      controller: _controller,
                      scaleAnimation: _scaleAnimation,
                      rotationAnimation: _rotationAnimation,
                      colorAnimation: _colorAnimation,
                    ),
                  ),
                  ImageCarousel(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Chart section - Use the available safe area height
                          // if (safeAreaHeight > 700)
                          //   Container(
                          //     height: safeAreaHeight * 0.40,
                          //     width: screenWidth * 0.99,
                          //     // Adjust the height proportionally
                          //     padding: EdgeInsets.symmetric(
                          //         horizontal: isMobile ? 8 : 16),
                          //     child: CollectedVsExpectedChart(
                          //       yearlyPayments: yearlyPayments,
                          //       availableYears: availableYears,
                          //       expectedTotal: expectedTotal,
                          //     ),
                          //   ),

                          // Table Section with Flexible Widget for Overflow Fix
                          if (showTable)
                            isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color.fromARGB(255, 0, 122, 255),
                                    ),
                                  )
                                : Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 8 : 16),
                                    child: SizedBox(
                                      width: screenWidth * 0.99,
                                      // Ensure the table takes full width
                                      child: Scrollbar(
                                        thumbVisibility: true,
                                        controller:
                                            placesProvider.scrollController,
                                        child: SingleChildScrollView(
                                          controller:
                                              placesProvider.scrollController,
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minWidth: screenWidth,
                                            ),
                                            child: DataTable(
                                              columnSpacing:
                                                  isMobile ? 10.0 : 20.0,
                                              dataRowMinHeight:
                                                  isMobile ? 25 : 35,
                                              dataRowMaxHeight:
                                                  isMobile ? 30 : 40,
                                              dataRowColor: WidgetStateProperty
                                                  .resolveWith<Color?>(
                                                (Set<WidgetState> states) {
                                                  if (states.contains(
                                                      WidgetState.selected)) {
                                                    return const Color.fromARGB(
                                                        255, 0, 122, 255);
                                                  }
                                                  return Colors
                                                      .deepPurple.shade50;
                                                },
                                              ),
                                              headingRowColor:
                                                  WidgetStateProperty
                                                      .resolveWith<Color?>(
                                                (Set<WidgetState> states) =>
                                                    const Color.fromARGB(
                                                        255, 0, 122, 255),
                                              ),
                                              border: TableBorder.all(
                                                color: const Color.fromARGB(
                                                    255, 0, 122, 255),
                                                width: 1.0,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              columns:
                                                  placesProvider.buildColumns(),
                                              rows: buildRows(paginatedData),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                          // Pagination controls
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
                                      onPressed: dateTimeProvider.currentPage >
                                              1
                                          ? () => setState(() =>
                                              dateTimeProvider.currentPage--)
                                          : null,
                                      icon: Icon(
                                        Icons.arrow_back,
                                        color: dateTimeProvider.currentPage > 1
                                            ? Color.fromARGB(255, 0, 122, 255)
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
                                        color: Color.fromARGB(255, 0, 122, 255),
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
                                                  dateTimeProvider
                                                      .itemsPerPage <
                                              dateTimeProvider.totalItems
                                          ? () => setState(() =>
                                              dateTimeProvider.currentPage++)
                                          : null,
                                      icon: Icon(
                                        Icons.arrow_forward,
                                        color: dateTimeProvider.currentPage *
                                                    dateTimeProvider
                                                        .itemsPerPage <
                                                dateTimeProvider.totalItems
                                            ? Color.fromARGB(255, 0, 122, 255)
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool showTable = true;

  String? selectedReportType = 'ڕاپۆرت'; // Default value
  List<String> reportTypes = [
    'ڕاپۆرت',
    'ڕاپۆرتی کرێ دان',
    'شوێنە بەتاڵەکان',
    'ناونیشانی موڵکەکان'
  ];

  void showFilterDialog(BuildContext context, PaymentProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text(
                'جۆری ڕاپۆرت هەڵبژێرە',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(
                      255, 0, 122, 255), // Deep purple title color
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
                            color: Color.fromARGB(255, 0, 122, 255),
                          ), // Item color
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
                    iconEnabledColor:
                        Color.fromARGB(255, 0, 122, 255), // Icon color
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'لابردن',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 122, 255),
                      // Cancel button color
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
                            title: const Text(
                              'Error',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 122, 255),
                              ),
                            ),
                            content: const Text(
                              'Please select a report type.',
                              style: TextStyle(
                                color: Color.fromARGB(
                                    255, 0, 122, 255), // Error content color
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'دڵنیابوون',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 0, 122, 255)),
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
                      case 'ڕاپۆرت':
                        wow.pdfHelper().showPlaceReportDialog(
                            context, provider.places ?? []);
                        break;
                      case 'ڕاپۆرتی کرێ دان':
                        wow
                            .pdfHelper()
                            .generatePaymentHistory(pdf, provider, ttf);
                        break;
                      case 'شوێنە بەتاڵەکان':
                        wow.pdfHelper().generateEmptyAndOccupiedPlacesReport(
                            pdf, provider, ttf);
                        break;
                      case 'ناونیشانی موڵکەکان':
                        wow.pdfHelper().showPlaceSelectionDialog(
                            context, provider.places ?? []);
                        break;
                      default:
                        break;
                    }
                    print(selectedReportType);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 0, 122, 255),
                    // Button background color
                    foregroundColor: Colors.white,
                    // Button text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Button corners
                    ),
                  ),
                  child: Text('پیشاندانی ڕاپۆرت'),
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
