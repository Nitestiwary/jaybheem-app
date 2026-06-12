import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/dummy_data.dart';
import '../models/status_model.dart';
import 'package:flutter/material.dart';

class FirebaseSeeder {
  static Future<void> seedDatabase(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final statuses = DummyData.generateStatuses();
    
    int count = 0;
    
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seeding database. Please wait...')),
    );

    try {
      final batch = firestore.batch();
      
      // Batch write 100+ statuses
      for (StatusModel status in statuses) {
        DocumentReference docRef = firestore.collection('statuses').doc(status.id);
        batch.set(docRef, status.toMap());
        count++;
        
        // Firestore batches can only have 500 writes. We have ~120, so 1 batch is fine.
      }
      
      // Add categories as well
      for (int i = 0; i < DummyData.categories.length; i++) {
        String category = DummyData.categories[i];
        DocumentReference catRef = firestore.collection('categories').doc(category);
        batch.set(catRef, {
          'name': category,
          'order': i,
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully seeded $count statuses and categories!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seeding database: $e')),
      );
    }
  }
}
