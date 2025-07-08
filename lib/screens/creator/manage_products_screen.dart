// lib/screens/creator/manage_products_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/screens/creator/upload_product_screen.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:charmy_craft_studio/state/creator_products_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageProductsScreen extends ConsumerStatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  ConsumerState<ManageProductsScreen> createState() =>
      _ManageProductsScreenState();
}

class _ManageProductsScreenState extends ConsumerState<ManageProductsScreen> {
  String _searchQuery = '';

  void _confirmAction({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor:
                title.toLowerCase().contains('delete') ? Colors.red : null),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(creatorProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Products',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (products) {
                final filteredProducts = products.where((prod) {
                  final matchesQuery = _searchQuery.isEmpty ||
                      prod.title
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                  return matchesQuery;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(context, product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final firestoreService = ref.read(firestoreServiceProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrls.isNotEmpty
                        ? product.imageUrls.first
                        : '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.image_not_supported),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Price: ₹${product.price.toStringAsFixed(0)}'),
                      if (product.isArchived)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Chip(
                            label: const Text('Archived'),
                            labelStyle: const TextStyle(
                                fontSize: 10, color: Colors.white),
                            backgroundColor: Colors.blueGrey,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Tooltip(
                  message: 'Edit',
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    // ++ FIX: Pass the product to the upload screen for editing ++
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                UploadProductScreen(productToEdit: product))),
                  ),
                ),
                Tooltip(
                  message: product.isArchived ? 'Unarchive' : 'Archive',
                  child: IconButton(
                    icon: Icon(
                        product.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                        color: Colors.blueAccent),
                    onPressed: () => _confirmAction(
                      context: context,
                      title: product.isArchived
                          ? 'Unarchive Product?'
                          : 'Archive Product?',
                      content: product.isArchived
                          ? 'This will make the product public again.'
                          : 'This will hide the product from the public.',
                      onConfirm: () => firestoreService
                          .setProductArchivedStatus(
                          product.id, !product.isArchived),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Remove',
                  child: IconButton(
                    icon: const Icon(Icons.delete_forever_outlined,
                        color: Colors.red),
                    onPressed: () => _confirmAction(
                      context: context,
                      title: 'Delete this product?',
                      content:
                      'This action is permanent and cannot be undone.',
                      onConfirm: () =>
                          firestoreService.deleteProduct(product.id),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}