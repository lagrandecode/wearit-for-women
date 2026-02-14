import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_constants.dart';
import '../models/planned_outfit.dart';
import '../services/planner_service.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/floating_message.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<XFile> _pendingImages = []; // Images waiting for time selection
  bool _isGridView = false; // Toggle between list and grid view
  late TabController _tabController;
  int _currentTabIndex = 0; // 0 = Upcoming, 1 = History

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedDate == null) {
      FloatingMessage.show(
        context,
        message: 'Please select a date first',
        icon: Icons.info_outline,
        backgroundColor: Colors.orange,
        iconColor: Colors.white,
      );
      return;
    }

    try {
      // Allow multiple image selection (iOS 14+ / Android)
      List<XFile> images = [];
      
      if (source == ImageSource.gallery) {
        // Try multiple selection first (available on iOS 14+ and Android)
        try {
          images = await _picker.pickMultiImage(
            imageQuality: 85,
          );
        } catch (e) {
          // Fallback to single image if multiple selection not supported
          final XFile? image = await _picker.pickImage(
            source: source,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          if (image != null) {
            images = [image];
          }
        }
      } else {
        // Camera - single image only
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        if (image != null) {
          images = [image];
        }
      }

      if (images.isNotEmpty) {
        setState(() {
          _pendingImages.addAll(images);
        });
        
        // If time is already selected, save immediately
        if (_selectedTime != null) {
          _saveOutfit();
        } else {
          // Otherwise, prompt for time
          _selectTime(context);
        }
      }
    } catch (e) {
      FloatingMessage.show(
        context,
        message: 'Failed to pick image: $e',
        icon: Icons.error_outline,
        backgroundColor: Colors.red,
        iconColor: Colors.white,
      );
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      
      // Save outfit if we have pending images
      if (_pendingImages.isNotEmpty) {
        _saveOutfit();
      }
    }
  }
  
  Future<void> _saveOutfit() async {
    if (_selectedDate == null || _selectedTime == null || _pendingImages.isEmpty) {
      return;
    }

    final plannerService = Provider.of<PlannerService>(context, listen: false);
    final dateKey = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    // Generate unique notification ID based on date and time
    // Must be within 32-bit integer range: [-2^31, 2^31 - 1]
    // Use hash of date and time to ensure uniqueness while staying within range
    final dateTimeHash = dateKey.millisecondsSinceEpoch.hashCode;
    final timeHash = (_selectedTime!.hour * 60 + _selectedTime!.minute).hashCode;
    final notificationId = (dateTimeHash + timeHash).abs() % 2147483647; // Max 32-bit int

    final outfit = PlannedOutfit.fromXFiles(
      date: dateKey,
      time: _selectedTime!,
      images: List.from(_pendingImages),
      notificationId: notificationId,
    );

    // Save using service (handles persistence and notifications)
    await plannerService.addOutfit(outfit);
    
    setState(() {
      _pendingImages.clear();
    });
    
    FloatingMessage.show(
      context,
      message: 'Outfit planned for ${outfit.formattedTime}',
      icon: Icons.check_circle,
      backgroundColor: Colors.green,
      iconColor: Colors.white,
    );
  }

  Future<void> _showImageSourceDialog() async {
    if (_selectedDate == null) {
      FloatingMessage.show(
        context,
        message: 'Please select a date first',
        icon: Icons.info_outline,
        backgroundColor: Colors.orange,
        iconColor: Colors.white,
      );
      return;
    }

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
                subtitle: const Text('Single photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select multiple images'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null; // Reset time when date changes
        _pendingImages.clear(); // Clear pending images
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  /// Helper widget to display image from path (local) or URL (Firebase)
  Widget _buildOutfitImage(String imagePath, {double? width, double? height}) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Firebase Storage URL
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.error, color: Colors.red),
          );
        },
      );
    } else {
      // Local file path
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.error, color: Colors.red),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Planner',
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
            Tab(text: 'Upcoming'),
            Tab(text: 'History'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingView(),
          _buildHistoryView(),
        ],
      ),
    );
  }

  Widget _buildUpcomingView() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Plan your outfits',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Select a date and time\n2. Upload clothes you want to wear\n3. Get notified when it\'s time to wear your outfit',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date selection
            ElevatedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : '${_getDayName(_selectedDate!)}, ${_formatDate(_selectedDate!)}',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time selection (only if date is selected)
            if (_selectedDate != null)
              ElevatedButton.icon(
                onPressed: () => _selectTime(context),
                icon: const Icon(Icons.access_time),
                label: Text(
                  _selectedTime == null
                      ? 'Select Time'
                      : _selectedTime!.format(context),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Upload button (only if date is selected)
            if (_selectedDate != null)
              ElevatedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(
                  'Upload Clothes',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            
            // Pending images indicator
            if (_pendingImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_pendingImages.length} image(s) waiting. ${_selectedTime == null ? 'Please select a time.' : 'Click "Upload Clothes" again to add more or wait for auto-save.'}',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.orange.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Planned outfits list - using Consumer to listen to changes
            Consumer<PlannerService>(
              builder: (context, plannerService, child) {
                final plannedOutfits = plannerService.plannedOutfits;
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                
                // Filter to show only upcoming outfits (today and future)
                final Map<DateTime, List<PlannedOutfit>> upcomingOutfits = {};
                for (var entry in plannedOutfits.entries) {
                  final dateKey = entry.key;
                  // Include today and future dates
                  if (dateKey.isAfter(today.subtract(const Duration(days: 1)))) {
                    // Filter outfits to only show those with future scheduled times
                    final futureOutfits = entry.value.where((outfit) {
                      final scheduledDateTime = outfit.scheduledDateTime;
                      return scheduledDateTime.isAfter(now);
                    }).toList();
                    if (futureOutfits.isNotEmpty) {
                      upcomingOutfits[dateKey] = futureOutfits;
                    }
                  }
                }
                
                // Filter outfits for selected date if date is selected
                final Map<DateTime, List<PlannedOutfit>> displayOutfits;
                if (_selectedDate != null) {
                  final dateKey = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                  );
                  final outfitsForDate = plannerService.getOutfitsForDate(_selectedDate!);
                  if (outfitsForDate != null && outfitsForDate.isNotEmpty) {
                    // Only show if date is today or future
                    if (dateKey.isAfter(today.subtract(const Duration(days: 1)))) {
                      displayOutfits = {dateKey: outfitsForDate};
                    } else {
                      displayOutfits = {};
                    }
                  } else {
                    displayOutfits = {};
                  }
                } else {
                  displayOutfits = upcomingOutfits;
                }
                
                if (displayOutfits.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDate != null ? 'Planned Outfits' : 'All Planned Outfits',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                          tooltip: _isGridView ? 'Switch to list view' : 'Switch to grid view',
                          onPressed: () {
                            setState(() {
                              _isGridView = !_isGridView;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Display planned outfits grouped by date
                    ...displayOutfits.entries.map((entry) {
              final date = entry.key;
              final outfits = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '${_getDayName(date)}, ${_formatDate(date)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  // Group outfits by time - horizontal list
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: outfits.length,
                      itemBuilder: (context, outfitIndex) {
                        final outfit = outfits[outfitIndex];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      outfit.formattedTime,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _isGridView
                                  ? SizedBox(
                                      width: 200,
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: 0.75,
                                        ),
                                        itemCount: outfit.imagePaths.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Stack(
                                                children: [
                                                  _buildOutfitImage(
                                                    outfit.imagePaths[index],
                                                  ),
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: IconButton(
                                                      icon: const Icon(Icons.close, color: Colors.white),
                                                      iconSize: 20,
                                                      onPressed: () async {
                                                        // Remove image using service
                                                        final plannerService = Provider.of<PlannerService>(context, listen: false);
                                                        await plannerService.removeImageFromOutfit(date, outfit, index);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : SizedBox(
                                      height: 150,
                                      width: 150,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: outfit.imagePaths.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: Container(
                                              width: 150,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Stack(
                                                  children: [
                                                    _buildOutfitImage(
                                                      outfit.imagePaths[index],
                                                    ),
                                                    Positioned(
                                                      top: 4,
                                                      right: 4,
                                                      child: IconButton(
                                                        icon: const Icon(Icons.close, color: Colors.white),
                                                        onPressed: () async {
                                                          // Remove image using service
                                                          final plannerService = Provider.of<PlannerService>(context, listen: false);
                                                          await plannerService.removeImageFromOutfit(date, outfit, index);
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      );
  }

  Widget _buildHistoryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Consumer<PlannerService>(
        builder: (context, plannerService, child) {
          final plannedOutfits = plannerService.plannedOutfits;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          // Filter to show only past outfits
          final Map<DateTime, List<PlannedOutfit>> historyOutfits = {};
          for (var entry in plannedOutfits.entries) {
            final dateKey = entry.key;
            // Include only past dates (before today)
            if (dateKey.isBefore(today)) {
              historyOutfits[dateKey] = entry.value;
            } else if (dateKey.year == today.year && 
                       dateKey.month == today.month && 
                       dateKey.day == today.day) {
              // For today, only show outfits with past scheduled times
              final pastOutfits = entry.value.where((outfit) {
                final scheduledDateTime = outfit.scheduledDateTime;
                return scheduledDateTime.isBefore(now);
              }).toList();
              if (pastOutfits.isNotEmpty) {
                historyOutfits[dateKey] = pastOutfits;
              }
            }
          }
          
          if (historyOutfits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No history yet',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your past planned outfits will appear here',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Sort dates in descending order (most recent first)
          final sortedDates = historyOutfits.keys.toList()
            ..sort((a, b) => b.compareTo(a));
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Outfit History',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                    tooltip: _isGridView ? 'Switch to list view' : 'Switch to grid view',
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Display historical outfits grouped by date
              ...sortedDates.map((date) {
                final outfits = historyOutfits[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '${_getDayName(date)}, ${_formatDate(date)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    // Group outfits by time - horizontal list
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: outfits.length,
                        itemBuilder: (context, outfitIndex) {
                          final outfit = outfits[outfitIndex];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        outfit.formattedTime,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _isGridView
                                    ? SizedBox(
                                        width: 200,
                                        child: GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                            childAspectRatio: 0.75,
                                          ),
                                          itemCount: outfit.imagePaths.length,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Stack(
                                                  children: [
                                                    _buildOutfitImage(
                                                      outfit.imagePaths[index],
                                                    ),
                                                    Positioned(
                                                      top: 4,
                                                      right: 4,
                                                      child: IconButton(
                                                        icon: const Icon(Icons.close, color: Colors.white),
                                                        iconSize: 20,
                                                        onPressed: () async {
                                                          final plannerService = Provider.of<PlannerService>(context, listen: false);
                                                          await plannerService.removeImageFromOutfit(date, outfit, index);
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : SizedBox(
                                        height: 150,
                                        width: 150,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: outfit.imagePaths.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: Container(
                                                width: 150,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Stack(
                                                    children: [
                                                      _buildOutfitImage(
                                                        outfit.imagePaths[index],
                                                      ),
                                                      Positioned(
                                                        top: 4,
                                                        right: 4,
                                                        child: IconButton(
                                                          icon: const Icon(Icons.close, color: Colors.white),
                                                          onPressed: () async {
                                                            final plannerService = Provider.of<PlannerService>(context, listen: false);
                                                            await plannerService.removeImageFromOutfit(date, outfit, index);
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
