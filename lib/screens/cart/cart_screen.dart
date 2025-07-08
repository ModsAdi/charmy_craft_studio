// lib/screens/cart/cart_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/address.dart';
import 'package:charmy_craft_studio/models/cart_item.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:charmy_craft_studio/state/cart_provider.dart';
import 'package:charmy_craft_studio/state/creator_profile_provider.dart';
import 'package:charmy_craft_studio/state/single_product_provider.dart';
import 'package:charmy_craft_studio/state/user_provider.dart';
import 'package:charmy_craft_studio/widgets/address_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
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
                  Icon(Icons.shopping_cart_outlined,
                      size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Your Cart is Empty',
                      style: GoogleFonts.lato(
                          fontSize: 22, fontWeight: FontWeight.bold)),
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
          : _WhatsAppCheckoutBar(cartTotal: cartTotal),
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
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    fullProductAsync.when(
                      data: (product) {
                        bool hasDiscount = product.discountedPrice != null &&
                            product.discountedPrice! < product.price;
                        return Row(
                          children: [
                            if (hasDiscount) ...[
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              '₹${item.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                  fontSize: 16),
                            ),
                            if (hasDiscount) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  '(${product.discountPercentage}% off)',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              )
                            ]
                          ],
                        );
                      },
                      loading: () => const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_, __) => Text('₹${item.price.toStringAsFixed(0)}'),
                    ),
                  ],
                ),
              ),
              if (userId != null) _QuantityControl(item: item, userId: userId),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityControl extends ConsumerWidget {
  const _QuantityControl({required this.item, required this.userId});
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
              ref
                  .read(firestoreServiceProvider)
                  .updateCartItemQuantity(userId, item.id, item.quantity - 1);
            },
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
          ),
          Text(item.quantity.toString(),
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
            icon: Icon(Icons.add, size: 16, color: theme.colorScheme.secondary),
            onPressed: () {
              ref
                  .read(firestoreServiceProvider)
                  .updateCartItemQuantity(userId, item.id, item.quantity + 1);
            },
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _WhatsAppCheckoutBar extends ConsumerWidget {
  final double cartTotal;
  const _WhatsAppCheckoutBar({required this.cartTotal});

  void _showAddressSelectorForCart(BuildContext context, WidgetRef ref) {
    final user = ref.read(userDataProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to continue.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddressSelectionSheet(
          onAddressSelected: (selectedAddress) {
            _generateWhatsAppMessageForCart(context, ref, selectedAddress);
          },
        );
      },
    );
  }

  void _generateWhatsAppMessageForCart(
      BuildContext context, WidgetRef ref, Address selectedAddress) async {
    final creatorProfile = ref.read(creatorProfileProvider).value;
    final user = ref.read(userDataProvider).value!;
    final cartItems = ref.read(cartProvider).value ?? [];
    final productsInCart = ref.read(cartProductsProvider).value ?? [];
    final whatsappNumber = creatorProfile?.whatsappNumber ?? '+910000000000';

    String addressString = "📍 *Shipping Address:*\n";
    addressString += "${selectedAddress.fullName}\n";
    addressString +=
    "${selectedAddress.flatHouseNo}, ${selectedAddress.areaStreet}\n";
    if (selectedAddress.landmark.isNotEmpty) {
      addressString += "Landmark: ${selectedAddress.landmark}\n";
    }
    addressString +=
    "${selectedAddress.townCity}, ${selectedAddress.state} ${selectedAddress.pincode}\n";
    addressString += "Phone: ${selectedAddress.mobileNumber}";

    String productsListString = "";
    for (int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];
      final product = productsInCart.firstWhere((p) => p.id == item.id,
          orElse: () => Product(
              id: item.id,
              title: item.title,
              description: '',
              imageUrls: [],
              price: item.price,
              deliveryTime: 'N/A',
              requiresAdvance: false));

      final hasDiscount = product.discountedPrice != null &&
          product.discountedPrice! < product.price;

      productsListString += "📦 *Product ${i + 1}*\n";
      productsListString += "• *ID:* ${product.id}\n"; // Use full ID
      productsListString += "• *Name:* ${product.title}\n";
      productsListString += "• *Description:* ${product.description}\n";
      productsListString +=
      "• *Original Price:* ₹${product.price.toStringAsFixed(0)}\n";
      if (hasDiscount) {
        productsListString +=
        "• *Discounted Price:* ₹${product.discountedPrice!.toStringAsFixed(0)} (${product.discountPercentage}% OFF)\n";
      }
      productsListString += "• *Quantity:* ${item.quantity}\n";
      productsListString += "• *Delivery Time:* ${product.deliveryTime}\n";
      productsListString +=
      "• *Total:* ${item.quantity} x ₹${item.price.toStringAsFixed(0)} = ₹${(item.quantity * item.price).toStringAsFixed(0)}\n";
      productsListString += "🔗 *Product Link:* [Product Link]\n\n";
    }

    final message = """
Hello, I’d like to place an order. 🛍️

👤 *Name:* ${user.displayName ?? 'N/A'}
📧 *Email:* ${user.email}

──────────────────────
🧾 *Order Summary*
──────────────────────
🛒 *Total Products:* ${cartItems.length}

$productsListString
💰 *Total Order Value: ₹${cartTotal.toStringAsFixed(0)}*

${addressString}
""";

    final url = Uri.parse(
        "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
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
              Text('Grand Total',
                  style: TextStyle(color: Colors.grey.shade600)),
              Text(
                '₹${cartTotal.toStringAsFixed(2)}',
                style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
            label: const Text('Buy Now'),
            style: ElevatedButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showAddressSelectorForCart(context, ref),
          ),
        ],
      ),
    );
  }
}