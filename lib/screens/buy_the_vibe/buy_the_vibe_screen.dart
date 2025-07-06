import 'package:charmy_craft_studio/screens/buy_the_vibe/widgets/products_widget.dart';
import 'package:charmy_craft_studio/screens/cart/cart_screen.dart';
import 'package:charmy_craft_studio/state/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BuyTheVibeScreen extends ConsumerWidget {
  const BuyTheVibeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: _buildAppBar(context, ref),
      body: const ProductsWidget(),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    // ++ THIS IS THE ONLY CHANGE IN THIS FILE ++
    // The new provider returns an AsyncValue, so we handle its states.
    final cartItemsCount = ref.watch(cartProvider).when(
      data: (items) => items.length,
      loading: () => 0,
      error: (err, stack) => 0,
    );
    // ++ END OF CHANGE ++

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: const Text('BUY THE VIBE'),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, size: 28),
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
                    color: Colors.red,
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
        icon: const Icon(Icons.search_outlined),
        onPressed: () {},
      ),
    );
  }
}