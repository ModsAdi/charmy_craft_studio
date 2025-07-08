// lib/screens/discover/discover_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/artwork.dart';
import 'package:charmy_craft_studio/screens/discover/widgets/artwork_card.dart';
import 'package:charmy_craft_studio/state/artwork_provider.dart';
import 'package:charmy_craft_studio/state/categories_provider.dart';
import 'package:entry/entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final artworksAsync = ref.watch(artworksProvider(_selectedCategory));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Charmi Crafts',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.displayLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Curated Galleries',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          // Horizontal Category List
          categoriesAsync.when(
            loading: () => const SizedBox(
              height: 110,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SizedBox(
              height: 110,
              child: Center(child: Text('Error: $err')),
            ),
            data: (categories) {
              return SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryCircle(
                      name: category.name,
                      imageUrl: category.imageUrl,
                      isSelected: _selectedCategory == category.name,
                      onTap: () => setState(() => _selectedCategory = category.name),
                    );
                  },
                ),
              );
            },
          ),
          // Artwork Grid
          Expanded(
            child: artworksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (artworks) {
                if (artworks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_search, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No artworks found in this category.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return MasonryGridView.count(
                  // ++ THIS IS THE FIX ++
                  // Added more bottom padding to account for the nav bar
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  itemCount: artworks.length,
                  itemBuilder: (context, index) {
                    final artwork = artworks[index];
                    return Entry.all(
                      delay: Duration(milliseconds: 100 * (index % 10)),
                      curve: Curves.easeOutCubic,
                      child: ArtworkCard(artwork: artwork),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCircle({
    required String name,
    required String imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.colorScheme.secondary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: theme.cardColor,
                backgroundImage: imageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(imageUrl)
                    : null,
                child: imageUrl.isEmpty
                    ? Icon(
                  (name == 'All') ? Icons.collections_bookmark_outlined : Icons.image_not_supported,
                  size: 24,
                  color: theme.colorScheme.secondary,
                )
                    : (isSelected
                    ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Icon(Icons.check, color: Colors.white),
                )
                    : null),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.secondary : theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}