import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/helper_class.dart';

class UnpaidRemindersScreen extends StatefulWidget {
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

  List<Map<String, dynamic>> calculateUnpaidMonths(
      List<Map<String, dynamic>> places) {
    final DateTime now = DateTime.now();
    final List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];

    List<Map<String, dynamic>> unpaidReminders = [];

    for (var place in places) {
      final payments = (place['payments'] as Map<String, dynamic>?) ?? {};
      final unpaidMonths = <String>[];

      for (int i = 0; i < now.month; i++) {
        String month = monthNames[i];
        if (!payments.containsKey(month) || payments[month] == null) {
          unpaidMonths.add(month);
        }
      }

      if (unpaidMonths.isNotEmpty) {
        unpaidReminders.add({
          'name': place['name'] ?? 'Unknown',
          'unpaidMonths': unpaidMonths,
        });
      }
    }

    return unpaidReminders;
  }

  Future<void> fetchPlaces() async {
    if (isLoading || !hasMoreData) return;

    setState(() {
      isLoading = true;
    });

    // Build the query with pagination
    Query query = FirebaseFirestore.instance
        .collection('places')
        .where('year', isEqualTo: DateTime.now().year)
        .limit(itemsPerPage);

    if (currentPage > 1 && lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      lastDocument = snapshot.docs.last; // Remember the last document for pagination

      List<Map<String, dynamic>> places = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return {
          'name': data['name'] ?? 'Unknown',
          'payments': data['payments'] ?? {},
        };
      }).toList();

      setState(() {
        // Clear the unpaid reminders list to prevent old data from being included
        if (currentPage > 1) {
          unpaidReminders.clear(); // Clear data on new page load
        }

        unpaidReminders.addAll(calculateUnpaidMonths(places));

        if (places.length < itemsPerPage) {
          hasMoreData = false; // No more data available
        }
      });
    } else {
      setState(() {
        hasMoreData = false; // No data fetched
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  // Method to handle the "Previous" button logic
  void goToPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        unpaidReminders.clear(); // Clear current list to load the previous page's data
        hasMoreData = true; // Reset the "has more data" flag
      });
      fetchPlaces(); // Fetch the previous page data
    }
  }

  // Method to handle the "Next" button logic
  void goToNextPage() {
    if (hasMoreData) {
      setState(() {
        currentPage++;
      });
      fetchPlaces(); // Fetch the next page data
    }
  }

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PaymentProvider>(context);
    int totalPages = ((unpaidReminders.length + (hasMoreData ? 1 : 0)) / itemsPerPage).ceil();

    return GestureDetector(
      onTap: () {
        placesProvider.overlayEntry?.remove();
        placesProvider.overlayEntry = null;
      },
      child: Scaffold(
        backgroundColor: Colors.deepPurple.shade50,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: Text(
            'Unpaid Reminders - ${DateTime.now().year}',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: unpaidReminders.length,
                itemBuilder: (context, index) {
                  final reminder = unpaidReminders[index];
                  return Card(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          (reminder['name'] ?? 'U').substring(0, 1).toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        reminder['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                      subtitle: Text(
                        'Unpaid Months: ${(reminder['unpaidMonths'] as List<dynamic>).join(', ')}',
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
                    onPressed: currentPage > 1 ? goToPreviousPage : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Previous',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    'Page $currentPage of $totalPages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: hasMoreData ? goToNextPage : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
