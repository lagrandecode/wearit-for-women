import 'package:flutter/material.dart';

/// Categories for wardrobe items
enum WardrobeCategory {
  clothes,
  bottom,
  shoes,
  bags,
  jewelries,
  accessories;

  String get displayName {
    switch (this) {
      case WardrobeCategory.clothes:
        return 'Clothes';
      case WardrobeCategory.bottom:
        return 'Bottom';
      case WardrobeCategory.shoes:
        return 'Shoes/Footwear';
      case WardrobeCategory.bags:
        return 'Bags';
      case WardrobeCategory.jewelries:
        return 'Jewelries';
      case WardrobeCategory.accessories:
        return 'Accessories';
    }
  }

  IconData get icon {
    switch (this) {
      case WardrobeCategory.clothes:
        return Icons.checkroom;
      case WardrobeCategory.bottom:
        return Icons.shopping_bag;
      case WardrobeCategory.shoes:
        return Icons.shopping_bag_outlined;
      case WardrobeCategory.bags:
        return Icons.shopping_bag;
      case WardrobeCategory.jewelries:
        return Icons.diamond;
      case WardrobeCategory.accessories:
        return Icons.watch;
    }
  }
}

/// Model for a wardrobe item
class WardrobeItem {
  final String id;
  final String imageUrl; // Firebase Storage URL or local path
  final WardrobeCategory category;
  final double price;
  final DateTime createdAt;
  final String? firebaseId; // Firebase document ID

  WardrobeItem({
    required this.id,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.createdAt,
    this.firebaseId,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'category': category.name,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
      'firebaseId': firebaseId,
    };
  }

  /// Create from JSON
  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      category: WardrobeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => WardrobeCategory.clothes,
      ),
      price: (json['price'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      firebaseId: json['firebaseId'],
    );
  }

  /// Create a copy with updated Firebase ID
  WardrobeItem copyWith({String? firebaseId}) {
    return WardrobeItem(
      id: id,
      imageUrl: imageUrl,
      category: category,
      price: price,
      createdAt: createdAt,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}
