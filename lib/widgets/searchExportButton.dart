import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helper/helper_class.dart';

class SearchExport extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final List<int> availableYears;
  final int selectedYear;
  final ValueChanged<int?> onChanged;
  final List manualPlaces;

  const SearchExport({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.availableYears,
    required this.selectedYear,
    required this.onChanged,
    required this.manualPlaces,
  });

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PaymentProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView( // Enable horizontal scrolling
        scrollDirection: Axis.horizontal, // Horizontal scrolling
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Make sure there’s no extra space
          children: [
            // Search Field
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35, // Adjust width for search box
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
            const SizedBox(width: 16), // Add spacing between widgets

            SizedBox(
              width: MediaQuery.of(context).size.width * 0.3, // Adjust width for year dropdown
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<int>(
                  value: selectedYear,
                  decoration: InputDecoration(
                    labelText: 'Select Year',
                    labelStyle: const TextStyle(color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.deepPurple.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.deepPurple.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Add more padding for clarity
                  ),
                  items: availableYears.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),

            // Dropdown for Places
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.25, // Adjust width for places dropdown
              child: DropdownButton<String>(
                value: placesProvider.selectedPlaceName ?? 'All',
                dropdownColor: Colors.deepPurpleAccent,
                icon: const Icon(Icons.filter_list, color: Colors.black),
                underline: const SizedBox(),
                items: ['All', ...manualPlaces].map((placeName) {
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
            ),
            const SizedBox(width: 16), // Add spacing between widgets

          ],
        ),
      ),
    );
  }
}
