import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

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

class PhotoGalleryScreen extends StatefulWidget {
  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  // Replace with your actual local IP address
  final String baseUrl = 'http://192.168.1.10:8000';

  List<String> imageUrls = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchImageList();
  }

  Future<void> fetchImageList() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await http.get(Uri.parse(baseUrl)).timeout(
        Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        // Parse HTML response to extract image file names
        String htmlContent = response.body;
        List<String> images = extractImageUrls(htmlContent);

        setState(() {
          imageUrls = images;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load images. Status: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  List<String> extractImageUrls(String htmlContent) {
    List<String> imageUrls = [];

    // Common image extensions
    List<String> imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];

    // Simple regex to find href attributes
    RegExp hrefRegex = RegExp(r'href="([^"]*)"');
    Iterable<RegExpMatch> matches = hrefRegex.allMatches(htmlContent);

    for (RegExpMatch match in matches) {
      String? href = match.group(1);
      if (href != null) {
        // Check if the href is an image file
        String lowerHref = href.toLowerCase();
        for (String ext in imageExtensions) {
          if (lowerHref.endsWith(ext)) {
            imageUrls.add('$baseUrl/$href');
            break;
          }
        }
      }
    }

    return imageUrls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Gallery'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchImageList,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
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
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchImageList,
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : imageUrls.isEmpty
          ? Center(
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
      )
          : GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImageView(
                    imageUrls: imageUrls,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Card(
              elevation: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrls[index],
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
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FullScreenImageView extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  FullScreenImageView({required this.imageUrls, required this.initialIndex});

  @override
  _FullScreenImageViewState createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
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
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}