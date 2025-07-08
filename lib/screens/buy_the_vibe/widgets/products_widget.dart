// lib/screens/buy_the_vibe/widgets/products_widget.dart

import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/screens/buy_the_vibe/widgets/product_widget.dart';
import 'package:flutter/material.dart';

// 1. Convert to ConsumerStatefulWidget
class ProductsWidget extends StatefulWidget {
  // 2. Accept products list and the shared PageController
  final List<Product> products;
  final PageController pageController;

  const ProductsWidget({
    super.key,
    required this.products,
    required this.pageController,
  });

  @override
  State<ProductsWidget> createState() => _ProductsWidgetState();
}

class _ProductsWidgetState extends State<ProductsWidget> {
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    // 3. Add a listener to the passed-in controller to update the page indicator text
    widget.pageController.addListener(() {
      if (widget.pageController.page?.round() != _pageIndex) {
        setState(() {
          _pageIndex = widget.pageController.page!.round();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            // 4. Use the controller from the parent widget
            controller: widget.pageController,
            itemCount: widget.products.length,
            itemBuilder: (context, index) {
              final product = widget.products[index];
              return ProductWidget(product: product);
            },
            // The listener in initState now handles updating the index
          ),
        ),
        // This page indicator text will now stay in sync
        Text(
          '${_pageIndex + 1}/${widget.products.length}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12)
      ],
    );
  }
}