// lib/screens/buy_the_vibe/widgets/stars_widget.dart

import 'package:flutter/material.dart';

class StarsWidget extends StatelessWidget {
  final int stars;

  const StarsWidget({super.key, required this.stars});

  @override
  Widget build(BuildContext context) {
    final allStars = List.generate(stars, (index) => index);

    return Row(
      children: allStars
          .map((star) => Container(
        margin: const EdgeInsets.only(right: 4),
        child:
        Icon(Icons.star_rate, size: 18, color: Colors.orangeAccent),
      ))
          .toList(),
    );
  }
}