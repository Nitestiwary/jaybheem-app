import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/dummy_data.dart';
import '../models/status_model.dart';
import '../widgets/media_item_widget.dart';

class HomeScreen extends StatefulWidget {
  final String? initialCategory;
  const HomeScreen({super.key, this.initialCategory});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  List<StatusModel> _feed = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final prefs = await SharedPreferences.getInstance();
    // 'seen_statuses' list of strings in format: "id|timestamp_ms"
    final seenList = prefs.getStringList('seen_statuses') ?? [];
    
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int oneDayMs = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
    
    // Filter out old entries from SharedPreferences to keep it clean
    List<String> validSeenList = [];
    Set<String> seenIdsWithin24h = {};
    
    for (String item in seenList) {
      final parts = item.split('|');
      if (parts.length == 2) {
        final id = parts[0];
        final timestamp = int.tryParse(parts[1]) ?? 0;
        
        if (nowMs - timestamp < oneDayMs) {
          validSeenList.add(item);
          seenIdsWithin24h.add(id);
        }
      }
      // Old formats without timestamps are ignored/dropped automatically
    }
    
    // Update preferences with cleaned up list
    await prefs.setStringList('seen_statuses', validSeenList);
    
    // Generate fresh dummy data (now strictly images/videos)
    List<StatusModel> allStatuses = DummyData.generateStatuses();
    
    // Filter by category if provided
    if (widget.initialCategory != null && widget.initialCategory != 'All') {
      allStatuses = allStatuses.where((s) => s.category == widget.initialCategory).toList();
    }
    
    // Deduplicate: remove posts seen within last 24h
    List<StatusModel> unseenFeed = allStatuses.where((s) => !seenIdsWithin24h.contains(s.id)).toList();
    
    // If we ran out of unseen posts, we just show them all again (fallback)
    if (unseenFeed.isEmpty) {
      unseenFeed = allStatuses;
    }

    // Always try to push newest post at top, but still keep it random
    // We sort by newest first...
    unseenFeed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // ...then we shuffle in small chunks to give a random feel while keeping newer items generally at the top.
    List<StatusModel> mixedFeed = [];
    for (int i = 0; i < unseenFeed.length; i += 5) {
      int end = (i + 5 < unseenFeed.length) ? i + 5 : unseenFeed.length;
      List<StatusModel> chunk = unseenFeed.sublist(i, end);
      chunk.shuffle();
      mixedFeed.addAll(chunk);
    }

    setState(() {
      _feed = mixedFeed;
      _isLoading = false;
    });

    // Mark the first one as seen
    if (_feed.isNotEmpty) {
      _markAsSeen(_feed.first.id);
    }
  }

  Future<void> _markAsSeen(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> seenList = prefs.getStringList('seen_statuses') ?? [];
    
    // Check if it already exists to avoid duplicates
    if (!seenList.any((element) => element.startsWith('$id|'))) {
      seenList.add('$id|${DateTime.now().millisecondsSinceEpoch}');
      // Keep only the last 500 to prevent infinite local storage growth
      if (seenList.length > 500) seenList.removeRange(0, seenList.length - 500);
      await prefs.setStringList('seen_statuses', seenList);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: widget.initialCategory != null 
        ? AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              widget.initialCategory!, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black87, blurRadius: 4)]),
            ),
          )
        : null,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _feed.length,
        onPageChanged: (index) {
          _markAsSeen(_feed[index].id);
        },
        itemBuilder: (context, index) {
          return MediaItemWidget(status: _feed[index]);
        },
      ),
    );
  }
}
