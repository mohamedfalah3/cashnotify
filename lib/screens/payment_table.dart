import 'package:cashnotify/helper/dateTimeProvider.dart';
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
    await placesProvider.fetchComments(year);

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

      dateTimeProvider.initializeYears();
      dateTimeProvider.duplicateDataForNewYear();

      fetchFilteredData(dateTimeProvider.selectedYear);

      dateTimeProvider.checkDate();
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
              // Access fields directly from the Place model instance
              final id = place.id;
              final name = place.name ?? 'Unknown';
              final placeName = place.place ?? 'Unknown Place';
              final payments =
                  place.payments ?? {}; // payments is a Map<String, dynamic>
              final amount = place.amount ?? '0'; // amount is a String

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
                'payments': payments,
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
        final id = row['docId'];
        final payments = row['payments'];

        if (!_isEditing.containsKey(id)) {
          _isEditing[id] = false;
        }

        if (!_controllers.containsKey(id)) {
          _controllers[id] = {
            'name': TextEditingController(text: row['name']),
            'amount': TextEditingController(text: row['amountString']),
            'items': TextEditingController(text: row['itemsString']),
            'place': TextEditingController(text: row['place']),
          };

          for (int i = 1; i <= 12; i++) {
            final month = placesProvider.monthName(i);
            _controllers[id]![month] = TextEditingController(
              text: payments[month]?.toString() ?? 'نەدراوە',
            );
          }
        }

        return DataRow(
          cells: [
            // Sequence Cell
            DataCell(Text(row['sequence'].toString())),

            // Tooltip for Name Field
            DataCell(
              _isEditing[id]!
                  ? TextField(controller: _controllers[id]!['name'])
                  : Text(row['name'] ?? 'No name'),
            ),

            // Tooltip for Place Field
            DataCell(
              SizedBox(
                  child: Text(
                row['place'] ?? 'No place',
              )),
            ),

            // Tooltip for Items/Code Field
            DataCell(
              _isEditing[id]!
                  ? TextField(controller: _controllers[id]!['items'])
                  : Text(row['itemsString'] ?? 'No code'),
            ),

            // Tooltip for Amount Field
            DataCell(
              _isEditing[id]!
                  ? TextField(controller: _controllers[id]!['amount'])
                  : Text(row['amountString'] ?? '0'),
            ),

            // Payments Fields (with tooltips and editing options)
            ...List.generate(12, (index) {
              final month = placesProvider.monthName(index + 1);

              return DataCell(
                GestureDetector(
                  onTap: () {
                    print(placesProvider.comment[id]?[month]);
                  },
                  onDoubleTap: () {
                    if (_isEditing[id] == false) {
                      showCommentDialog(
                          context, dateTimeProvider.selectedYear, month, id);
                    }
                  },
                  child: Tooltip(
                    message: (placesProvider.comment[id]?[month]?.isEmpty ??
                            true)
                        ? 'نۆ کۆمێنت'
                        : placesProvider.comment[id]?[month] ?? 'No comment',
                    child: Container(
                      padding: _isEditing[id] == true
                          ? const EdgeInsets.all(0)
                          : const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      height: 40,
                      decoration: BoxDecoration(
                        // Add logic to check if payment is "Not Paid" for new users and reset payment to "Not Paid" if empty
                        color: _controllers[id]![month]!.text.isEmpty ||
                                _controllers[id]![month]!.text == 'نەدراوە'
                            ? Colors.red[100] // Red background for "Not Paid"
                            : Colors.transparent,
                        // Transparent if not "Not Paid"
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _isEditing[id]!
                          ? TextField(
                              controller: _controllers[id]![month],
                            )
                          : Text(
                              _controllers[id]![month]!.text.isEmpty
                                  ? 'نەدراوە' // Show "Not Paid" if empty
                                  : _controllers[id]![month]!.text,
                            ),
                    ),
                  ),
                ),
              );
            }),

            // Action Buttons for Save/Edit and Delete
            DataCell(
              Row(
                children: [
                  // Save/Edit Button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (_isEditing[id] == true) {
                          final updatedData = {
                            'name': _controllers[id]!['name']!.text,
                            'amount': _controllers[id]!['amount']!.text,
                            'items': _controllers[id]!['items']!
                                .text
                                .split(RegExp(r'\s+'))
                                .map((item) => item.toUpperCase())
                                .toList(),
                            'place': _controllers[id]!['place']!.text,
                            'itemsString': _controllers[id]!['items']!
                                .text
                                .split(RegExp(r'\s+'))
                                .map((item) => item.toUpperCase())
                                .toList()
                                .toString(),
                            'payments': Map.fromEntries(
                              List.generate(12, (i) {
                                final month = placesProvider.monthName(i + 1);
                                final paymentText =
                                    _controllers[id]![month]!.text;

                                final paymentValue = paymentText.isEmpty
                                    ? 'نەدراوە'
                                    : paymentText;

                                return MapEntry(month, paymentValue);
                              }),
                            ),
                          };
                          placesProvider.updatePayment(
                            context,
                            id,
                            updatedData,
                            dateTimeProvider.selectedYear,
                          );
                          _isEditing[id] = false;
                        } else {
                          _isEditing[id] = true;

                          // Clear all TextFields
                          _controllers[id] ??= {};
                          _controllers[id]!['name'] =
                              TextEditingController(text: row['name'] ?? '');
                          _controllers[id]!['amount'] = TextEditingController(
                              text: row['amountString'] ?? '');
                          _controllers[id]!['items'] = TextEditingController(
                              text: row['itemsString'] ?? '');
                          _controllers[id]!['place'] =
                              TextEditingController(text: row['place'] ?? '');
                          for (int i = 0; i < 12; i++) {
                            final month = placesProvider.monthName(i + 1);
                            final paymentValue = row['payments'][month];
                            _controllers[id]![month] = TextEditingController(
                              text: paymentValue == 'نەدراوە' ||
                                      paymentValue == null
                                  ? ''
                                  : paymentValue.toString(),
                            );
                          }
                        }
                      });
                    },
                    icon: _isEditing[id] == true
                        ? const Icon(Icons.save)
                        : const Icon(Icons.edit),
                  ),
                  const SizedBox(width: 10),

                  // Delete Button (only visible when not editing)
                  if (_isEditing[id] == false)
                    IconButton(
                      onPressed: () {
                        placesProvider.deletePayment(
                            context, id, dateTimeProvider.selectedYear);
                      },
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                    ),
                ],
              ),
            ),
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
                placesProvider.exportToPDF(context);
              },
              icon: const Icon(Icons.picture_as_pdf),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: placesProvider.exportToCSVWeb,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
              ),
              icon: const Icon(Icons.download),
              label: const Text('گۆڕین بۆ ئێکسل'),
            ),
            if (dateTimeProvider.isRed)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Notificationicon(onPressed: () {
                      placesProvider.toggleDropdown(context);
                      dateTimeProvider.checkDate();
                    }),
                    Positioned(
                      top: -5, // Adjust to make it more prominent
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
                margin: EdgeInsets.only(right: 10),
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
                      placesProvider
                          .fetchComments(dateTimeProvider.selectedYear);
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
