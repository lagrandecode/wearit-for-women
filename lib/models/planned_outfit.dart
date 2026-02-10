import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Model for a planned outfit with date, time, and images
class PlannedOutfit {
  final DateTime date;
  final TimeOfDay time;
  final List<String> imagePaths; // Store paths (local) or URLs (Firebase Storage)
  final int notificationId; // Unique ID for notification
  final String? firebaseId; // Firebase document ID for syncing

  PlannedOutfit({
    required this.date,
    required this.time,
    required this.imagePaths,
    required this.notificationId,
    this.firebaseId,
  });

  /// Create from XFile list (for new outfits)
  factory PlannedOutfit.fromXFiles({
    required DateTime date,
    required TimeOfDay time,
    required List<XFile> images,
    required int notificationId,
  }) {
    return PlannedOutfit(
      date: date,
      time: time,
      imagePaths: images.map((img) => img.path).toList(),
      notificationId: notificationId,
    );
  }

  /// Convert to XFile list (for display)
  List<XFile> get images {
    return imagePaths.map((path) => XFile(path)).toList();
  }

  /// Get the full DateTime for when the outfit should be worn
  DateTime get scheduledDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  /// Get formatted time string
  String get formattedTime {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'imagePaths': imagePaths,
      'notificationId': notificationId,
      'firebaseId': firebaseId,
    };
  }

  /// Create from JSON
  factory PlannedOutfit.fromJson(Map<String, dynamic> json) {
    return PlannedOutfit(
      date: DateTime.parse(json['date']),
      time: TimeOfDay(
        hour: json['timeHour'],
        minute: json['timeMinute'],
      ),
      imagePaths: List<String>.from(json['imagePaths']),
      notificationId: json['notificationId'],
      firebaseId: json['firebaseId'],
    );
  }

  /// Create a copy with updated Firebase ID
  PlannedOutfit copyWith({String? firebaseId}) {
    return PlannedOutfit(
      date: date,
      time: time,
      imagePaths: imagePaths,
      notificationId: notificationId,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }

  /// Check if all images still exist (for local paths) or are URLs
  bool get hasValidImages {
    return imagePaths.every((path) {
      // If it's a URL (starts with http:// or https://), it's valid
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return true;
      }
      // Otherwise, check if local file exists
      return File(path).existsSync();
    });
  }

  /// Get only valid images (that still exist or are URLs)
  List<String> get validImagePaths {
    return imagePaths.where((path) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return true;
      }
      return File(path).existsSync();
    }).toList();
  }

  /// Check if images are stored in Firebase Storage
  bool get hasFirebaseImages {
    return imagePaths.any((path) => 
      path.startsWith('http://') || path.startsWith('https://'));
  }
}
