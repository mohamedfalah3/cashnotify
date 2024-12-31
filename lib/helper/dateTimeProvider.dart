import 'package:cashnotify/helper/place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DateTimeProvider extends ChangeNotifier {
  int selectedYear = DateTime.now().year;
  int totalItems = 0;
  final int itemsPerPage = 10;

  int currentPage = 1;

  List<Map<String, dynamic>> getPaginatedData(
      List<Map<String, dynamic>> tableData) {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return tableData.sublist(
      startIndex,
      endIndex > tableData.length ? tableData.length : endIndex,
    );
  }

  List<int> availableYears = [];

  void initializeYears() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('places').get();
    final years =
        snapshot.docs.map((doc) => doc['year'] as int).toSet().toList()..sort();
    print('Available years: $years');

    availableYears = years;
    notifyListeners();
  }

  Future<void> duplicateDataForNewYear() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final currentYear = now.year;

    try {
      // Check if data for the current year already exists
      final existingSnapshot = await firestore
          .collection('places')
          .where('year', isEqualTo: currentYear)
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        print('Data for year $currentYear already exists.');
        return;
      }

      // Fetch all documents for the previous year
      final previousYear = currentYear - 1;
      final snapshot = await firestore
          .collection('places')
          .where('year', isEqualTo: previousYear)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No data found for year $previousYear to duplicate.');
        return;
      }

      // Start a Firestore batch
      final batch = firestore.batch();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Create a new Place instance with the current year and reset fields
        final newPlace = Place(
          id: firestore.collection('places').doc().id,
          // Generate a new ID
          name: data['name'] ?? 'Unknown',
          // Handle null values
          amount: data['amount'] ?? '0',
          comments: {
            'January': '',
            'February': '',
            'March': '',
            'April': '',
            'May': '',
            'June': '',
            'July': '',
            'August': '',
            'September': '',
            'October': '',
            'November': '',
            'December': '',
          },
          items: List<String>.from(data['items'] ?? []),
          payments: {
            'January': 'نەدراوە',
            'February': 'نەدراوە',
            'March': 'نەدراوە',
            'April': 'نەدراوە',
            'May': 'نەدراوە',
            'June': 'نەدراوە',
            'July': 'نەدراوە',
            'August': 'نەدراوە',
            'September': 'نەدراوە',
            'October': 'نەدراوە',
            'November': 'نەدراوە',
            'December': 'نەدراوە',
          },
          year: currentYear,
          itemsString: data['itemsString'] ?? '',
          place: data['place'] ?? 'Unknown',
        );

        // Add the new document to the batch
        final newDocRef = firestore.collection('places').doc(newPlace.id);
        batch.set(newDocRef, {
          'name': newPlace.name,
          'amount': newPlace.amount,
          'comments': newPlace.comments,
          'items': newPlace.items,
          'payments': newPlace.payments,
          'year': newPlace.year,
          'itemsString': newPlace.itemsString,
          'place': newPlace.place,
        });
      }

      // Commit the batch
      await batch.commit();
      print('Data duplicated successfully for year $currentYear.');
    } catch (e) {
      print('Error duplicating data: $e');
    }
  }

  bool isRed = false;
  DateTime? activationTime;

  void checkDate() {
    DateTime now = DateTime.now();

    // Check if it's the 9th day after 9 AM or any day after the 9th
    bool isValidDateTime = (now.day == 9 && now.hour >= 9) || now.day > 9;

    // If already activated, check if 9 hours have passed since activation
    if (activationTime != null) {
      Duration timeElapsed = now.difference(activationTime!);
      if (timeElapsed.inHours < 9) {
        isRed = true; // Still within the 9-hour window
        notifyListeners();
        return;
      } else {
        isRed = false; // 9-hour window expired
      }
    }

    // Allow activation only if the date/time conditions are met
    if (isValidDateTime) {
      isRed = true;
      activationTime = now; // Set the activation time
    } else {
      isRed = false;
    }

    notifyListeners();
  }
}
