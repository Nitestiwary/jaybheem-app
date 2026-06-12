import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firebase_seeder.dart';
import '../data/dummy_data.dart';
import '../models/status_model.dart';
import '../widgets/media_item_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _phoneController = TextEditingController(text: "+91");
  final TextEditingController _otpController = TextEditingController();
  
  String _verificationId = "";
  bool _isCodeSent = false;
  bool _isLoading = false;

  void _verifyPhone() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verification failed')));
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isCodeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _isLoading = false);
    }
  }

  void _verifyOTP() async {
    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
    }
    setState(() => _isLoading = false);
  }

  Widget _buildAuthUI() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text('Login to Save Bookmarks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Enter your phone number to access your saved videos and images.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          
          if (!_isCodeSent) ...[
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyPhone,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Send OTP'),
              ),
            ),
          ] else ...[
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '6-Digit OTP',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.password),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Verify & Login'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileUI(User user) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          color: Colors.blue.withOpacity(0.1),
          child: Column(
            children: [
              const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
              const SizedBox(height: 16),
              Text(user.phoneNumber ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out'),
              )
            ],
          ),
        ),
        const Expanded(
          child: SavedItemsGrid(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Saved')),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data != null) {
            return _buildProfileUI(snapshot.data!);
          }
          return _buildAuthUI();
        },
      ),
    );
  }
}

class SavedItemsGrid extends StatelessWidget {
  const SavedItemsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('bookmarks').orderBy('savedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No saved items yet.'));
        }

        // Get saved IDs
        List<String> savedIds = snapshot.data!.docs.map((doc) => doc.id).toList();
        
        // Temporarily map from DummyData until real feed is implemented
        List<StatusModel> allStatuses = DummyData.generateStatuses();
        List<StatusModel> savedStatuses = allStatuses.where((s) => savedIds.contains(s.id)).toList();

        return MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          padding: const EdgeInsets.all(4),
          itemCount: savedStatuses.length,
          itemBuilder: (context, index) {
            final status = savedStatuses[index];
            return GestureDetector(
              onTap: () {
                // Open full screen view
                Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                  body: MediaItemWidget(status: status),
                  extendBodyBehindAppBar: true,
                  appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
                )));
              },
              child: Stack(
                children: [
                  if (status.type == 'image' && status.imageUrl != null)
                    CachedNetworkImage(imageUrl: status.imageUrl!, fit: BoxFit.cover),
                  if (status.type == 'video')
                    Container(
                      color: Colors.black,
                      height: 200,
                      child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 50)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
