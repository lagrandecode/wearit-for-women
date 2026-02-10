import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_constants.dart';
import '../models/wardrobe_item.dart';
import '../services/wardrobe_service.dart';
import '../widgets/floating_message.dart';
import '../widgets/shimmer_loading.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;
  double _animatedTotal = 0.0;
  WardrobeCategory? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // When switching to statistics tab, animate the total
        _animateTotal();
      }
    });
  }
  
  void _animateTotal() {
    final wardrobeService = Provider.of<WardrobeService>(context, listen: false);
    final targetTotal = wardrobeService.totalSpent;
    
    // Reset animation
    _animatedTotal = 0.0;
    setState(() {});
    
    // Animate to target
    const duration = Duration(milliseconds: 1500);
    const steps = 60;
    final stepValue = targetTotal / steps;
    final stepDuration = duration ~/ steps;
    
    int step = 0;
    void updateValue() {
      if (step < steps && mounted) {
        setState(() {
          _animatedTotal = (stepValue * (step + 1)).clamp(0.0, targetTotal);
        });
        step++;
        Future.delayed(stepDuration, updateValue);
      } else if (mounted) {
        setState(() {
          _animatedTotal = targetTotal;
        });
      }
    }
    updateValue();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Wardrobe',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wardrobe'),
            Tab(text: 'Statistics'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWardrobeView(),
          _buildStatisticsView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: const Color(AppConstants.primaryColor),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildWardrobeView() {
    return Consumer<WardrobeService>(
      builder: (context, wardrobeService, child) {
        if (wardrobeService.isLoading) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: 9, // Show 9 shimmer items
              itemBuilder: (context, index) {
                return const WardrobeItemShimmer();
              },
            ),
          );
        }

        final items = wardrobeService.wardrobeItems;
        
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.checkroom,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No items in wardrobe',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add items',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildWardrobeItemCard(item);
            },
          ),
        );
      },
    );
  }

  Widget _buildWardrobeItemCard(WardrobeItem item) {
    return GestureDetector(
      onLongPress: () => _showDeleteDialog(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Image
              Builder(
                builder: (context) {
                  // Check if it's a URL
                  if (item.imageUrl.startsWith('http://') || item.imageUrl.startsWith('https://')) {
                    return Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading network image: $error');
                        print('Image URL: ${item.imageUrl}');
                        return Container(
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 32),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Failed to load image',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const ImageShimmer();
                      },
                    );
                  } else {
                    // Local file path (shouldn't happen if everything is in Firebase)
                    final file = File(item.imageUrl);
                    if (file.existsSync()) {
                      return Image.file(
                        file,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading file image: $error');
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.error, color: Colors.red),
                          );
                        },
                      );
                    } else {
                      // File doesn't exist
                      print('Image file not found: ${item.imageUrl}');
                      return Container(
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Image not found',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
              ),
              // Debug: Show image URL (temporary for debugging)
              if (item.imageUrl.isEmpty || (!item.imageUrl.startsWith('http') && !File(item.imageUrl).existsSync()))
                Positioned.fill(
                  child: Container(
                    color: Colors.red.shade100,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning, color: Colors.red, size: 24),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              'No image',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                color: Colors.red.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Category badge
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.category.icon, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        item.category.displayName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Delete button
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _showDeleteDialog(item),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Price badge
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${item.price.toStringAsFixed(0)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsView() {
    return Consumer<WardrobeService>(
      builder: (context, wardrobeService, child) {
        final totalSpent = wardrobeService.totalSpent;
        final spendingByCategory = wardrobeService.spendingByCategory;
        
        // Initialize animation on first build
        if (_animatedTotal == 0.0 && totalSpent > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _animateTotal();
          });
        }
        
        if (wardrobeService.wardrobeItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No statistics yet',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add items to see spending statistics',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total spent card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFE9ECD), Color(0xFFE91E63)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spent',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_animatedTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${wardrobeService.wardrobeItems.length} items',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Donut chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Spending by Category',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedCategory != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(AppConstants.primaryColor)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedCategory!.icon,
                              size: 16,
                              color: const Color(AppConstants.primaryColor),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _selectedCategory!.displayName,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(AppConstants.primaryColor),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: _buildDonutChart(spendingByCategory, totalSpent),
              ),
              const SizedBox(height: 24),
              
              // Category breakdown
              Text(
                'Category Breakdown',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...spendingByCategory.entries.map((entry) {
                final percentage = (entry.value / totalSpent * 100);
                return _buildCategoryStatCard(entry.key, entry.value, percentage);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDonutChart(Map<WardrobeCategory, double> spending, double total) {
    if (spending.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      );
    }

    final colors = [
      const Color(0xFFFE9ECD),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
    ];

    int colorIndex = 0;
    final List<WardrobeCategory> categoryOrder = spending.keys.toList();
    final pieChartData = spending.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = colors[colorIndex % colors.length];
      final category = entry.key;
      final isSelected = _selectedCategory == category;
      colorIndex++;
      return PieChartSectionData(
        value: entry.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        color: color,
        radius: isSelected ? 70 : 60,
        titleStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return GestureDetector(
      onTap: () {
        // Reset selection on tap outside
        setState(() {
          _selectedCategory = null;
        });
      },
      child: PieChart(
        PieChartData(
          sections: pieChartData,
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          startDegreeOffset: -90,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                final touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                if (touchedIndex >= 0 && touchedIndex < categoryOrder.length) {
                  setState(() {
                    _selectedCategory = categoryOrder[touchedIndex];
                  });
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryStatCard(WardrobeCategory category, double amount, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              category.icon,
              color: const Color(AppConstants.primaryColor),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.displayName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${amount.toStringAsFixed(2)} • ${percentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(AppConstants.primaryColor),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    XFile? selectedImage;
    WardrobeCategory? selectedCategory;
    final priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Add Item to Wardrobe',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image picker
                GestureDetector(
                  onTap: () => _showImageSourceDialog(context, (image) {
                    setState(() => selectedImage = image);
                  }),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add image',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Category selector
                Text(
                  'Category',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WardrobeCategory.values.map((category) {
                    final isSelected = selectedCategory == category;
                    return GestureDetector(
                      onTap: () => setState(() => selectedCategory = category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(AppConstants.primaryColor)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(AppConstants.primaryColor)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              category.displayName,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Price input
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: GoogleFonts.spaceGrotesk(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.spaceGrotesk()),
            ),
            ElevatedButton(
              onPressed: selectedImage != null && selectedCategory != null && priceController.text.isNotEmpty
                  ? () async {
                      final price = double.tryParse(priceController.text);
                      if (price == null || price < 0) {
                        FloatingMessage.show(
                          context,
                          message: 'Please enter a valid price',
                          icon: Icons.error_outline,
                          backgroundColor: Colors.red,
                          iconColor: Colors.white,
                        );
                        return;
                      }

                      final wardrobeService = Provider.of<WardrobeService>(context, listen: false);
                      final item = WardrobeItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        imageUrl: selectedImage!.path,
                        category: selectedCategory!,
                        price: price,
                        createdAt: DateTime.now(),
                      );

                      await wardrobeService.addItem(item);
                      Navigator.pop(context);
                      
                      FloatingMessage.show(
                        context,
                        message: 'Item added to wardrobe',
                        icon: Icons.check_circle,
                        backgroundColor: Colors.green,
                        iconColor: Colors.white,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
              ),
              child: Text('Add', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog(BuildContext context, Function(XFile) onImageSelected) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    onImageSelected(image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    onImageSelected(image);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteDialog(WardrobeItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this item?',
              style: GoogleFonts.spaceGrotesk(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '\$${item.price.toStringAsFixed(2)} will be automatically deducted from your total spent.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.spaceGrotesk()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final wardrobeService = Provider.of<WardrobeService>(context, listen: false);
      final itemPrice = item.price;
      await wardrobeService.removeItem(item);
      
      // If on statistics tab, re-animate the total to reflect the deduction
      if (_tabController.index == 1) {
        _animateTotal();
      }
      
      FloatingMessage.show(
        context,
        message: 'Item deleted. \$${itemPrice.toStringAsFixed(2)} deducted from total.',
        icon: Icons.delete_outline,
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
    }
  }
}
