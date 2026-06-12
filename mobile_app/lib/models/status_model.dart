import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  final String id;
  final String? text;
  final String? imageUrl;
  final String category;
  final String type; // 'text' or 'image'
  final int viewCount;
  final int shareCount;
  final DateTime createdAt;

  StatusModel({
    required this.id,
    this.text,
    this.imageUrl,
    required this.category,
    required this.type,
    this.viewCount = 0,
    this.shareCount = 0,
    required this.createdAt,
  });

  factory StatusModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StatusModel(
      id: doc.id,
      text: data['text'],
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'General',
      type: data['type'] ?? 'text',
      viewCount: data['viewCount'] ?? 0,
      shareCount: data['shareCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'imageUrl': imageUrl,
      'category': category,
      'type': type,
      'viewCount': viewCount,
      'shareCount': shareCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
