import 'package:flutter/material.dart';
import '../widgets/full_screen_image_view.dart';

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