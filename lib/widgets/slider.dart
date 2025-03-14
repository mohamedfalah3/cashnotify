import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class ImageCarousel extends StatelessWidget {
  final List<String> imagePaths = [
    'assets/images/image1.jpg',
    'assets/images/image2.jpg',
    'assets/images/image3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      // Added padding
      child: Center(
        child: CarouselSlider(
          options: CarouselOptions(
            height: screenHeight * 0.3,
            // Adjusted height
            aspectRatio: 16 / 9,
            viewportFraction: screenWidth < 600 ? 1.0 : 0.85,
            // Full width on small screens
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            // Increased delay before changing
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            // Smooth transition
            enlargeCenterPage: true,
            enableInfiniteScroll: true,
            scrollPhysics: BouncingScrollPhysics(), // Smoother scrolling effect
          ),
          items: imagePaths.map((imagePath) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // Slightly rounded corners
              child: Image.asset(
                imagePath,
                width: screenWidth * 0.85, // Adjusted width
                fit: BoxFit.cover,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
