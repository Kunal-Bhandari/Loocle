import 'package:flutter/material.dart';
import 'network_image_widget.dart';

class PhotoTile extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final bool isSmall;
  final bool showDetails;

  const PhotoTile({
    Key? key,
    required this.imageUrl,
    required this.onTap,
    this.isSmall = false,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filename = imageUrl.split('/').last;

    return GestureDetector(
      onTap: onTap,
      child: isSmall ? _buildCompactTile() : _buildNormalTile(filename),
    );
  }

  Widget _buildCompactTile() {
    // Simplified tile for many columns (5+ columns)
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: NetworkImageWidget(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildNormalTile(String filename){
    return Card(
          elevation: isSmall ? 2 : 4,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmall? 4: 8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isSmall ? 4: 8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkImageWidget(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
            ),
            if (showDetails)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding:const EdgeInsets.all(8),
                  child: Text(
                    filename,
                    style:const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  )
              )
              ],
            )
            
          ),
        );
  }
}