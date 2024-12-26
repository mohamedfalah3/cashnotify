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

  Stream<QuerySnapshot>? filteredStream;

  void fetchFilteredData(int year) {
    // Fetch the filtered data for the selected year
    final placesProvider = Provider.of<PaymentProvider>(context, listen: false);
    placesProvider.fetchComments(year);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<PaymentProvider>(context, listen: false).fetchPlaces());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final placesProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      placesProvider.initializeYears();
      placesProvider.duplicateDataForNewYear();
      fetchFilteredData(placesProvider.selectedYear);
      placesProvider.checkDate();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
            backgroundColor: Colors.white,
            title: Text(
              'Add/Edit Comment for $month, $year',
              style: const TextStyle(color: Colors.deepPurple),
            ),
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
                    _comments[year] ??= {};
                    _comments[year]![month] = newComment;
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
          final amount = data['amount'] ?? '0';

          final List<dynamic>? items = data['items'];
          final itemsString =
              items != null && items.isNotEmpty ? items.join(', ') : 'No code';

          // Get prefix: Allow either 2 or 3 letters as a prefix
          String prefix = itemsString.split('/').first;

          // Make sure we handle both 2-letter and 3-letter prefixes correctly
          if (prefix.length >= 3) {
            prefix = prefix.substring(0, 3).toUpperCase();
          } else if (prefix.length >= 2) {
            prefix = prefix.substring(0, 2).toUpperCase();
          } else {
            prefix = prefix.toUpperCase();
          }

          // Update prefix counter
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
            'amountString': amount?.toString() ?? '0',
            'payments': payments,
          };
        }).toList()) ??
        [];

    final List<String> manualPlaceNames = [
      'Ganjan City',
      'Ainkawa',
    ];

    placesProvider.totalItems = tableData.length;
    final paginatedData = placesProvider.getPaginatedData(tableData);

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
              _isEditing[id]!
                  ? TextField(controller: _controllers[id]!['place'])
                  : SizedBox(child: Text(row['place'] ?? 'No place')),
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
              final paymentAmount = payments[month];
              final isNotPaid = paymentAmount == null || paymentAmount == 0;

              return DataCell(
                GestureDetector(
                  onTap: () {
                    print(placesProvider.comment[id]?[month]);
                  },
                  onDoubleTap: () {
                    if (_isEditing[id] == false) {
                      _showCommentDialog(
                          context, placesProvider.selectedYear, month, id);
                    }
                  },
                  child: Tooltip(
                    message: (placesProvider.comment[id]?[month]?.isEmpty ??
                            true)
                        ? 'نۆ کۆمێنت'
                        : placesProvider.comment[id]?[month] ?? 'No comment',
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
                            context,
                            id,
                            updatedData,
                            placesProvider.selectedYear,
                          );
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
                  const SizedBox(width: 10),

                  // Delete Button (only visible when not editing)
                  if (_isEditing[id] == false)
                    IconButton(
                      onPressed: () {
                        placesProvider.deletePayment(
                            context, id, placesProvider.selectedYear);
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
              label: const Text('Export to Excel'),
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
            Container(
              width: double.infinity, // Full screen width
              padding: const EdgeInsets.all(16.0),
              color: Colors.deepPurple.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount: \$${placesProvider.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monthly Totals:',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: placesProvider.monthlyTotals.entries.map((entry) {
                      return Chip(
                        label: Text(
                            '${entry.key}: \$${entry.value.toStringAsFixed(2)}'),
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
              availableYears: placesProvider.availableYears,
              selectedYear: placesProvider.selectedYear,
              onChanged: (newYear) {
                if (newYear != null) {
                  setState(() {
                    placesProvider.selectedYear = newYear;
                    fetchFilteredData(placesProvider.selectedYear);
                    placesProvider.fetchPlaces(
                        year: placesProvider.selectedYear);
                    placesProvider.fetchComments(placesProvider.selectedYear);
                    print(placesProvider.selectedYear);
                  });
                }
              },
              manualPlaces: manualPlaceNames,
            ),
            //here comes the code
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
                        onPressed: placesProvider.currentPage > 1
                            ? () => setState(() => placesProvider.currentPage--)
                            : null,
                        icon: Icon(
                          Icons.arrow_back,
                          color: placesProvider.currentPage > 1
                              ? Colors.deepPurple
                              : Colors.grey,
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
                          placesProvider.currentPage.toString() +
                              ' / ' +
                              (((placesProvider.totalItems - 1) ~/
                                          placesProvider.itemsPerPage) +
                                      1)
                                  .toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: placesProvider.currentPage *
                                    placesProvider.itemsPerPage <
                                placesProvider.totalItems
                            ? () => setState(() => placesProvider.currentPage++)
                            : null,
                        icon: Icon(
                          Icons.arrow_forward,
                          color: placesProvider.currentPage *
                                      placesProvider.itemsPerPage <
                                  placesProvider.totalItems
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
