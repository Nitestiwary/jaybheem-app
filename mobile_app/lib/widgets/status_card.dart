import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/status_model.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusCard extends StatefulWidget {
  final StatusModel status;
  final VoidCallback onSave;

  const StatusCard({super.key, required this.status, required this.onSave});

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> {
  final ScreenshotController screenshotController = ScreenshotController();
  bool isSharing = false;

  void _shareContent(BuildContext context) async {
    if (widget.status.type == 'text' && widget.status.imageUrl == null) {
      Share.share('${widget.status.text}\n\n- Shared from Jay Bheem App');
      return;
    }

    setState(() => isSharing = true);
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = await screenshotController.captureAndSave(
        directory.path,
        fileName: 'jay_bheem_status_${DateTime.now().millisecondsSinceEpoch}.png',
        pixelRatio: 3.0, // High quality for sharing
      );
      if (imagePath != null) {
        await Share.shareXFiles(
          [XFile(imagePath)], 
          text: 'Namo Buddhay, Jai Bhim! 🙏\n- Shared via Jay Bheem App'
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error preparing image for share')),
      );
    }
    setState(() => isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = widget.status.imageUrl != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The visual part of the card that gets screenshot
          Screenshot(
            controller: screenshotController,
            child: Container(
              color: hasImage ? Colors.black : AppTheme.primaryBlue,
              child: Stack(
                children: [
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: widget.status.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 350,
                      placeholder: (context, url) => const SizedBox(
                        height: 350,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => const SizedBox(
                        height: 350,
                        child: Center(child: Icon(Icons.error, color: Colors.white)),
                      ),
                    ),
                  
                  if (hasImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        if (!hasImage)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.status.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        
                        if (hasImage) const SizedBox(height: 180), // Push text down over image

                        // Main Text/Quote
                        Text(
                          widget.status.text ?? '',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: hasImage ? 22 : 24,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            shadows: hasImage ? [
                              Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 8, offset: const Offset(1, 1))
                            ] : [],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action Bar (Not included in screenshot)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.share, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.status.shareCount} Shares',
                      style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppTheme.darkText),
                      onPressed: () {
                        // Implement copy
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      tooltip: 'Copy Text',
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border, color: AppTheme.darkText),
                      onPressed: widget.onSave,
                      tooltip: 'Save to Favorites',
                    ),
                    isSharing
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.share, color: AppTheme.primaryBlue),
                            onPressed: () => _shareContent(context),
                            tooltip: 'Share',
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
