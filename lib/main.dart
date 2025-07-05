import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  runApp(PhotoGalleryApp());
}

class PhotoGalleryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PhotoGalleryScreen(),
    );
  }
}

// Configuration class for gallery settings
class GalleryConfig {
  static const String baseUrl = 'http://192.168.1.2:8000';
  static const List<String> imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
  static const Duration requestTimeout = Duration(seconds: 10);
}

// Service class for handling API calls
class PhotoService {
  static Future<List<String>> fetchImageUrls() async {
    try {
      final client = http.Client();

      final response = await client.get(
        Uri.parse(GalleryConfig.baseUrl),
        headers: {
          'User-Agent': 'PhotoGalleryApp/1.0',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Cache-Control': 'no-cache',
        },
      ).timeout(GalleryConfig.requestTimeout);

      if (response.statusCode == 200) {
        return _extractImageUrls(response.body);
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection Failed: $e');
    }
  }

  static List<String> _extractImageUrls(String htmlContent) {
    List<String> imageUrls = [];
    RegExp hrefRegex = RegExp(r'href="([^"]*)"');
    Iterable<RegExpMatch> matches = hrefRegex.allMatches(htmlContent);

    for (RegExpMatch match in matches) {
      String? href = match.group(1);
      if (href != null) {
        String lowerHref = href.toLowerCase();
        for (String ext in GalleryConfig.imageExtensions) {
          if (lowerHref.endsWith(ext)) {
            imageUrls.add('${GalleryConfig.baseUrl}/$href');
            break;
          }
        }
      }
    }
    return imageUrls;
  }
}

// Main gallery screen
class PhotoGalleryScreen extends StatefulWidget {
  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<String> imageUrls = [];
  bool isLoading = true;
  String errorMessage = '';
  int gridColumns = 2; // Default to 2 columns
  String debugInfo = '';

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

      setState(() {
        imageUrls = images;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Connection Failed!\n\n$debugInfo\nError: $e\n\nTroubleshooting:\n1. Make sure Python server is running\n2. Use --bind 0.0.0.0 flag\n3. Check firewall settings\n4. Verify IP address is correct\n5. Test in phone browser first';
        isLoading = false;
      });
    }
  }

  void _toggleGridLayout() {
    setState(() {
      gridColumns = gridColumns == 2 ? 4 : 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Gallery'),
        actions: [
          IconButton(
            icon: Icon(gridColumns == 2 ? Icons.grid_4x4 : Icons.grid_3x3),
            onPressed: _toggleGridLayout,
            tooltip: gridColumns == 2 ? 'Switch to 4 columns' : 'Switch to 2 columns',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
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
      return ErrorWidget(
        message: errorMessage,
        onRetry: _loadImages,
      );
    }

    if (imageUrls.isEmpty) {
      return EmptyStateWidget();
    }

    return PhotoGrid(
      imageUrls: imageUrls,
      columns: gridColumns,
    );
  }
}

// Loading widget component
class LoadingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading images...'),
        ],
      ),
    );
  }
}

// Error widget component
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorWidget({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// Empty state widget component
class EmptyStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No images found in the directory',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// Photo grid component
class PhotoGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int columns;

  const PhotoGrid({
    Key? key,
    required this.imageUrls,
    required this.columns,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: columns == 4 ? 4 : 8,
        mainAxisSpacing: columns == 4 ? 4 : 8,
        childAspectRatio: 1,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return PhotoTile(
          imageUrl: imageUrls[index],
          onTap: () => _openFullScreen(context, index),
          isSmall: columns == 4,
        );
      },
    );
  }

  void _openFullScreen(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenGallery(
          imageUrls: imageUrls,
          initialIndex: index,
        ),
      ),
    );
  }
}

// Individual photo tile component
class PhotoTile extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final bool isSmall;

  const PhotoTile({
    Key? key,
    required this.imageUrl,
    required this.onTap,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSmall ? 2 : 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: NetworkImageWidget(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

// Reusable network image widget with loading and error states
class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const NetworkImageWidget({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
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
            size: fit == BoxFit.cover ? 40 : 64,
          ),
        );
      },
    );
  }
}

// Full-screen gallery component
class FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenGallery({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _FullScreenGalleryState createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          '${currentIndex + 1} of ${widget.imageUrls.length}',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Add share functionality if needed
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return FullScreenImageView(
            imageUrl: widget.imageUrls[index],
          );
        },
      ),
    );
  }
}

// Full-screen image view component
class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      child: Center(
        child: NetworkImageWidget(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}