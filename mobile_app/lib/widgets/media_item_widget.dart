import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/status_model.dart';
import '../theme/app_theme.dart';

class MediaItemWidget extends StatefulWidget {
  final StatusModel status;
  
  const MediaItemWidget({super.key, required this.status});

  @override
  State<MediaItemWidget> createState() => _MediaItemWidgetState();
}

class _MediaItemWidgetState extends State<MediaItemWidget> {
  VideoPlayerController? _videoController;
  bool _isDownloading = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    if (widget.status.type == 'video' && widget.status.videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.status.videoUrl!))
        ..initialize().then((_) {
          _videoController?.setLooping(true);
          setState(() {});
        });
    }
    _checkBookmarkStatus();
  }

  void _checkBookmarkStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(widget.status.id)
          .get()
          .then((doc) {
        if (doc.exists && mounted) {
          setState(() => _isBookmarked = true);
        }
      });
    }
  }

  void _toggleBookmark() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login from Profile tab to save items.')));
      }
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('bookmarks').doc(widget.status.id);
    
    if (_isBookmarked) {
      await docRef.delete();
      setState(() => _isBookmarked = false);
    } else {
      await docRef.set({'savedAt': FieldValue.serverTimestamp()});
      setState(() => _isBookmarked = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Bookmarks!')));
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (_videoController == null) return;
    if (info.visibleFraction > 0.5) {
      _videoController?.play();
    } else {
      _videoController?.pause();
    }
  }

  Future<void> _downloadMedia() async {
    setState(() => _isDownloading = true);
    try {
      final hasAccess = await Gal.requestAccess();
      if (!hasAccess) throw Exception('No gallery access');

      final url = widget.status.type == 'video' ? widget.status.videoUrl : widget.status.imageUrl;
      if (url == null) throw Exception('No media url');

      final ext = widget.status.type == 'video' ? 'mp4' : 'jpg';
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/jaybheem_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await Dio().download(
        url, 
        path,
        options: Options(headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}),
      );
      
      if (widget.status.type == 'video') {
        await Gal.putVideo(path);
      } else {
        await Gal.putImage(path);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Gallery!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download media.')));
      }
    }
    setState(() => _isDownloading = false);
  }

  void _showShareMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 30,
              runSpacing: 24,
              children: [
                _buildShareOption(Icons.chat_bubble_outline, 'WhatsApp', () => _shareToSocial('whatsapp')),
                _buildShareOption(Icons.camera_alt_outlined, 'Insta Feed', () => _shareToSocial('insta_feed')),
                _buildShareOption(Icons.history_toggle_off, 'Insta Story', () => _shareToSocial('insta_story')),
                _buildShareOption(Icons.facebook, 'FB Feed', () => _shareToSocial('fb_feed')),
                _buildShareOption(Icons.amp_stories_outlined, 'FB Story', () => _shareToSocial('fb_story')),
                _buildShareOption(Icons.more_horiz, 'Other', () => _shareToSocial('other')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _shareToSocial(String platform) async {
    Navigator.pop(context); // Close bottom sheet
    setState(() => _isDownloading = true);
    
    try {
      final url = widget.status.type == 'video' ? widget.status.videoUrl : widget.status.imageUrl;
      if (url == null) throw Exception('No media url');

      final ext = widget.status.type == 'video' ? 'mp4' : 'jpg';
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/jaybheem_share_${DateTime.now().millisecondsSinceEpoch}.$ext';

      // Download file to temp storage so social apps can access it locally
      await Dio().download(
        url, 
        path,
        options: Options(headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}),
      );
      
      final appinioSocialShare = AppinioSocialShare();

      // "share_plus" is often more reliable for standard intents.
      // Also, social_share does not support videoPath for IG/FB Stories,      // Fall back to share_plus for generic feeds
      if (platform == 'other' || platform == 'fb_feed' || platform == 'insta_feed') {
        await Share.shareXFiles([XFile(path)], text: 'Check out this status on the Jay Bheem App!');
      } else {
        // Direct Story integration using appinio_social_share (Supports Video and Image!)
        switch (platform) {
          case 'whatsapp':
            await appinioSocialShare.android.shareToWhatsapp("Check out this status on the Jay Bheem App! $url", path);
            break;
          case 'insta_story':
            await appinioSocialShare.android.shareToInstagramStory("4057850024467367", 
              backgroundImage: widget.status.type == 'image' ? path : null,
              backgroundVideo: widget.status.type == 'video' ? path : null,
            );
            break;
          case 'fb_story':
            await appinioSocialShare.android.shareToFacebookStory("4057850024467367", 
              backgroundTopColor: "#000000", 
              backgroundBottomColor: "#000000", 
              backgroundImage: widget.status.type == 'image' ? path : null,
              backgroundVideo: widget.status.type == 'video' ? path : null,
            );
            break;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
    setState(() => _isDownloading = false);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.status.id),
      onVisibilityChanged: _handleVisibilityChanged,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Media
          if (widget.status.type == 'image' && widget.status.imageUrl != null)
            CachedNetworkImage(
              imageUrl: widget.status.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.white)),
            )
          else if (widget.status.type == 'video' && _videoController != null)
            _videoController!.value.isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),

          // Dark Gradient Overlay for text readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
          ),

          // Caption and Category
          Positioned(
            bottom: 20,
            left: 16,
            right: 80, // Leave room for side action buttons
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.status.category,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.status.text ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Right Side Action Buttons
          Positioned(
            bottom: 20,
            right: 8,
            child: Column(
              children: [
                _buildActionButton(
                  icon: Icons.download,
                  label: 'Download',
                  onTap: _downloadMedia,
                  isLoading: _isDownloading,
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  label: 'Save',
                  onTap: _toggleBookmark,
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: _showShareMenu,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, bool isLoading = false}) {
    return Column(
      children: [
        isLoading 
            ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Colors.white))
            : InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
