// lib/screens/buy_the_vibe/widgets/product_image_widget.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:flutter/material.dart';

class ProductImageWidget extends StatelessWidget {
  final Product product;

  const ProductImageWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: size.height * 0.5,
      width: size.width * 0.8,
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 2, spreadRadius: 1),
          ],
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Stack(
          children: [
            _buildImage(),
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopText(),
                  // We can add other info here later if needed
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImage() => SizedBox.expand(
    child: ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: product.imageUrls.isNotEmpty
          ? CachedNetworkImage(
        imageUrl: product.imageUrls.first,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
        const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
        const Icon(Icons.error, color: Colors.red),
      )
          : Container(
        color: Colors.grey.shade300,
        child: const Center(child: Text('No Image')),
      ),
    ),
  );

  Widget _buildTopText() => Text(
    product.title,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  );
}