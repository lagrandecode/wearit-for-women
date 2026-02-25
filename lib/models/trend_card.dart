import 'package:cloud_firestore/cloud_firestore.dart';

class TrendCard {
  final String id;
  final String mediaUrl; // Image or video URL
  final String mediaType; // 'image' or 'video'
  final String prompt; // AI generation prompt
  final int order; // Display order
  final DateTime createdAt;
  final DateTime updatedAt;

  TrendCard({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    required this.prompt,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'prompt': prompt,
      'order': order,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from Firestore document
  factory TrendCard.fromFirestore(String id, Map<String, dynamic> data) {
    return TrendCard(
      id: id,
      mediaUrl: data['mediaUrl'] ?? '',
      mediaType: data['mediaType'] ?? 'video',
      prompt: data['prompt'] ?? '',
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  TrendCard copyWith({
    String? id,
    String? mediaUrl,
    String? mediaType,
    String? prompt,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrendCard(
      id: id ?? this.id,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      prompt: prompt ?? this.prompt,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
