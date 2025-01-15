import 'package:cashnotify/helper/dateTimeProvider.dart';
import 'package:cashnotify/screens/placeDetails.dart';
import 'package:cashnotify/widgets/searchExportButton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/helper_class.dart';
import '../widgets/notificationIcon.dart';

class PaymentTable extends StatefulWidget {
  const PaymentTable({super.key});

  @override
  State<PaymentTable> createState() => _PaymentTableState();
}

class _PaymentTableState extends State<PaymentTable>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> _isEditing = {};
  final Map<String, Map<String, TextEditingController>> _controllers = {};

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

      // dateTimeProvider.initializeYears();
      // dateTimeProvider.duplicateDataForNewYear();

      fetchFilteredData(dateTimeProvider.selectedYear);

      // dateTimeProvider.checkDate();
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

    Map<int, Map<String, String>> comments = {};

    void showCommentDialog(
        BuildContext context, int year, String month, String id) {
      // Fetch the initial comment for the given year and month
      final TextEditingController commentController = TextEditingController(
        text: comments[year]?[month] ?? '',
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Add/Edit Comment for $month, $year',
              style: const TextStyle(color: Colors.deepPurple),
            ),
            content: TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'کۆمینت بنووسە',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('لابردن'),
              ),
              ElevatedButton(
                onPressed: () {
                  String newComment = commentController.text;

                  setState(() {
                    comments[year] ??= {};
                    comments[year]![month] = newComment;
                  });

                  FirebaseFirestore.instance
                      .collection('places')
                      .doc(id)
                      .update({
                    'comments.$month': newComment,
                  });

                  Navigator.of(context).pop();
                  placesProvider.fetchComments(year);
                },
                child: const Text('تۆمارکردن'),
              ),
            ],
          );
        },
      );
    }

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

    final Map keyMapping = {
      'January': '1',
      'February': '2',
      'March': '3',
      'April': '4',
      'May': '5',
      'June': '6',
      'July': '7',
      'August': '8',
      'September': '9',
      'October': '10',
      'November': '11',
      'December': '12',
    };

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
            IconButton(
              onPressed: () {
                // placesProvider.exportToPDF(context);
              },
              icon: const Icon(Icons.picture_as_pdf),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
              ),
              icon: const Icon(Icons.download),
              label: const Text('گۆڕین بۆ ئێکسل'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Notificationicon(onPressed: () {
                    placesProvider.toggleDropdown(context);
                    // dateTimeProvider.checkDate();
                  }),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          // Apply scale animation
                          child: Transform.rotate(
                            angle: _rotationAnimation.value,
                            // Apply rotation animation
                            child: Container(
                              width: 10, // Adjust size for visibility
                              height: 10,
                              decoration: BoxDecoration(
                                color: _colorAnimation.value,
                                // Apply color animation
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
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
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
                          'Total Amount: \$${placesProvider.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Every: \$${placesProvider.totalMoneyCollected.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'کۆکراوەی مانگانە:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          placesProvider.monthlyTotals.entries.map((entry) {
                        String newKey = keyMapping[entry.key] ?? entry.key;
                        return Chip(
                          label: Text(
                            '$newKey: \$${entry.value.toStringAsFixed(2)}',
                          ),
                          backgroundColor: Colors.deepPurple.shade50,
                        );
                      }).toList(),
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
                availableYears: dateTimeProvider.availableYears,
                selectedYear: dateTimeProvider.selectedYear,
                onChanged: (newYear) {
                  if (newYear != null &&
                      dateTimeProvider.selectedYear != newYear) {
                    setState(() {
                      dateTimeProvider.selectedYear = newYear;
                      fetchFilteredData(dateTimeProvider.selectedYear);
                      placesProvider.fetchPlaces(
                          year: dateTimeProvider.selectedYear);
                      // placesProvider
                      //     .fetchComments(dateTimeProvider.selectedYear);
                    });
                  }
                },
                manualPlaces: manualPlaceNames,
              ),
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
                              headingRowColor: MaterialStateColor.resolveWith(
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
}
