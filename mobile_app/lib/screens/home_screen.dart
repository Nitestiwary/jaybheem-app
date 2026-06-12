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
    final seenIds = prefs.getStringList('seen_statuses') ?? [];
    
    // Generate fresh dummy data (now strictly images/videos)
    List<StatusModel> allStatuses = DummyData.generateStatuses();
    
    // Filter by category if provided
    if (widget.initialCategory != null && widget.initialCategory != 'All') {
      allStatuses = allStatuses.where((s) => s.category == widget.initialCategory).toList();
    }
    
    // Deduplicate: remove already seen posts
    List<StatusModel> unseenFeed = allStatuses.where((s) => !seenIds.contains(s.id)).toList();
    
    // If we ran out of unseen posts, we just show them all again
    if (unseenFeed.isEmpty) {
      unseenFeed = allStatuses;
    }

    // Shuffle for a TikTok-like random feed experience
    unseenFeed.shuffle();

    setState(() {
      _feed = unseenFeed;
      _isLoading = false;
    });

    // Mark the first one as seen
    if (_feed.isNotEmpty) {
      _markAsSeen(_feed.first.id);
    }
  }

  Future<void> _markAsSeen(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> seenIds = prefs.getStringList('seen_statuses') ?? [];
    if (!seenIds.contains(id)) {
      seenIds.add(id);
      // Keep only the last 500 to prevent infinite local storage growth
      if (seenIds.length > 500) seenIds.removeRange(0, seenIds.length - 500);
      await prefs.setStringList('seen_statuses', seenIds);
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
