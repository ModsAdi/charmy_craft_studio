import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/screens/buy_the_vibe/widgets/expanded_product_content_widget.dart';
import 'package:charmy_craft_studio/screens/buy_the_vibe/widgets/product_image_widget.dart';
import 'package:charmy_craft_studio/screens/details/product_details_screen.dart';
import 'package:flutter/material.dart';

class ProductWidget extends StatefulWidget {
  final Product product;

  const ProductWidget({super.key, required this.product});

  @override
  State<ProductWidget> createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> {
  bool isExpanded = false;

  // Handles both the first and second tap actions.
  void _handleTap() {
    // If the card is already open, navigate to the details page.
    if (isExpanded) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(productId: widget.product.id),
      ));
    } else {
      // If the card is closed, expand it.
      setState(() {
        isExpanded = true;
      });
    }
  }

  // Handles closing the card when dragged downwards.
  void _handleVerticalDragEnd(DragEndDetails details) {
    // Check if the card is expanded and if the user swiped downwards with enough speed.
    if (isExpanded && details.primaryVelocity != null && details.primaryVelocity! > 50) {
      setState(() {
        isExpanded = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // The GestureDetector now wraps the entire widget. This is the main change.
    // It captures all tap and drag gestures on the card area.
    return GestureDetector(
      onTap: _handleTap,
      onVerticalDragEnd: _handleVerticalDragEnd,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Your existing white content card that appears behind the image.
            // No changes are needed here.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              bottom: isExpanded ? (size.height * 0.1) : (size.height * 0.2),
              width: isExpanded ? size.width * 0.78 : size.width * 0.7,
              height: isExpanded ? size.height * 0.6 : size.height * 0.5,
              child: ExpandedProductContentWidget(product: widget.product),
            ),
            // Your existing main product image card.
            // I've removed the old GestureDetector from here.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              bottom: isExpanded ? (size.height * 0.25) : (size.height * 0.2),
              child: ProductImageWidget(product: widget.product),
            ),
          ],
        ),
      ),
    );
  }
}