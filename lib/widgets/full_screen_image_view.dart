import 'package:flutter/material.dart';
import 'network_image_widget.dart';

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