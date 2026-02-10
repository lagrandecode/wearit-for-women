import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/planned_outfit.dart';
import 'notification_service.dart';

/// Service for managing planned outfits with persistence
class PlannerService extends ChangeNotifier {
  static const String _storageKey = 'planned_outfits';
  static const String _firestoreCollection = 'planned_outfits';
  Map<DateTime, List<PlannedOutfit>> _plannedOutfits = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;

  PlannerService() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // Load from local storage first (for offline support)
    await _loadOutfits();
    
    // Then sync with Firebase
    await _syncFromFirebase();
  }

  /// Get all planned outfits
  Map<DateTime, List<PlannedOutfit>> get plannedOutfits => _plannedOutfits;

  /// Get outfits for a specific date
  List<PlannedOutfit>? getOutfitsForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _plannedOutfits[dateKey];
  }

  /// Check if date has planned outfits
  bool hasOutfitsForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _plannedOutfits.containsKey(dateKey) && 
           _plannedOutfits[dateKey]!.isNotEmpty;
  }

  /// Add a planned outfit
  Future<void> addOutfit(PlannedOutfit outfit) async {
    final dateKey = DateTime(
      outfit.date.year,
      outfit.date.month,
      outfit.date.day,
    );

    if (_plannedOutfits[dateKey] == null) {
      _plannedOutfits[dateKey] = [];
    }

    // Upload images to Firebase Storage and get URLs
    final outfitWithUrls = await _uploadImagesToFirebase(outfit);
    
    _plannedOutfits[dateKey]!.add(outfitWithUrls);
    notifyListeners();
    
    // Save locally
    await _saveOutfits();
    
    // Save to Firebase
    await _saveOutfitToFirebase(outfitWithUrls);

    // Schedule notification
    await _scheduleNotification(outfitWithUrls);
  }

  /// Remove an outfit
  Future<void> removeOutfit(DateTime date, PlannedOutfit outfit) async {
    final dateKey = DateTime(date.year, date.month, date.day);
    
    if (_plannedOutfits[dateKey] != null) {
      _plannedOutfits[dateKey]!.remove(outfit);
      
      // Cancel notification
      await NotificationService.cancelNotification(outfit.notificationId);
      
      // Delete from Firebase
      if (outfit.firebaseId != null) {
        await _deleteOutfitFromFirebase(outfit.firebaseId!);
      }
      
      // Delete images from Firebase Storage
      await _deleteImagesFromFirebase(outfit.imagePaths);
      
      // Remove date entry if empty
      if (_plannedOutfits[dateKey]!.isEmpty) {
        _plannedOutfits.remove(dateKey);
      }
      
      notifyListeners();
      await _saveOutfits();
    }
  }

  /// Remove a specific image from an outfit
  Future<void> removeImageFromOutfit(
    DateTime date,
    PlannedOutfit outfit,
    int imageIndex,
  ) async {
    final dateKey = DateTime(date.year, date.month, date.day);
    
    if (_plannedOutfits[dateKey] != null) {
      final outfitIndex = _plannedOutfits[dateKey]!.indexOf(outfit);
      if (outfitIndex != -1) {
        final updatedOutfit = _plannedOutfits[dateKey]![outfitIndex];
        
        // Validate image index
        if (imageIndex < 0 || imageIndex >= updatedOutfit.imagePaths.length) {
          print('Invalid image index: $imageIndex (outfit has ${updatedOutfit.imagePaths.length} images)');
          return;
        }
        
        // Delete image from Firebase Storage if it's a URL
        final imagePath = updatedOutfit.imagePaths[imageIndex];
        if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
          await _deleteImageFromFirebaseStorage(imagePath);
        }
        
        // Remove the image path
        updatedOutfit.imagePaths.removeAt(imageIndex);
        
        // If no images left, remove the entire outfit
        if (updatedOutfit.imagePaths.isEmpty) {
          await removeOutfit(date, outfit);
        } else {
          // Update in Firebase
          await _saveOutfitToFirebase(updatedOutfit);
          notifyListeners();
          await _saveOutfits();
        }
      }
    }
  }

  /// Schedule notification for an outfit
  Future<void> _scheduleNotification(PlannedOutfit outfit) async {
    try {
      final scheduledDateTime = outfit.scheduledDateTime;
      
      // Schedule notification at the exact time the user set
      // Only schedule if the time is in the future
      if (scheduledDateTime.isAfter(DateTime.now())) {
        // Cancel any existing notification with the same ID first
        await NotificationService.cancelNotification(outfit.notificationId);
        
        await NotificationService.scheduleOutfitReminder(
          id: outfit.notificationId,
          title: 'Outfit Reminder',
          body: 'Time to wear your planned outfit!',
          scheduledDate: scheduledDateTime,
        );
        print('✅ Scheduled notification for ${outfit.formattedTime} on ${outfit.date.toString().split(' ')[0]} (ID: ${outfit.notificationId})');
      } else {
        print('⚠️ Cannot schedule notification in the past: ${scheduledDateTime.toString()}');
      }
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  /// Load outfits from storage
  Future<void> _loadOutfits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final outfitsJson = prefs.getString(_storageKey);
      
      if (outfitsJson != null) {
        final Map<String, dynamic> data = jsonDecode(outfitsJson);
        _plannedOutfits.clear();
        
        for (var entry in data.entries) {
          final dateKey = DateTime.parse(entry.key);
          final List<dynamic> outfitsList = entry.value;
          
          final loadedOutfits = outfitsList
              .map((json) => PlannedOutfit.fromJson(json))
              .where((outfit) => outfit.hasValidImages) // Only keep outfits with valid images
              .toList();
          
          _plannedOutfits[dateKey] = loadedOutfits;
          
          // Reschedule notifications for all loaded outfits (only future ones)
          for (var outfit in loadedOutfits) {
            final scheduledDateTime = outfit.scheduledDateTime;
            if (scheduledDateTime.isAfter(DateTime.now())) {
              await _scheduleNotification(outfit);
            }
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Error loading planned outfits: $e');
    }
  }

  /// Save outfits to storage
  Future<void> _saveOutfits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert to JSON
      final Map<String, dynamic> data = {};
      for (var entry in _plannedOutfits.entries) {
        final dateKey = entry.key.toIso8601String();
        data[dateKey] = entry.value.map((outfit) => outfit.toJson()).toList();
      }
      
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      print('Error saving planned outfits: $e');
    }
  }

  /// Clear all planned outfits
  Future<void> clearAll() async {
    // Cancel all notifications
    for (var outfits in _plannedOutfits.values) {
      for (var outfit in outfits) {
        await NotificationService.cancelNotification(outfit.notificationId);
      }
    }
    
    // Delete all from Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final outfitsSnapshot = await FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .where('userId', isEqualTo: user.uid)
          .get();
      
      for (var doc in outfitsSnapshot.docs) {
        await doc.reference.delete();
      }
    }
    
    _plannedOutfits.clear();
    notifyListeners();
    await _saveOutfits();
  }

  /// Upload images to Firebase Storage and return outfit with URLs
  Future<PlannedOutfit> _uploadImagesToFirebase(PlannedOutfit outfit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User not logged in, return outfit as-is (local only)
      return outfit;
    }

    final List<String> imageUrls = [];
    final storage = FirebaseStorage.instance;

    for (var imagePath in outfit.imagePaths) {
      // Skip if already a URL
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        imageUrls.add(imagePath);
        continue;
      }

      try {
        final file = File(imagePath);
        if (!file.existsSync()) {
          print('Image file not found: $imagePath');
          continue;
        }

        // Create unique path for each image
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${user.uid}/outfits/${timestamp}_${file.path.split('/').last}';
        final ref = storage.ref().child(fileName);

        // Upload file
        await ref.putFile(file);
        
        // Get download URL
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
        print('Uploaded image to Firebase Storage: $url');
      } catch (e) {
        print('Error uploading image to Firebase: $e');
        // Keep local path as fallback
        imageUrls.add(imagePath);
      }
    }

    return PlannedOutfit(
      date: outfit.date,
      time: outfit.time,
      imagePaths: imageUrls,
      notificationId: outfit.notificationId,
      firebaseId: outfit.firebaseId,
    );
  }

  /// Save outfit to Firestore
  Future<void> _saveOutfitToFirebase(PlannedOutfit outfit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in, skipping Firebase save');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final outfitData = {
        'userId': user.uid,
        'date': Timestamp.fromDate(outfit.date),
        'timeHour': outfit.time.hour,
        'timeMinute': outfit.time.minute,
        'imageUrls': outfit.imagePaths,
        'notificationId': outfit.notificationId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      if (outfit.firebaseId != null) {
        // Update existing document
        await firestore
            .collection(_firestoreCollection)
            .doc(outfit.firebaseId)
            .update(outfitData);
      } else {
        // Create new document
        final docRef = await firestore
            .collection(_firestoreCollection)
            .add(outfitData);
        
        // Update local outfit with Firebase ID
        final dateKey = DateTime(
          outfit.date.year,
          outfit.date.month,
          outfit.date.day,
        );
        final outfitIndex = _plannedOutfits[dateKey]?.indexOf(outfit);
        if (outfitIndex != null && outfitIndex != -1) {
          _plannedOutfits[dateKey]![outfitIndex] = PlannedOutfit(
            date: outfit.date,
            time: outfit.time,
            imagePaths: outfit.imagePaths,
            notificationId: outfit.notificationId,
            firebaseId: docRef.id,
          );
        }
      }
      print('Saved outfit to Firebase');
    } catch (e) {
      print('Error saving outfit to Firebase: $e');
    }
  }

  /// Sync outfits from Firebase
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
      // Get all outfits for user, then sort in memory (avoids needing composite index)
      final outfitsSnapshot = await firestore
          .collection(_firestoreCollection)
          .where('userId', isEqualTo: user.uid)
          .get();
      
      // Sort by date in memory
      final sortedDocs = outfitsSnapshot.docs.toList()
        ..sort((a, b) {
          final dateA = (a.data()['date'] as Timestamp).toDate();
          final dateB = (b.data()['date'] as Timestamp).toDate();
          return dateA.compareTo(dateB);
        });

      for (var doc in outfitsSnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dateKey = DateTime(date.year, date.month, date.day);

        final outfit = PlannedOutfit(
          date: dateKey,
          time: TimeOfDay(
            hour: data['timeHour'] as int,
            minute: data['timeMinute'] as int,
          ),
          imagePaths: List<String>.from(data['imageUrls'] ?? []),
          notificationId: data['notificationId'] as int,
          firebaseId: doc.id,
        );

        // Only add if not already in local storage (avoid duplicates)
        if (_plannedOutfits[dateKey] == null) {
          _plannedOutfits[dateKey] = [];
        }
        
        // Check if outfit already exists (by Firebase ID or notification ID)
        final exists = _plannedOutfits[dateKey]!.any((o) => 
          o.firebaseId == outfit.firebaseId || 
          o.notificationId == outfit.notificationId);
        
        if (!exists) {
          _plannedOutfits[dateKey]!.add(outfit);
          // Reschedule notification only if it's in the future
          final scheduledDateTime = outfit.scheduledDateTime;
          if (scheduledDateTime.isAfter(DateTime.now())) {
            await _scheduleNotification(outfit);
          }
        }
      }

      notifyListeners();
      await _saveOutfits();
      print('Synced ${sortedDocs.length} outfits from Firebase');
    } catch (e) {
      print('Error syncing from Firebase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete outfit from Firestore
  Future<void> _deleteOutfitFromFirebase(String firebaseId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(firebaseId)
          .delete();
      print('Deleted outfit from Firebase: $firebaseId');
    } catch (e) {
      print('Error deleting outfit from Firebase: $e');
    }
  }

  /// Delete images from Firebase Storage
  Future<void> _deleteImagesFromFirebase(List<String> imagePaths) async {
    for (var imagePath in imagePaths) {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        await _deleteImageFromFirebaseStorage(imagePath);
      }
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
      // Don't throw error if image doesn't exist - it might have been deleted already
      if (e.toString().contains('object-not-found') || 
          e.toString().contains('No object exists')) {
        print('Image already deleted or not found: $imageUrl');
      } else {
        print('Error deleting image from Firebase Storage: $e');
      }
    }
  }
}
