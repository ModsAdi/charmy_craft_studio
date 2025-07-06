import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/cart_item.dart';
import 'package:charmy_craft_studio/models/product.dart'; // <-- ADD THIS IMPORT
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:charmy_craft_studio/state/cart_provider.dart';
import 'package:charmy_craft_studio/state/single_product_provider.dart'; // <-- ADD THIS IMPORT
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (cartItems) {
          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Your Cart is Empty', style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8).copyWith(bottom: 100),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return _CartItemCard(item: item);
            },
          );
        },
      ),
      bottomSheet: cartAsync.valueOrNull?.isEmpty ?? true
          ? null
          : _CheckoutBar(cartTotal: cartTotal),
    );
  }
}

class _CartItemCard extends ConsumerWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(authStateChangesProvider).value?.uid;
    final fullProductAsync = ref.watch(singleProductProvider(item.id));

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (userId != null) {
          ref.read(firestoreServiceProvider).removeFromCart(userId, item.id);
        }
      },
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    fullProductAsync.when(
                      data: (product) {
                        bool hasDiscount = product.discountedPrice != null && product.discountedPrice! < product.price;
                        return Row(
                          children: [
                            if(hasDiscount)...[
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              '₹${item.price.toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, fontSize: 16),
                            ),
                            if(hasDiscount)...[
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  '(${product.discountPercentage}% off)',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              )
                            ]
                          ],
                        );
                      },
                      loading: () => const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_,__) => Text('₹${item.price.toStringAsFixed(0)}'),
                    ),
                  ],
                ),
              ),
              _QuantityControl(item: item, userId: userId!),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityControl extends ConsumerWidget {
  const _QuantityControl({ required this.item, required this.userId });
  final CartItem item;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () {
              ref.read(firestoreServiceProvider).updateCartItemQuantity(userId, item.id, item.quantity - 1);
            },
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
          ),
          Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
            icon: Icon(Icons.add, size: 16, color: theme.colorScheme.secondary),
            onPressed: () {
              ref.read(firestoreServiceProvider).updateCartItemQuantity(userId, item.id, item.quantity + 1);
            },
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final double cartTotal;
  const _CheckoutBar({required this.cartTotal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Grand Total', style: TextStyle(color: Colors.grey.shade600)),
              Text(
                '₹${cartTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Navigate to final checkout or order summary screen
            },
            child: const Text('Checkout', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}