// lib/state/upload_product_provider.dart

import 'dart:io';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:charmy_craft_studio/services/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class UploadProductState {
  final List<File> imageFiles;
  final bool isLoading;
  final String? errorMessage;
  final double progress;

  const UploadProductState({
    this.imageFiles = const [],
    this.isLoading = false,
    this.errorMessage,
    this.progress = 0.0,
  });

  UploadProductState copyWith({
    List<File>? imageFiles,
    bool? isLoading,
    String? errorMessage,
    double? progress,
  }) {
    return UploadProductState(
      imageFiles: imageFiles ?? this.imageFiles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }
}

class UploadProductNotifier extends StateNotifier<UploadProductState> {
  final Ref _ref;
  UploadProductNotifier(this._ref) : super(const UploadProductState());

  Future<void> pickImages() async {
    reset();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFiles = result.paths.map((path) => File(path!)).toList();
      state = state.copyWith(imageFiles: pickedFiles);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> uploadProduct({
    required Product product,
  }) async {
    if (state.imageFiles.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select at least one image.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, progress: 0.0);

    try {
      final storageService = _ref.read(storageServiceProvider);
      final firestoreService = _ref.read(firestoreServiceProvider);

      List<String> imageUrls = [];
      for (int i = 0; i < state.imageFiles.length; i++) {
        final file = state.imageFiles[i];
        final url = await storageService.uploadFile('products', file);
        imageUrls.add(url);
        state = state.copyWith(progress: (i + 1) / state.imageFiles.length);
      }

      final newProduct = Product(
        id: '', // Firestore will generate this
        title: product.title,
        description: product.description,
        imageUrls: imageUrls,
        price: product.price,
        discountedPrice: product.discountedPrice,
        discountPercentage: product.discountPercentage,
        discountCountdown: product.discountCountdown,
        deliveryTime: product.deliveryTime,
        requiresAdvance: product.requiresAdvance,
      );

      await firestoreService.addProduct(newProduct);
      state = const UploadProductState(isLoading: false); // Reset state on success
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // ++ NEW: Method to update an existing product ++
  Future<void> updateProduct({required Product product}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, progress: 0.0);

    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateProduct(product);
      state = const UploadProductState(isLoading: false); // Reset state on success
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void reset() {
    state = const UploadProductState();
  }
}

final uploadProductProvider =
StateNotifierProvider.autoDispose<UploadProductNotifier, UploadProductState>(
        (ref) {
      return UploadProductNotifier(ref);
    });