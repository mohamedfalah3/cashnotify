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
}
