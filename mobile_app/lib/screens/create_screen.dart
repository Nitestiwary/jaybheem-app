import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  final TextEditingController textController = TextEditingController(text: "Jai Bhim");
  
  double _fontSize = 30.0;
  Color _textColor = Colors.white;
  int _selectedBgIndex = 0;
  bool _isExporting = false;

  final List<String> _backgrounds = [
    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Dr._Bhimrao_Ambedkar.jpg/800px-Dr._Bhimrao_Ambedkar.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Lord_Buddha_in_Sarnath.jpg/800px-Lord_Buddha_in_Sarnath.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Dr_B_R_Ambedkar_statue_at_Parliament_of_India.jpg/800px-Dr_B_R_Ambedkar_statue_at_Parliament_of_India.jpg',
  ];

  final List<Color> _colors = [Colors.white, Colors.black, Colors.amber, Colors.blue, Colors.red];

  Future<void> _exportAndShare() async {
    setState(() => _isExporting = true);
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = await screenshotController.captureAndSave(
        directory.path,
        fileName: 'dp_maker_${DateTime.now().millisecondsSinceEpoch}.png',
        pixelRatio: 3.0,
      );
      if (imagePath != null) {
        await Share.shareXFiles([XFile(imagePath)], text: 'Created with Jay Bheem App');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving DP')));
    }
    setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DP Maker', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _isExporting 
            ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)))
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: _exportAndShare,
                tooltip: 'Export & Share',
              )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // The Canvas
            Screenshot(
              controller: screenshotController,
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width, // Square for DP
                color: Colors.grey[200],
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: _backgrounds[_selectedBgIndex],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          textController.text,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: _fontSize,
                            color: _textColor,
                            fontWeight: FontWeight.bold,
                            shadows: const [Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(2, 2))],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Editor Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Your Text / Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const Text('Font Size', style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _fontSize,
                    min: 16.0,
                    max: 80.0,
                    onChanged: (val) => setState(() => _fontSize = val),
                  ),
                  const SizedBox(height: 8),
                  const Text('Text Color', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: _colors.map((color) => GestureDetector(
                      onTap: () => setState(() => _textColor = color),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: _textColor == color ? AppTheme.primaryBlue : Colors.grey, width: 3),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Background Template', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _backgrounds.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => setState(() => _selectedBgIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 80,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedBgIndex == index ? AppTheme.primaryBlue : Colors.transparent,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(_backgrounds[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
