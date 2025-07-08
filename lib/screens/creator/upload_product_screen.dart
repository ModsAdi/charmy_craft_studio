// lib/screens/creator/upload_product_screen.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/state/upload_product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:intl/intl.dart';

class UploadProductScreen extends ConsumerStatefulWidget {
  final Product? productToEdit;

  const UploadProductScreen({super.key, this.productToEdit});

  @override
  ConsumerState<UploadProductScreen> createState() =>
      _UploadProductScreenState();
}

class _UploadProductScreenState extends ConsumerState<UploadProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  DateTime? _discountCountdown;
  bool _requiresAdvance = false;

  bool get _isEditMode => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final product = widget.productToEdit!;
      _titleController.text = product.title;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toStringAsFixed(0);
      _discountPriceController.text =
          product.discountedPrice?.toStringAsFixed(0) ?? '';
      _deliveryTimeController.text = product.deliveryTime;
      _discountCountdown = product.discountCountdown;
      _requiresAdvance = product.requiresAdvance;
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final discountedPrice = _discountPriceController.text.isNotEmpty
          ? double.tryParse(_discountPriceController.text)
          : null;
      int? discountPercentage;
      if (price > 0 && discountedPrice != null && discountedPrice > 0) {
        discountPercentage =
            (((price - discountedPrice) / price) * 100).round();
      }

      final productData = Product(
        id: _isEditMode ? widget.productToEdit!.id : '',
        title: _titleController.text,
        description: _descriptionController.text,
        imageUrls: _isEditMode ? widget.productToEdit!.imageUrls : [],
        price: price,
        discountedPrice: discountedPrice,
        discountPercentage: discountPercentage,
        discountCountdown: _discountCountdown,
        deliveryTime: _deliveryTimeController.text,
        requiresAdvance: _requiresAdvance,
      );

      if (_isEditMode) {
        ref
            .read(uploadProductProvider.notifier)
            .updateProduct(product: productData);
      } else {
        ref
            .read(uploadProductProvider.notifier)
            .uploadProduct(product: productData);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _deliveryTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProductProvider);
    final uploadNotifier = ref.read(uploadProductProvider.notifier);

    ref.listen<UploadProductState>(uploadProductProvider, (previous, next) {
      if (!next.isLoading &&
          next.errorMessage == null &&
          (previous?.isLoading ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEditMode
                  ? 'Product updated successfully!'
                  : 'Product uploaded successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${next.errorMessage}'),
              backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Product' : 'Add New Product',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (!_isEditMode)
                  _buildFilePicker(context, uploadState, uploadNotifier),
                if (_isEditMode && widget.productToEdit!.imageUrls.isNotEmpty)
                  _buildExistingImagesPreview(),
                const SizedBox(height: 16),
                _buildTextField(_titleController, 'Product Title'),
                const SizedBox(height: 16),
                _buildTextField(_descriptionController, 'Description',
                    maxLines: 4),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(_priceController, 'Price (₹)',
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(_discountPriceController,
                          'Discounted Price (₹, Optional)',
                          keyboardType: TextInputType.number,
                          isRequired: false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                    _deliveryTimeController, 'Delivery Time (e.g., 5-7 Days)'),
                const SizedBox(height: 16),
                _buildDateTimePicker(),
                SwitchListTile(
                  title: const Text('Requires Advance Payment?'),
                  value: _requiresAdvance,
                  onChanged: (value) =>
                      setState(() => _requiresAdvance = value),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: uploadState.isLoading ? null : _submitForm,
                  icon: Icon(
                      _isEditMode ? Icons.save_alt_outlined : Icons.upload),
                  label:
                  Text(_isEditMode ? 'Save Changes' : 'Upload Product'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ],
            ),
          ),
          if (uploadState.isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      uploadState.progress > 0 && !_isEditMode
                          ? 'Uploading images: ${(uploadState.progress * 100).toStringAsFixed(0)}%'
                          : _isEditMode
                          ? 'Saving changes...'
                          : 'Processing...',
                      style:
                      const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ++ MODIFIED: This widget now correctly themes the date picker ++
  Widget _buildDateTimePicker() {
    final theme = Theme.of(context);
    return ListTile(
      title: const Text('Discount Countdown (Optional)'),
      subtitle: Text(_discountCountdown == null
          ? 'Not set'
          : DateFormat.yMMMd().add_jm().format(_discountCountdown!)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _discountCountdown ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: theme.colorScheme.secondary, // Header background
                  onPrimary: Colors.white, // Header text
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor:
                    theme.colorScheme.secondary, // Button text color
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date == null) return;
        final time = await showTimePicker(
          context: context,
          initialTime:
          TimeOfDay.fromDateTime(_discountCountdown ?? DateTime.now()),
        );
        if (time == null) return;

        setState(() {
          _discountCountdown = DateTime(
              date.year, date.month, date.day, time.hour, time.minute);
        });
      },
    );
  }

  Widget _buildExistingImagesPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Images',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.productToEdit!.imageUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.productToEdit!.imageUrls[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Note: To change images, please delete and re-upload the product.',
          style:
          Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildFilePicker(BuildContext context, UploadProductState uploadState,
      UploadProductNotifier uploadNotifier) {
    return GestureDetector(
      onTap: uploadNotifier.pickImages,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(12),
          color: Theme.of(context).colorScheme.secondary,
          strokeWidth: 2,
          dashPattern: const [8, 4],
        ),
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: uploadState.imageFiles.isNotEmpty
              ? GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4),
            itemCount: uploadState.imageFiles.length,
            itemBuilder: (context, index) {
              return Image.file(uploadState.imageFiles[index],
                  fit: BoxFit.cover);
            },
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 8),
              const Text('Tap to select images'),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1,
        TextInputType? keyboardType,
        bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => (isRequired && (value == null || value.isEmpty))
          ? 'Please enter a value'
          : null,
    );
  }
}