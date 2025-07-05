import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/models/product_review.dart';
import 'package:charmy_craft_studio/models/user.dart';
import 'package:charmy_craft_studio/screens/details/full_image_screen.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:charmy_craft_studio/state/cart_provider.dart';
import 'package:charmy_craft_studio/state/creator_profile_provider.dart';
import 'package:charmy_craft_studio/state/product_review_provider.dart';
import 'package:charmy_craft_studio/state/reviews_list_provider.dart';
import 'package:charmy_craft_studio/state/single_product_provider.dart';
import 'package:charmy_craft_studio/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _reviewController = TextEditingController();
  double _currentRating = 0;
  bool _isFirstLoad = true;

  void _launchWhatsApp(Product product, UserModel? user) async {
    final creatorProfile = ref.read(creatorProfileProvider).value;
    final whatsappNumber = creatorProfile?.whatsappNumber ?? '+910000000000';

    final name = user?.displayName ?? 'Customer';
    final email = user?.email ?? 'N/A';
    final price = product.discountedPrice ?? product.price;
    final discountInfo = product.discountPercentage != null
        ? "🔻 Discounted Price: ₹${product.discountedPrice!.toStringAsFixed(0)} (${product.discountPercentage}% OFF)"
        : "";

    final message = """
Hello, I'd like to place an order.

👤 Name: $name
📧 Email: $email

Product count: 1
🆔 Product ID: ${product.id}
📦 Product: ${product.title}
💬 Description: ${product.description}
💰 Price: ₹${product.price.toStringAsFixed(0)}
$discountInfo
📆 Delivery Time: ${product.deliveryTime}

🔗 View Product: [We will add a link later]

🧾 Total Order Value: ₹${price.toStringAsFixed(0)}

Address - 
""";

    final url = Uri.parse("https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _submitReview(Product product, UserModel? user) {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to write a review.')));
      return;
    }
    if (_currentRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a star rating before submitting.')));
      return;
    }
    ref.read(firestoreServiceProvider).setReview(
      product.id,
      user.uid,
      user.displayName ?? 'Anonymous User',
      user.photoUrl ?? '',
      _currentRating,
      _reviewController.text.trim(),
    );
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your review!')));
  }

  void _deleteReview(String productId, String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to permanently delete this review?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(firestoreServiceProvider).deleteReview(productId, reviewId);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(singleProductProvider(widget.productId));

    return Scaffold(
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (product) {
          final user = ref.watch(userDataProvider).value;
          final userReviewAsync = ref.watch(productReviewProvider(product.id));
          final reviewsListAsync = ref.watch(reviewsListProvider(product.id));

          final existingReview = userReviewAsync.value;
          if (_isFirstLoad && mounted) {
            _currentRating = existingReview?.rating ?? 0.0;
            if (existingReview?.text != null) {
              _reviewController.text = existingReview!.text!;
            }
            _isFirstLoad = false;
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, product),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(product),
                      const SizedBox(height: 16),
                      _buildPrice(context, product),
                      const SizedBox(height: 24),
                      _buildActionButtons(context, product, user),
                      const Divider(height: 48),
                      _buildSectionTitle('Description'),
                      const SizedBox(height: 8),
                      Text(product.description, style: GoogleFonts.lato(fontSize: 16, height: 1.5)),
                      const Divider(height: 48),
                      _buildSectionTitle('Ratings & Reviews'),
                      const SizedBox(height: 12),
                      _buildRatingSection(product, userReviewAsync),
                      const SizedBox(height: 24),
                      _buildReviewInput(product, user),
                      const SizedBox(height: 24),
                      _buildReviewsList(reviewsListAsync, user),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, Product product) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.5,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.grey.shade200,
      flexibleSpace: FlexibleSpaceBar(
        background: GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FullImageScreen(
                imageUrls: product.imageUrls,
                initialIndex: _pageController.page?.round() ?? 0,
              ),
            ));
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: product.imageUrls.length,
            itemBuilder: (context, index) {
              return Hero(
                tag: product.imageUrls[index],
                child: CachedNetworkImage(
                  imageUrl: product.imageUrls[index],
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => const Icon(Icons.error),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          style: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Product ID: ${product.id}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPrice(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final hasDiscount = product.discountedPrice != null && product.discountedPrice! < product.price;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '₹${(product.discountedPrice ?? product.price).toStringAsFixed(0)}',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: hasDiscount ? theme.colorScheme.secondary : Colors.black87,
          ),
        ),
        if (hasDiscount)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.grey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        if (hasDiscount && product.discountPercentage != null)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              '${product.discountPercentage}% OFF',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Product product, UserModel? user) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).addItem(product);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to cart!')),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
              elevation: 0,
            ),
            child: const Text('Add to Cart'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
            label: const Text('Buy Now'),
            onPressed: () => _launchWhatsApp(product, user),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(Product product, AsyncValue<Review?> userReviewAsync) {
    return Row(
      children: [
        RatingBar.builder(
          initialRating: userReviewAsync.value?.rating ?? 0.0,
          minRating: 1,
          direction: Axis.horizontal,
          itemCount: 5,
          itemSize: 28.0,
          itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (rating) {
            setState(() {
              _currentRating = rating;
            });
          },
        ),
        const SizedBox(width: 12),
        if (product.ratingCount > 0)
          Text(
            '${product.averageRating.toStringAsFixed(1)} out of 5',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          )
        else
          Text(
            'No ratings yet',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
      ],
    );
  }

  Widget _buildReviewInput(Product product, UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _reviewController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share your experience...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => _submitReview(product, user),
            child: const Text('Submit Review'),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsList(AsyncValue<List<ProductReview>> reviewsListAsync, UserModel? currentUser) {
    return reviewsListAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Text('Could not load reviews.'),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text('Be the first to review this product!'),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final review = reviews[index];
            final bool canDelete = currentUser != null && (currentUser.uid == review.id || currentUser.role == 'creator');

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: review.userPhotoUrl.isNotEmpty ? NetworkImage(review.userPhotoUrl) : null,
                    child: review.userPhotoUrl.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: review.rating,
                              itemCount: 5,
                              itemSize: 16.0,
                              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat.yMMMd().format(review.timestamp.toDate()),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (review.text.isNotEmpty) Text(review.text),
                      ],
                    ),
                  ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => _deleteReview(widget.productId, review.id),
                      tooltip: 'Delete Review',
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reviewController.dispose();
    super.dispose();
  }
}