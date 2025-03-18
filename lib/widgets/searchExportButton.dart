import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/helper_class.dart';

class SearchExport extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final PaymentProvider paymentProvider;
  final void Function(BuildContext, PaymentProvider) showFilter;
  final AnimationController controller;
  final Animation<double> scaleAnimation;
  final Animation<double> rotationAnimation;
  final Animation<Color?> colorAnimation;

  const SearchExport({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.showFilter,
    required this.paymentProvider,
    required this.controller,
    required this.scaleAnimation,
    required this.rotationAnimation,
    required this.colorAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final placesProvider = Provider.of<PaymentProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'گەران...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
          const SizedBox(width: 10), // Space between search and filter button

          // Filter Button
          ElevatedButton.icon(
            onPressed: () => showFilter(context, paymentProvider),
            icon: const Icon(Icons.filter_list, color: Colors.white),
            label: const Text(
              "ڕاپۆرت",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 0, 122, 255),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              elevation: 3, // Adds a slight shadow
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  placesProvider.toggleDropdown(context);
                  // getCollectedVsExpected(places);
                  // final result = getCollectedVsExpected(places);
                  // print("Collected: ${result['collected']}");
                  // print(expectedTotal);
                },
                icon: const Icon(Icons.notifications_outlined),
                color: Color.fromARGB(255, 0, 122, 255),
                iconSize: 28,
                splashRadius: 24,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: scaleAnimation.value,
                      child: Transform.rotate(
                        angle: rotationAnimation.value,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorAnimation.value,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
