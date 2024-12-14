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
  late AnimationController _controller;
  late Animation<double> _animation;

  Map<String, bool> _isEditing = {}; // Track editing state for each row
  Map<String, Map<String, TextEditingController>> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Fetch data after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final placesProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      placesProvider.fetchPlaces();
      placesProvider.checkDate();
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // Continuous bounce effect

    _animation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  String monthName(int month) {
    return const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PaymentProvider>(context);

    final Map<String, int> prefixCounters = {};
    final List<Map<String, dynamic>> tableData = (placesProvider.filteredPlaces
            ?.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final id = doc.id;
          final name = data['name'] ?? 'Unknown Place';
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
            'itemsString': itemsString,
            'amountString': amount?.toString() ?? 'No amount',
            'payments': payments,
          };
        }).toList()) ??
        [];

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
            placesProvider.isRed
                ? Stack(
                    clipBehavior: Clip.none,
                    // Allows the red dot to overflow the bounds of the icon
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          size: 32,
                        ),
                        color: Colors.grey,
                        onPressed: () async {
                          final unpaidPlaces =
                              await placesProvider.getUnpaidPlaces();
                          placesProvider.toggleDropdown(context);
                          setState(() {
                            placesProvider.isRed = false;
                          });
                        },
                      ),
                      Positioned(
                        top: -2, // Adjust to position the dot properly
                        right: -2,
                        child: Container(
                          width: 8, // Size of the red dot
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.notifications,
                      size: 32,
                    ),
                    color: Colors.grey,
                    onPressed: () async {
                      final unpaidPlaces =
                          await placesProvider.getUnpaidPlaces();
                      placesProvider.toggleDropdown(context);
                    },
                  ),
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
                      onChanged: placesProvider.filterSearch,
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
                            headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Colors.deepPurpleAccent,
                            ),
                            columnSpacing: 20.0,
                            columns: [
                              const DataColumn(
                                label: Text(
                                  'Seq',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const DataColumn(
                                label: Text(
                                  'Place Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const DataColumn(
                                label: Text(
                                  'Area Code',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const DataColumn(
                                label: Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ...List.generate(
                                12,
                                (index) => DataColumn(
                                  label: Text(
                                    monthName(index + 1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const DataColumn(
                                label: Text(
                                  'Actions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            rows: tableData.map((row) {
                              final id = row['docId'];
                              final payments = row['payments'];

                              // Initialize controllers if not done
                              if (!_controllers.containsKey(id)) {
                                _controllers[id] = {
                                  'name':
                                      TextEditingController(text: row['name']),
                                  'amount': TextEditingController(
                                      text: row['amountString']),
                                  'items': TextEditingController(
                                      text: row['itemsString']),
                                };
                                for (int i = 1; i <= 12; i++) {
                                  final month = monthName(i);
                                  _controllers[id]![month] =
                                      TextEditingController(
                                    text: payments[month]?.toString() ??
                                        'Not Paid',
                                  );
                                }
                              }

                              return DataRow(
                                cells: [
                                  DataCell(Text(row['sequence'].toString())),
                                  DataCell(
                                    _isEditing[id] == true
                                        ? TextField(
                                            controller:
                                                _controllers[id]!['name'],
                                          )
                                        : Text(row['name']),
                                  ),
                                  DataCell(
                                    _isEditing[id] == true
                                        ? TextField(
                                            controller:
                                                _controllers[id]!['items'],
                                          )
                                        : Text(row['itemsString']),
                                  ),
                                  DataCell(
                                    _isEditing[id] == true
                                        ? TextField(
                                            controller:
                                                _controllers[id]!['amount'],
                                          )
                                        : Text(row['amountString']),
                                  ),
                                  ...List.generate(12, (index) {
                                    final month = monthName(index + 1);
                                    return DataCell(
                                      _isEditing[id] == true
                                          ? TextField(
                                              controller:
                                                  _controllers[id]![month],
                                            )
                                          : Text(
                                              payments[month]?.toString() ??
                                                  'Not Paid',
                                            ),
                                    );
                                  }),
                                  DataCell(
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          if (_isEditing[id] == true) {
                                            final updatedData = {
                                              'name': _controllers[id]!['name']!
                                                  .text,
                                              'amount':
                                                  _controllers[id]!['amount']!
                                                      .text,
                                              'items':
                                                  _controllers[id]!['items']!
                                                      .text
                                                      .split(RegExp(r'\s+'))
                                                      .map((item) =>
                                                          item.toUpperCase())
                                                      .toList(),
                                              'itemsString':
                                                  _controllers[id]!['items']!
                                                      .text
                                                      .split(RegExp(r'\s+'))
                                                      .map((item) =>
                                                          item.toUpperCase())
                                                      .toList()
                                                      .toString(),
                                              'payments': Map.fromEntries(
                                                List.generate(
                                                  12,
                                                  (i) => MapEntry(
                                                    monthName(i + 1),
                                                    _controllers[id]![
                                                            monthName(i + 1)]!
                                                        .text,
                                                  ),
                                                ),
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
                                      child: Text(_isEditing[id] == true
                                          ? 'Save'
                                          : 'Edit'),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
