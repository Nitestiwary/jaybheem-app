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
          const SizedBox(height: 40),
          _buildLegalLinks(),
        ],
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          GestureDetector(onTap: (){}, child: const Text('Privacy Policy', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
          GestureDetector(onTap: (){}, child: const Text('Terms', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
          GestureDetector(onTap: (){}, child: const Text('Disclaimer', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
          GestureDetector(onTap: (){}, child: const Text('Contact Us', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
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
              ),
              const SizedBox(height: 16),
              _buildLegalLinks(),
            ],
          ),
        ),
        const Expanded(
          child: SavedItemsViewer(),
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

class SavedItemsViewer extends StatefulWidget {
  const SavedItemsViewer({super.key});

  @override
  State<SavedItemsViewer> createState() => _SavedItemsViewerState();
}

class _SavedItemsViewerState extends State<SavedItemsViewer> {
  int _currentIndex = 0;

  void _removeFromSaved(String statusId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('bookmarks').doc(statusId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from saved')));
      }
    }
  }

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

        List<String> savedIds = snapshot.data!.docs.map((doc) => doc.id).toList();
        List<StatusModel> allStatuses = DummyData.generateStatuses();
        List<StatusModel> savedStatuses = allStatuses.where((s) => savedIds.contains(s.id)).toList();

        if (savedStatuses.isEmpty) {
          return const Center(child: Text('No saved items yet.'));
        }

        if (_currentIndex >= savedStatuses.length) {
          _currentIndex = savedStatuses.length - 1;
        }

        final status = savedStatuses[_currentIndex];

        return Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MediaItemWidget(status: status),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                        onPressed: () => _removeFromSaved(status.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                  Text('${_currentIndex + 1} of ${savedStatuses.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ElevatedButton(
                    onPressed: _currentIndex < savedStatuses.length - 1 ? () => setState(() => _currentIndex++) : null,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text('Next'), SizedBox(width: 8), Icon(Icons.arrow_forward_ios, size: 16)],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
