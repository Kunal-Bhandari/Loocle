import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../config/gallery_config.dart';
import '../services/photo_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom;
import '../widgets/empty_state_widget.dart';
import '../widgets/photo_grid.dart';
import '../screens/full_screen_gallery.dart';

class PhotoGalleryScreen extends StatefulWidget {
  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<ImageData> allImages = [];
  Map<String, List<ImageData>> groupedImages = {};
  bool isLoading = true;
  String errorMessage = '';
  
  final List<int> gridColumnOptions = [2, 3, 4, 5, 6, 8];
  int currentGridIndex = 0;
  
  String debugInfo = '';

  int get gridColumns => gridColumnOptions[currentGridIndex];

  @override
  void initState() {
    super.initState();
    debugInfo = 'Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}\n';
    debugInfo += 'Target URL: ${GalleryConfig.baseUrl}\n';
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      debugInfo += 'Attempting to connect...\n';
      final images = await PhotoService.fetchImageUrls();
      debugInfo += 'Found ${images.length} images\n';

      // Group images by date
      final grouped = <String, List<ImageData>>{};
      for (var image in images) {
        final dateKey = DateFormat('d MMMM yyyy').format(image.modifiedDate);
        grouped.putIfAbsent(dateKey, () => []).add(image);
      }

      setState(() {
        allImages = images;
        groupedImages = grouped;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage =
            'Connection Failed!\n\n$debugInfo\nError: $e\n\nTroubleshooting:\n'
            '1. Make sure Python server is running\n'
            '2. Use --bind 0.0.0.0 flag\n'
            '3. Check firewall settings\n'
            '4. Verify IP address is correct\n'
            '5. Test in phone browser first';
        isLoading = false;
      });
    }
  }

  void _cycleGridLayout() {
    setState(() {
      currentGridIndex = (currentGridIndex + 1) % gridColumnOptions.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Gallery'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.grid_view),
                onPressed: _cycleGridLayout,
                tooltip: 'Change grid layout (${gridColumns} columns)',
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$gridColumns',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadImages,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return LoadingWidget();
    }

    if (errorMessage.isNotEmpty) {
      return custom.ErrorWidget(
        message: errorMessage,
        onRetry: _loadImages,
      );
    }

    if (allImages.isEmpty) {
      return EmptyStateWidget();
    }

    return _buildGroupedGallery();
  }

  Widget _buildGroupedGallery() {
    final sortedDates = groupedImages.keys.toList();
    
    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final images = groupedImages[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            // Grid of images for this date
            _buildDateGrid(images),
          ],
        );
      },
    );
  }

  Widget _buildDateGrid(List<ImageData> images) {
    final double spacing = gridColumns > 4 ? 2 : 4;
    final double padding = gridColumns > 4 ? 2 : 8;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return GestureDetector(
          onTap: () {
            // Find the index in allImages list
            final globalIndex = allImages.indexWhere((img) => img.url == image.url);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenGallery(
                  imageUrls: allImages.map((img) => img.url).toList(),
                  initialIndex: globalIndex,
                ),
              ),
            );
          },
          child: Card(
            elevation: gridColumns > 4 ? 1 : 2,
            margin: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(gridColumns > 4 ? 4 : 8),
              child: Image.network(
                image.url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}