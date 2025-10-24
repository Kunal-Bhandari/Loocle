import 'package:flutter/material.dart';
import '../screens/full_screen_gallery.dart';
import 'photo_tile.dart';

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

    final double spacing = _getSpacing(columns);
    final double padding = _getPadding(columns);

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return PhotoTile(
          imageUrl: imageUrls[index],
          onTap: () => _openFullScreen(context, index),
          isSmall: columns > 4,
          showDetails: columns <= 3,
        );
      },
    );
  }

  double _getSpacing(int columns){
    if (columns <= 2) return 8;
    if (columns <= 4) return 4;
    if (columns <= 6) return 2;
    return 1;
  }

  double _getPadding(int columns){
    if (columns <= 2) return 8;
    if (columns <= 4) return 4;
    if (columns <= 6) return 2;
    return 1;
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