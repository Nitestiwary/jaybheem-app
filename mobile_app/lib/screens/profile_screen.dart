import 'package:flutter/material.dart';
import '../services/firebase_seeder.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('User Profile & Saved Items', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => FirebaseSeeder.seedDatabase(context),
              icon: const Icon(Icons.upload),
              label: const Text('Seed Dummy Data to Firestore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Developer Tool: Populates Firestore with 100 dummy statuses',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

