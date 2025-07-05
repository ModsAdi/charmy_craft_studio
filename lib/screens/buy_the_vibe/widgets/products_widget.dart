// lib/screens/buy_the_vibe/widgets/products_widget.dart

import 'package:charmy_craft_studio/screens/buy_the_vibe/widgets/product_widget.dart';
import 'package:charmy_craft_studio/state/products_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductsWidget extends ConsumerStatefulWidget {
  const ProductsWidget({super.key});

  @override
  ConsumerState<ProductsWidget> createState() => _ProductsWidgetState();
}

class _ProductsWidgetState extends ConsumerState<ProductsWidget> {
  final pageController = PageController(viewportFraction: 0.8);
  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Text('No products available yet.',
                style: TextStyle(color: Colors.white70, fontSize: 18)),
          );
        }
        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductWidget(product: product);
                },
                onPageChanged: (index) => setState(() => pageIndex = index),
              ),
            ),
            Text(
              '${pageIndex + 1}/${products.length}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12)
          ],
        );
      },
    );
  }
}