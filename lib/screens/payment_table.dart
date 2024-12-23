import 'package:cashnotify/widgets/searchExportButton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/helper_class.dart';
import '../widgets/notificationIcon.dart';

class PaymentTable extends StatefulWidget {
  const PaymentTable({Key? key}) : super(key: key);

  @override
  State<PaymentTable> createState() => _PaymentTableState();
}

class _PaymentTableState extends State<PaymentTable>
    with SingleTickerProviderStateMixin {
  Map<String, bool> _isEditing = {};
  Map<String, Map<String, TextEditingController>> _controllers = {};
  final ScrollController _scrollController = ScrollController();

  int selectedYear = DateTime.now().year;
  List<int> availableYears = [];
  Stream<QuerySnapshot>? filteredStream;

  // Pagination

  int currentPage = 1;
  final int itemsPerPage = 14;
  int totalItems = 0;

  List<Map<String, dynamic>> getPaginatedData(
      List<Map<String, dynamic>> tableData) {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return tableData.sublist(
      startIndex,
      endIndex > tableData.length ? tableData.length : endIndex,
    );
  }

  void initializeYears() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('places').get();
    final years =
        snapshot.docs.map((doc) => doc['year'] as int).toSet().toList()..sort();
    print('Available years: $years');
    setState(() {
      availableYears = years;
    });
  }

  void fetchFilteredData(int year) {
    // Fetch the filtered data for the selected year
    final placesProvider = Provider.of<PaymentProvider>(context, listen: false);
    placesProvider.fetchComments(year); // Fetch comments for the selected year
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final placesProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      placesProvider.fetchPlaces();
      initializeYears();
      placesProvider.duplicateDataForNewYear();
      fetchFilteredData(selectedYear);
      placesProvider.checkDate();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, Map<String, String>> _comments =
      {}; // Example: {id: {month: comment}}

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PaymentProvider>(context);

    Map<int, Map<String, String>> _comments = {};

    void _showCommentDialog(
        BuildContext context, int year, String month, String id) {
      // Fetch the initial comment for the given year and month
      final TextEditingController commentController = TextEditingController(
        text: _comments[year]?[month] ?? '',
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Add/Edit Comment for $month, $year'),
            content: TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your comment here',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  String newComment = commentController.text;

                  setState(() {
                    // Ensure the structure exists for the year and month
                    _comments[year] ??= {};
                    _comments[year]![month] = newComment;
                  });

                  // Update the Firestore document
                  FirebaseFirestore.instance
                      .collection('places')
                      .doc(id)
                      .update({
                    'comments.$month': newComment,
                  });

                  Navigator.of(context).pop();
                  placesProvider.fetchComments(selectedYear);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }

    final Map<String, int> prefixCounters = {};
    final List<Map<String, dynamic>> tableData = (placesProvider.filteredPlaces
            ?.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final id = doc.id;
          final name = data['name'] ?? 'Unknown';
          final place = data['place'] ?? 'Unknown Place';
          final payments = Map<String, dynamic>.from(data['payments'] ?? {});
          final amount = data['amount'];

          final List<dynamic>? items = data['items'];
          final itemsString =
              items != null && items.isNotEmpty ? items.join(', ') : 'No code';

          final prefix =
              itemsString.split('/').first.substring(0, 3).toUpperCase();

          if (!prefixCounters.containsKey(prefix)) {
            prefixCounters[prefix] = 1;
          } else {
            prefixCounters[prefix] = prefixCounters[prefix]! + 1;
          }

          return {
            'docId': id,
            'sequence': prefixCounters[prefix],
            'name': name,
            'place': place,
            'itemsString': itemsString,
            'amountString': amount?.toString() ?? 'No amount',
            'payments': payments,
          };
        }).toList()) ??
        [];
    // final provider = Provider.of<PaymentProvider>(context);
    final List<String> manualPlaceNames = [
      'Ganjan City',
      'Ainkawa',
    ];

    totalItems = tableData.length;
    final paginatedData = getPaginatedData(tableData);

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
              text: payments[month]?.toString() ?? 'Not Paid',
            );
          }
        }

        return DataRow(
          cells: [
            DataCell(Text(row['sequence'].toString())),
            DataCell(
              _isEditing[id]!
                  ? TextField(controller: _controllers[id]!['name'])
                  : Text(row['name'] ?? 'No name'),
            ),
            DataCell(
              _isEditing[id]!
                  ? TextField(controller: _controllers[id]!['place'])
                  : Text(row['place']),
            ),
            DataCell(
              _isEditing[id]!
                  ? TextField(controller: _controllers[id]!['items'])
                  : Text(row['itemsString']),
            ),
            DataCell(
              _isEditing[id]!
                  ? TextField(controller: _controllers[id]!['amount'])
                  : Text(row['amountString']),
            ),
            ...List.generate(12, (index) {
              final month = placesProvider.monthName(index + 1);
              final paymentAmount = payments[month];
              final isNotPaid = paymentAmount == null || paymentAmount == 0;

              return DataCell(
                GestureDetector(
                  onTap: () {
                    print(placesProvider.comment[id]?[month]);
                  },
                  onDoubleTap: () {
                    if (_isEditing[id] == false) {
                      _showCommentDialog(context, selectedYear, month, id);
                    }
                  },
                  child: Tooltip(
                    message: placesProvider.comment[id]?[month] ?? 'نۆ کۆمێنت',
                    child: Container(
                      padding: _isEditing[id] == true
                          ? EdgeInsets.all(0)
                          : const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isNotPaid ? Colors.red[100] : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _isEditing[id]!
                          ? TextField(
                              controller: _controllers[id]![month],
                            )
                          : Text(
                              isNotPaid ? 'Not Paid' : paymentAmount.toString(),
                            ),
                    ),
                  ),
                ),
              );
            }),
            DataCell(
              Row(
                children: [
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

                                final paymentValue =
                                    paymentText == 'Not Paid' ||
                                            paymentText == '0'
                                        ? null
                                        : paymentText;

                                return MapEntry(month, paymentValue);
                              }),
                            ),
                          };
                          placesProvider.updatePayment(
                              context, id, updatedData, selectedYear);
                          _isEditing[id] = false;
                        } else {
                          _isEditing[id] = true;
                        }
                      });
                    },
                    icon: _isEditing[id] == true
                        ? const Icon(Icons.save)
                        : const Icon(Icons.edit),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  if (_isEditing[id] == false)
                    IconButton(
                      onPressed: () {
                        placesProvider.deletePayment(context, id, selectedYear);
                      },
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                    )
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
          title: const Text('App Title'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<int>(
                value: selectedYear,
                items: availableYears.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (newYear) {
                  if (newYear != null) {
                    setState(() {
                      selectedYear = newYear;
                      fetchFilteredData(selectedYear);
                      placesProvider.fetchPlaces(year: selectedYear);
                    });
                  }
                },
              ),
            ),
            IconButton(
              onPressed: () {
                placesProvider.exportToPDF(context);
              },
              icon: const Icon(Icons.picture_as_pdf),
            ),
            const SizedBox(width: 20),
            DropdownButton<String>(
              value: placesProvider.selectedPlaceName ?? 'All',
              dropdownColor: Colors.deepPurpleAccent,
              icon: const Icon(Icons.filter_list, color: Colors.black),
              underline: const SizedBox(),
              items: ['All', ...manualPlaceNames].map((placeName) {
                return DropdownMenuItem<String>(
                  value: placeName,
                  child: Text(
                    placeName,
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                placesProvider.selectedPlaceName =
                    value == 'All' ? null : value;
                placesProvider.filterData(
                  placesProvider.searchController.text,
                  placesProvider.selectedPlaceName,
                );
              },
            ),
            placesProvider.isRed
                ? Stack(
                    clipBehavior: Clip.none,
                    // Allows the red dot to overflow the bounds of the icon
                    children: [
                      Notificationicon(onPressed: () {
                        placesProvider.toggleDropdown(context);
                        setState(() {
                          placesProvider.isRed = false;
                        });
                      }),
                      Positioned(
                        top: -2, // Adjust to position the dot properly
                        right: -2,
                        child: Container(
                          width: 8, // Size of the red dot
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  )
                : Notificationicon(onPressed: () {
                    placesProvider.toggleDropdown(context);
                  }),
          ],
        ),
        body: Column(
          children: [
            SearchExport(
              searchController: placesProvider.searchController,
              onSearch: (query) {
                placesProvider.filterData(
                    query, placesProvider.selectedPlaceName);
              },
            ),
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: Row(
            //     children: [
            //       Flexible(
            //         flex: 3,
            //         child: TextField(
            //           controller: placesProvider.searchController,
            //           onChanged: (query) {
            //             placesProvider.filterData(
            //               query,
            //               placesProvider.selectedPlaceName,
            //             );
            //           },
            //           decoration: InputDecoration(
            //             hintText: 'Search...',
            //             prefixIcon:
            //                 const Icon(Icons.search, color: Colors.grey),
            //             filled: true,
            //             fillColor: Colors.grey[200],
            //             contentPadding:
            //                 const EdgeInsets.symmetric(vertical: 12.0),
            //             border: OutlineInputBorder(
            //               borderRadius: BorderRadius.circular(30.0),
            //               borderSide: BorderSide.none,
            //             ),
            //           ),
            //           style: const TextStyle(fontSize: 16.0),
            //         ),
            //       ),
            //       const SizedBox(width: 16),
            //       ElevatedButton.icon(
            //         onPressed: placesProvider.exportToCSVWeb,
            //         style: ElevatedButton.styleFrom(
            //           padding: const EdgeInsets.symmetric(
            //             horizontal: 20.0,
            //             vertical: 16.0,
            //           ),
            //         ),
            //         icon: const Icon(Icons.download),
            //         label: const Text('Export to Excel'),
            //       ),
            //     ],
            //   ),
            // ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                // Always show the scrollbar
                controller: placesProvider.scrollController,
                // Attach the ScrollController
                child: SingleChildScrollView(
                  controller: placesProvider.scrollController,
                  // Attach the same ScrollController
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateColor.resolveWith(
                      (states) => Colors.deepPurpleAccent,
                    ),
                    columnSpacing: 20.0,
                    columns: placesProvider.buildColumns(),
                    rows: buildRows(paginatedData),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.deepPurple.shade50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: currentPage > 1
                            ? () => setState(() => currentPage--)
                            : null,
                        icon: Icon(
                          Icons.arrow_back,
                          color:
                              currentPage > 1 ? Colors.deepPurple : Colors.grey,
                        ),
                        splashRadius: 24,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$currentPage / ${((totalItems - 1) ~/ itemsPerPage) + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: currentPage * itemsPerPage < totalItems
                            ? () => setState(() => currentPage++)
                            : null,
                        icon: Icon(
                          Icons.arrow_forward,
                          color: currentPage * itemsPerPage < totalItems
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
    );
  }
}
