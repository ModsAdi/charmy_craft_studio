// lib/screens/buy_the_vibe/buy_the_vibe_screen.dart

import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/screens/buy_the_vibe/widgets/products_widget.dart';
import 'package:charmy_craft_studio/screens/cart/cart_screen.dart';
import 'package:charmy_craft_studio/state/cart_provider.dart';
import 'package:charmy_craft_studio/state/products_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BuyTheVibeScreen extends ConsumerStatefulWidget {
  const BuyTheVibeScreen({super.key});

  @override
  ConsumerState<BuyTheVibeScreen> createState() => _BuyTheVibeScreenState();
}

class _BuyTheVibeScreenState extends ConsumerState<BuyTheVibeScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    // Add a listener to rebuild the screen on scroll, which updates the background
    _pageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (products) {
        if (products.isEmpty) {
          return Scaffold(
              appBar: _buildAppBar(context, ref),
              body: const Center(child: Text('No products available right now.')));
        }

        return Stack(
          children: [
            // ++ NEW: Dynamic, Cross-fading Background ++
            _buildDynamicBackground(products),

            // BLUR & OVERLAY
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ),

            // FOREGROUND
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: _buildAppBar(context, ref),
              body: ProductsWidget(
                products: products,
                pageController: _pageController,
              ),
            ),
          ],
        );
      },
    );
  }

  // ++ NEW: This widget builds the dynamic background ++
  Widget _buildDynamicBackground(List<Product> products) {
    // Ensure the controller is ready before trying to access its page property
    if (!_pageController.hasClients) {
      return const SizedBox.shrink();
    }

    final double currentPage = _pageController.page!;
    final int pageIndex = currentPage.floor();
    final int nextPage = (pageIndex + 1).clamp(0, products.length - 1);
    final double pageProgress = currentPage - pageIndex;

    return Stack(
      children: [
        // Current Page Image
        if (products[pageIndex].imageUrls.isNotEmpty)
          Opacity(
            opacity: 1 - pageProgress,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(products[pageIndex].imageUrls.first),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

        // Next Page Image
        if (products[nextPage].imageUrls.isNotEmpty)
          Opacity(
            opacity: pageProgress,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(products[nextPage].imageUrls.first),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    final cartItemsCount = ref.watch(cartProvider).when(
      data: (items) => items.fold(0, (sum, item) => sum + item.quantity),
      loading: () => 0,
      error: (err, stack) => 0,
    );

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: const Text('BUY THE VIBE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, size: 28, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen()));
              },
            ),
            if (cartItemsCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    cartItemsCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
      leading: IconButton(
        icon: const Icon(Icons.search_outlined, color: Colors.white),
        onPressed: () {},
      ),
    );
  }
}