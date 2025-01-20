import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/helper_class.dart';

class SearchExport extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final PaymentProvider paymentProvider;
  final void Function(BuildContext, PaymentProvider) showFilter;

  const SearchExport({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.showFilter,
    required this.paymentProvider,
  });

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PaymentProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        // Make sure there’s no extra space
        children: [
          // Search Field
          Expanded(
            // width: MediaQuery.of(context).size.width * 0.35, // Adjust width for search box
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
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => showFilter(context, paymentProvider),
          ),
        ],
      ),
    );
  }
}
