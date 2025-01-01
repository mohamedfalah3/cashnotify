import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UnpaidRemindersScreen extends StatefulWidget {
  const UnpaidRemindersScreen({super.key});

  @override
  _UnpaidRemindersScreenState createState() => _UnpaidRemindersScreenState();
}

class _UnpaidRemindersScreenState extends State<UnpaidRemindersScreen> {
  final int itemsPerPage = 10;
  int currentPage = 1;
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool hasMoreData = true;
  List<Map<String, dynamic>> unpaidReminders = [];

  @override
  void initState() {
    super.initState();
    fetchUnpaidReminders();
  }

  Future<void> fetchUnpaidReminders() async {
    if (isLoading || !hasMoreData) return;

    setState(() {
      isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('places')
          .where('year', isEqualTo: DateTime.now().year)
          .limit(itemsPerPage);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;

        List<Map<String, dynamic>> newReminders = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final payments = data['payments'] as Map<String, dynamic>? ?? {};
          print(payments.length);

          List<String> unpaidMonths = _calculateUnpaidMonths(payments);

          return {
            'name': data['name'] ?? 'Unknown',
            'unpaidMonths': unpaidMonths,
          };
        }).toList();

        setState(() {
          unpaidReminders.addAll(newReminders);
          if (newReminders.length < itemsPerPage) {
            hasMoreData = false;
          }
          print('$unpaidReminders reminders');
        });
      } else {
        setState(() {
          hasMoreData = false;
        });
      }
    } catch (e) {
      print('Error fetching unpaid reminders: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<String> _calculateUnpaidMonths(Map<String, dynamic> payments) {
    final List<String> monthNames = [
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
    ];

    final now = DateTime.now();
    List<String> unpaidMonths = [];

    // Log payments map for debugging
    print('Payments received: $payments');

    for (int i = 0; i < now.month; i++) {
      final month = monthNames[i];

      // Check if the month exists in payments and is unpaid
      if (!payments.containsKey(month) ||
          payments[month] == null ||
          payments[month] == 'Not Paid' ||
          (payments[month] is num && payments[month] == 0) ||
          (payments[month] is String &&
              double.tryParse(payments[month]) == 0)) {
        unpaidMonths.add(month);
      }
    }

    print('Unpaid months: $unpaidMonths');
    return unpaidMonths;
  }

  void _goToNextPage() {
    if (hasMoreData) {
      setState(() {
        currentPage++;
      });
      fetchUnpaidReminders();
    }
  }

  void _goToPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        unpaidReminders.clear();
        lastDocument = null;
        hasMoreData = true;
      });
      fetchUnpaidReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unpaid Reminders - ${DateTime.now().year}'),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0), // Line height
          child: Container(
            color: Colors.deepPurple, // Line color
            height: 4.0, // Line height
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: unpaidReminders.isEmpty
                ? Center(
                    child: Text(
                      'No unpaid reminders found.',
                      style: TextStyle(color: Colors.deepPurple.shade700),
                    ),
                  )
                : ListView.builder(
                    itemCount: unpaidReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = unpaidReminders[index];

                      // Skip the record if the name is null or empty
                      if (reminder['name'] == null ||
                              reminder['name']?.isEmpty ??
                          true) {
                        return const SizedBox
                            .shrink(); // Return an empty widget to not display the record
                      }

                      print('Building item for: $reminder');

                      // Get the unpaid months list
                      List<String> unpaidMonths =
                          reminder['unpaidMonths'] as List<String>;

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              (reminder['name']?.isNotEmpty ?? false)
                                  ? (reminder['name']?[0] ?? 'U').toUpperCase()
                                  : 'U', // If name is null or empty, use 'U'
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            reminder['name'] ?? 'Unknown',
                            // Fallback to 'Unknown' if name is null
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          subtitle: unpaidMonths.isEmpty
                              ? const Text(
                                  'All payments are made',
                                  style: TextStyle(color: Colors.green),
                                )
                              : Text(
                                  'Unpaid Months: ${unpaidMonths.join(', ')}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 1 ? _goToPreviousPage : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple),
                  child: const Text('Previous'),
                ),
                Text(
                  'Page $currentPage',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: hasMoreData ? _goToNextPage : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple),
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
