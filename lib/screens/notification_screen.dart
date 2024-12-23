import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/helper_class.dart';

class UnpaidRemindersScreen extends StatefulWidget {
  @override
  _UnpaidRemindersScreenState createState() => _UnpaidRemindersScreenState();
}

class _UnpaidRemindersScreenState extends State<UnpaidRemindersScreen> {
  late Future<List<Map<String, dynamic>>> unpaidRemindersFuture;

  List<Map<String, dynamic>> calculateUnpaidMonths(
      List<Map<String, dynamic>> places) {
    final DateTime now = DateTime.now();
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

    List<Map<String, dynamic>> unpaidReminders = [];

    for (var place in places) {
      final payments = place['payments'] as Map<String, dynamic>;
      final unpaidMonths = <String>[];

      for (int i = 0; i < now.month; i++) {
        String month = monthNames[i];
        if (!payments.containsKey(month) || payments[month] == null) {
          unpaidMonths.add(month);
        }
      }

      if (unpaidMonths.isNotEmpty) {
        unpaidReminders.add({
          'name': place['name'],
          'unpaidMonths': unpaidMonths,
        });
      }
    }

    return unpaidReminders;
  }

  Future<List<Map<String, dynamic>>> fetchPlaces() async {
    final placesCollection = FirebaseFirestore.instance
        .collection('places')
        .where('year', isEqualTo: DateTime.now().year);
    final snapshot = await placesCollection.get();

    List<Map<String, dynamic>> places = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      places.add({
        'name': data['name'],
        'payments': data['payments'] ?? {},
      });
    }

    return places;
  }

  @override
  void initState() {
    super.initState();
    unpaidRemindersFuture = _fetchUnpaidReminders();
  }

  Future<List<Map<String, dynamic>>> _fetchUnpaidReminders() async {
    final places = await fetchPlaces();
    return calculateUnpaidMonths(places);
  }

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PaymentProvider>(context);

    return GestureDetector(
      onTap: () {
        placesProvider.overlayEntry?.remove();
        placesProvider.overlayEntry = null;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Unpaid Reminders for ' + DateTime.now().year.toString()),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: unpaidRemindersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading reminders'));
            } else if (snapshot.hasData && snapshot.data!.isEmpty) {
              return const Center(child: Text('No unpaid reminders'));
            } else {
              final unpaidReminders = snapshot.data!;
              return ListView.builder(
                itemCount: unpaidReminders.length,
                itemBuilder: (context, index) {
                  final reminder = unpaidReminders[index];
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(reminder['name']),
                      subtitle: Text(
                        'Unpaid Months: ${reminder['unpaidMonths'].join(', ')}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
