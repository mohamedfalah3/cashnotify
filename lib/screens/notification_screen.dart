import 'package:cashnotify/helper/helper_class.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:provider/provider.dart';

class UnpaidRemindersScreen extends StatefulWidget {
  const UnpaidRemindersScreen({super.key});

  @override
  _UnpaidRemindersScreenState createState() => _UnpaidRemindersScreenState();
}

class _UnpaidRemindersScreenState extends State<UnpaidRemindersScreen> {
  final int itemsPerPage = 6;
  int currentPage = 1;
  bool isLoading = false;
  List<Map<String, dynamic>> unpaidReminders = [];

  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredReminders = [];

  @override
  void initState() {
    super.initState();
    fetchUnpaidPlaces();
  }

  Future<void> fetchUnpaidPlaces() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final provider = Provider.of<PaymentProvider>(context, listen: false);
      final allUnpaidPlaces = await provider.getUnpaidPlaces();

      // Implement pagination
      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex =
          (startIndex + itemsPerPage).clamp(0, allUnpaidPlaces.length);
      final newReminders = allUnpaidPlaces.sublist(startIndex, endIndex);

      setState(() {
        unpaidReminders = newReminders;
        filteredReminders = unpaidReminders; // Initialize filtered list
      });
    } catch (e) {
      debugPrint('Error fetching unpaid reminders: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterReminders(String query) {
    setState(() {
      filteredReminders = unpaidReminders
          .where((reminder) =>
              reminder['name']?.toLowerCase().contains(query.toLowerCase()) ??
              false)
          .toList();
    });
  }

  void _goToNextPage() {
    setState(() {
      currentPage++;
    });
    fetchUnpaidPlaces();
  }

  void _goToPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      fetchUnpaidPlaces();
    }
  }

  String formatDateInterval(String date) {
    try {
      // Debug the raw date string
      debugPrint('Raw date string: $date');

      // Split the date into year, month, and day
      List<String> parts = date.split('-');

      if (parts.length == 3) {
        String year = parts[0];
        String month = parts[1].padLeft(2, '0'); // Ensure month has 2 digits
        String day = parts[2].padLeft(2, '0'); // Ensure day has 2 digits

        // Rebuild the date in the format yyyy-MM-dd
        String formattedDate = '$year-$month-$day';

        // Try parsing the formatted date
        DateTime? unpaidDate = DateTime.tryParse(formattedDate);

        if (unpaidDate == null) {
          return "Invalid date format"; // In case the parsing still fails
        }

        // Add 30 days to the unpaid date
        DateTime dueDate = unpaidDate.add(const Duration(days: 30));

        // Return formatted date as an interval
        String formattedUnpaid = DateFormat('yyyy-MM-dd').format(unpaidDate);
        String formattedDue = DateFormat('yyyy-MM-dd').format(dueDate);

        return "$formattedUnpaid → $formattedDue";
      } else {
        return "Invalid date format"; // If the date is not in the correct format
      }
    } catch (e) {
      debugPrint("Error parsing date: $e");
      return "Invalid date"; // Return fallback message in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('Unpaid Reminders - ${DateTime.now().year}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: const Color(0xFF005BBB), height: 4.0),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'گەڕان بە ناو',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF007AFF)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: _filterReminders,
              ),
            ),
          ),
          Expanded(
            child: unpaidReminders.isEmpty
                ? Center(
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            'هیچ نەدۆزرایەوە',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                  )
                : ListView.builder(
                    itemCount: filteredReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = filteredReminders[index];
                      final unpaidIntervals =
                          (reminder['unpaidIntervals'] as List<String>? ?? [])
                              .map(formatDateInterval)
                              .toList();

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF007AFF),
                            child: Text(
                              (reminder['name']?.isNotEmpty ?? false)
                                  ? (reminder['name'][0].toUpperCase())
                                  : 'U',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            reminder['name'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text(
                                'ماوە نەدراوەکان',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              ...unpaidIntervals.map(
                                (interval) => Container(
                                  margin:
                                      const EdgeInsets.only(top: 2, left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '🔴 $interval',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (unpaidReminders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: currentPage > 1 ? _goToPreviousPage : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('پێشتر',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                  Text(
                    'لاپەڕە $currentPage',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  ElevatedButton(
                    onPressed: unpaidReminders.length == itemsPerPage
                        ? _goToNextPage
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('دواتر',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
