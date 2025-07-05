import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/cart_item.dart';
import 'package:charmy_craft_studio/models/user.dart';
import 'package:charmy_craft_studio/state/cart_provider.dart';
import 'package:charmy_craft_studio/state/creator_profile_provider.dart';
import 'package:charmy_craft_studio/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  void _launchWhatsApp(List<CartItem> cartItems, double totalValue, UserModel? user, WidgetRef ref) async {
    final creatorProfile = ref.read(creatorProfileProvider).value;
    final whatsappNumber = creatorProfile?.whatsappNumber ?? '+910000000000';

    final name = user?.displayName ?? 'Customer';
    final email = user?.email ?? 'N/A';

    String productsSummary = "";
    for(int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];
      productsSummary += """
🆔 Product ${i+1} ID: ${item.productId}
📦 Product: ${item.title}
💰 Price: ₹${item.price.toStringAsFixed(0)} x ${item.quantity}
🔗 View Product: [We will add a link later]
---
""";
    }

    final message = """
Hello, I'd like to place an order.

👤 Name: $name
📧 Email: $email

Product count: ${cartItems.length}
---
$productsSummary
🧾 Total Order Value: ₹${totalValue.toStringAsFixed(0)}

Address - 
""";

    final url = Uri.parse("https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final user = ref.watch(userDataProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Your cart is empty', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[400])),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return _buildCartItemCard(context, item, cartNotifier);
              },
            ),
          ),
          _buildCheckoutSection(context, cartNotifier.totalValue, () => _launchWhatsApp(cartItems, cartNotifier.totalValue, user, ref)),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item, CartNotifier notifier) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('₹${item.price.toStringAsFixed(0)}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
            ),
            _buildQuantitySelector(item, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(CartItem item, CartNotifier notifier) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: () => notifier.updateQuantity(item.productId, item.quantity - 1),
        ),
        Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: () => notifier.updateQuantity(item.productId, item.quantity + 1),
        ),
      ],
    );
  }

  Widget _buildCheckoutSection(BuildContext context, double totalValue, VoidCallback onCheckout) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: -5),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text(
                '₹${totalValue.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: onCheckout,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }
}