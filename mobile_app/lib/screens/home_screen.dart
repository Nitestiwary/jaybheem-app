import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/status_model.dart';
import '../widgets/status_card.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> categories = DummyData.categories;
  late List<StatusModel> statuses;
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    statuses = DummyData.generateStatuses();
  }

  List<StatusModel> get filteredStatuses {
    if (selectedCategory == 'All') return statuses;
    return statuses.where((s) => s.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jay Bheem', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // Categories list
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                final category = index == 0 ? 'All' : categories[index - 1];
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.darkText,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: filteredStatuses.length,
              itemBuilder: (context, index) {
                final status = filteredStatuses[index];
                return StatusCard(
                  status: status,
                  onSave: () {
                    // Save functionality placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved to favorites!')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
