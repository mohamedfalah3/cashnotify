import 'package:cashnotify/widgets/notificationIcon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/helper_class.dart';

class PaymentTable extends StatefulWidget {
  const PaymentTable({Key? key}) : super(key: key);

  @override
  State<PaymentTable> createState() => _PaymentTableState();
}

class _PaymentTableState extends State<PaymentTable>
    with SingleTickerProviderStateMixin {
  Map<String, bool> _isEditing = {};
  Map<String, Map<String, TextEditingController>> _controllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final placesProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      placesProvider.fetchPlaces();
      placesProvider.fetchComments();
      placesProvider.checkDate();
    });
  }

  Map<String, Map<String, String>> _comments =
      {}; // Example: {id: {month: comment}}

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PaymentProvider>(context);

    void _showCommentDialog(BuildContext context, String id, String month) {
      final TextEditingController commentController =
          TextEditingController(text: _comments[id]?[month]);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Add/Edit Comment'),
            content: TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter your comment here',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  String newComment = commentController.text;

                  setState(() {
                    _comments[id] ??= {};
                    _comments[id]![month] = newComment;
                  });

                  placesProvider.updateCommentInFirestore(
                      id, month, newComment);

                  Navigator.of(context).pop();
                  placesProvider.fetchComments();
                },
                child: Text('Save'),
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

    List<DataRow> buildRows(List<Map<String, dynamic>> tableData) {
      return tableData.map((row) {
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
                  : Text(row['name']),
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
                    print(placesProvider.comments[id]?[month]);
                  },
                  onDoubleTap: () {
                    _showCommentDialog(context, id, month);
                  },
                  child: Tooltip(
                    message:
                        placesProvider.comments[id]?[month] ?? 'No comment',
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isNotPaid ? Colors.red[100] : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _isEditing[id]!
                          ? TextField(
                              controller: _controllers[id]![month],
                              textAlign: TextAlign.center,
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
                              context, id, updatedData);
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
                        placesProvider.deletePayment(context, id);
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
          title: const Text('Your App Title'),
          actions: [
            IconButton(
                onPressed: () {
                  placesProvider.exportToPDF(context);
                },
                icon: Icon(Icons.picture_as_pdf)),
            SizedBox(
              width: 20,
            ),
            DropdownButton<String>(
              value: placesProvider.selectedPlaceName ?? 'All',
              dropdownColor: Colors.deepPurpleAccent,
              icon: const Icon(Icons.filter_list, color: Colors.black),
              underline: const SizedBox(),
              items: ['All', ...manualPlaceNames].map((placeName) {
                return DropdownMenuItem<String>(
                  value: placeName,
                  child: Text(placeName,
                      style: const TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: (value) {
                placesProvider.selectedPlaceName =
                    value == 'All' ? null : value;
                placesProvider.filterData(placesProvider.searchController.text,
                    placesProvider.selectedPlaceName);
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Flexible(
                    flex: 3,
                    child: TextField(
                      controller: placesProvider.searchController,
                      onChanged: (query) {
                        placesProvider.filterData(
                            query, placesProvider.selectedPlaceName);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: placesProvider.exportToCSVWeb,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 16.0),
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Export to Excel'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: placesProvider.filteredPlaces == null
                  ? const Center(child: CircularProgressIndicator())
                  : placesProvider.filteredPlaces!.isEmpty
                      ? const Center(child: Text('No places found.'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateColor.resolveWith(
                              (states) => Colors.deepPurpleAccent,
                            ),
                            columnSpacing: 20.0,
                            columns: placesProvider.buildColumns(),
                            rows: buildRows(tableData),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
