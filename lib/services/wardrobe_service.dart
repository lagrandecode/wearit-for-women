import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../models/wardrobe_item.dart';

/// Service for managing wardrobe items with Firebase persistence
class WardrobeService extends ChangeNotifier {
  static const String _firestoreCollection = 'wardrobe_items';
  List<WardrobeItem> _wardrobeItems = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  List<WardrobeItem> get wardrobeItems => _wardrobeItems;

  /// Get total amount spent
  double get totalSpent {
    return _wardrobeItems.fold(0.0, (sum, item) => sum + item.price);
  }

  /// Get spending by category
  Map<WardrobeCategory, double> get spendingByCategory {
    final Map<WardrobeCategory, double> spending = {};
    for (var item in _wardrobeItems) {
      spending[item.category] = (spending[item.category] ?? 0.0) + item.price;
    }
    return spending;
  }

  /// Get items by category
  List<WardrobeItem> getItemsByCategory(WardrobeCategory category) {
    return _wardrobeItems.where((item) => item.category == category).toList();
  }

  WardrobeService() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // Load only from Firebase
    await _syncFromFirebase();
  }

  /// Add a wardrobe item
  Future<void> addItem(WardrobeItem item) async {
    try {
      // Upload image to Firebase Storage and get URL
      print('🔄 Starting to add wardrobe item...');
      final itemWithUrl = await _uploadImageToFirebase(item);
      print('✅ Image uploaded, URL: ${itemWithUrl.imageUrl}');
      
      // Save to Firebase (this will get the Firebase ID)
      final savedItem = await _saveItemToFirebase(itemWithUrl);
      
      // Add to local list only after successful Firebase save
      if (savedItem != null) {
        print('✅ Item saved to Firebase with ID: ${savedItem.firebaseId}');
        _wardrobeItems.add(savedItem);
        notifyListeners();
      } else {
        throw Exception('Failed to save item to Firebase');
      }
    } catch (e) {
      print('❌ Error adding wardrobe item: $e');
      rethrow;
    }
  }

  /// Remove an item
  Future<void> removeItem(WardrobeItem item) async {
    _wardrobeItems.remove(item);
    
    // Delete from Firebase
    if (item.firebaseId != null) {
      await _deleteItemFromFirebase(item.firebaseId!);
    }
    
      // Delete image from Firebase Storage
      if (item.imageUrl.startsWith('http://') || item.imageUrl.startsWith('https://')) {
        await _deleteImageFromFirebaseStorage(item.imageUrl);
      }
      
      notifyListeners();
  }

  /// Upload image to Firebase Storage and return item with URL
  Future<WardrobeItem> _uploadImageToFirebase(WardrobeItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ User not logged in, cannot upload to Firebase');
      throw Exception('User must be logged in to add wardrobe items');
    }

    // Skip if already a URL
    if (item.imageUrl.startsWith('http://') || item.imageUrl.startsWith('https://')) {
      print('✅ Image already has URL: ${item.imageUrl}');
      return item;
    }

    try {
      final file = File(item.imageUrl);
      if (!file.existsSync()) {
        print('❌ Image file not found: ${item.imageUrl}');
        throw Exception('Image file not found: ${item.imageUrl}');
      }

      print('📤 Uploading image to Firebase Storage...');
      final storage = FirebaseStorage.instance;
      // Create unique path for each image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.uid}/wardrobe/${timestamp}_${file.path.split('/').last}';
      final ref = storage.ref().child(fileName);

      // Upload file
      await ref.putFile(file);
      
      // Get download URL
      final url = await ref.getDownloadURL();
      print('✅ Uploaded wardrobe image to Firebase Storage: $url');
      
      return WardrobeItem(
        id: item.id,
        imageUrl: url,
        category: item.category,
        price: item.price,
        createdAt: item.createdAt,
        firebaseId: item.firebaseId,
      );
    } catch (e) {
      print('❌ Error uploading image to Firebase: $e');
      rethrow; // Re-throw to let caller handle the error
    }
  }

  /// Save item to Firestore
  /// Returns the item with Firebase ID, or null if save failed
  Future<WardrobeItem?> _saveItemToFirebase(WardrobeItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in, skipping Firebase save');
      return null;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final itemData = {
        'userId': user.uid,
        'imageUrl': item.imageUrl,
        'category': item.category.name,
        'price': item.price,
        'createdAt': Timestamp.fromDate(item.createdAt),
        'updatedAt': Timestamp.now(),
      };

      if (item.firebaseId != null) {
        // Update existing document
        await firestore
            .collection(_firestoreCollection)
            .doc(item.firebaseId)
            .update(itemData);
        print('Updated wardrobe item in Firebase');
        return item;
      } else {
        // Create new document
        final docRef = await firestore
            .collection(_firestoreCollection)
            .add(itemData);
        
        print('Saved wardrobe item to Firebase with ID: ${docRef.id}');
        // Return item with Firebase ID
        return item.copyWith(firebaseId: docRef.id);
      }
    } catch (e) {
      print('Error saving wardrobe item to Firebase: $e');
      return null;
    }
  }

  /// Sync items from Firebase
  Future<void> _syncFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in, skipping Firebase sync');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final firestore = FirebaseFirestore.instance;
      final itemsSnapshot = await firestore
          .collection(_firestoreCollection)
          .where('userId', isEqualTo: user.uid)
          .get();
      
      // Sort by createdAt in memory
      final sortedDocs = itemsSnapshot.docs.toList()
        ..sort((a, b) {
          final dateA = (a.data()['createdAt'] as Timestamp).toDate();
          final dateB = (b.data()['createdAt'] as Timestamp).toDate();
          return dateB.compareTo(dateA); // Newest first
        });

      // Clear existing items and load fresh from Firebase
      _wardrobeItems.clear();
      
      for (var doc in sortedDocs) {
        final data = doc.data();
        final imageUrl = data['imageUrl'] as String? ?? '';
        
        print('📥 Loading wardrobe item from Firebase:');
        print('   ID: ${doc.id}');
        print('   Image URL: $imageUrl');
        print('   Category: ${data['category']}');
        print('   Price: ${data['price']}');
        
        if (imageUrl.isEmpty) {
          print('⚠️ Warning: Item ${doc.id} has empty imageUrl');
          continue; // Skip items without image URLs
        }
        
        final item = WardrobeItem(
          id: doc.id,
          imageUrl: imageUrl,
          category: WardrobeCategory.values.firstWhere(
            (e) => e.name == data['category'],
            orElse: () => WardrobeCategory.clothes,
          ),
          price: (data['price'] as num).toDouble(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          firebaseId: doc.id,
        );
        _wardrobeItems.add(item);
      }

      notifyListeners();
      print('Synced ${sortedDocs.length} wardrobe items from Firebase');
    } catch (e) {
      print('Error syncing from Firebase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete item from Firestore
  Future<void> _deleteItemFromFirebase(String firebaseId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(firebaseId)
          .delete();
      print('Deleted wardrobe item from Firebase: $firebaseId');
    } catch (e) {
      print('Error deleting wardrobe item from Firebase: $e');
    }
  }

  /// Delete a single image from Firebase Storage
  Future<void> _deleteImageFromFirebaseStorage(String imageUrl) async {
    try {
      // Only try to delete if it's a valid Firebase Storage URL
      if (!imageUrl.contains('firebasestorage.googleapis.com')) {
        print('Not a Firebase Storage URL, skipping delete: $imageUrl');
        return;
      }
      
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
      print('Deleted image from Firebase Storage: $imageUrl');
    } catch (e) {
      // Don't throw error if image doesn't exist
      if (e.toString().contains('object-not-found') || 
          e.toString().contains('No object exists')) {
        print('Image already deleted or not found: $imageUrl');
      } else {
        print('Error deleting image from Firebase Storage: $e');
      }
    }
  }


  /// Clear all items
  Future<void> clearAll() async {
    // Delete all from Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .where('userId', isEqualTo: user.uid)
          .get();
      
      for (var doc in itemsSnapshot.docs) {
        await doc.reference.delete();
      }
    }
    
    _wardrobeItems.clear();
    notifyListeners();
  }
}
