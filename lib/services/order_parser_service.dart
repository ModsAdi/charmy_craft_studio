// lib/services/order_parser_service.dart

import 'package:charmy_craft_studio/models/order_item.dart';
import 'package:charmy_craft_studio/models/product.dart';
import 'package:charmy_craft_studio/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParsedOrderData {
  final String? email;
  final List<({String productId, int quantity})> parsedItems;

  ParsedOrderData({required this.email, required this.parsedItems});
}

class OrderParserService {
  final Ref _ref;
  OrderParserService(this._ref);

  ParsedOrderData parseOrderFromString(String text) {
    final emailRegExp = RegExp(r"📧 \*Email:\* (.*?)\n");
    final productBlockRegExp = RegExp(r"📦 \*Product \d+\*\n([\s\S]*?)(?=\n\n|\z)");
    final idRegExp = RegExp(r"• \*ID:\* (\d{7})");
    final quantityRegExp = RegExp(r"• \*Quantity:\* (\d+)");

    final emailMatch = emailRegExp.firstMatch(text);
    final String? email = emailMatch?.group(1)?.trim();

    final productMatches = productBlockRegExp.allMatches(text);
    final List<({String productId, int quantity})> parsedItems = [];

    for (final match in productMatches) {
      final block = match.group(1)!;
      final idMatch = idRegExp.firstMatch(block);
      final quantityMatch = quantityRegExp.firstMatch(block);

      if (idMatch != null && quantityMatch != null) {
        parsedItems.add((
        productId: idMatch.group(1)!.trim(),
        quantity: int.tryParse(quantityMatch.group(1)!.trim()) ?? 1,
        ));
      }
    }

    return ParsedOrderData(email: email, parsedItems: parsedItems);
  }

  Future<List<OrderItem>> convertParsedItemsToOrderItems(List<({String productId, int quantity})> parsedItems) async {
    if (parsedItems.isEmpty) return [];

    final firestore = _ref.read(firestoreServiceProvider);
    final List<OrderItem> orderItems = [];

    for (final itemData in parsedItems) {
      final Product? product = await firestore.getProductById(itemData.productId);
      if (product != null) {
        orderItems.add(OrderItem(
          productId: product.id,
          title: product.title,
          imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
          price: product.discountedPrice ?? product.price,
          quantity: itemData.quantity,
        ));
      }
    }
    return orderItems;
  }
}

final orderParserServiceProvider = Provider((ref) => OrderParserService(ref));