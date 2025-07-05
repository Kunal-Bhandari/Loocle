import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart' as custom;

class ImageViewerScreen extends StatefulWidget {
  final File imageFile;
  final String heroTag;

  const ImageViewerScreen({
    super.key,
    required this.imageFile,
    required this.heroTag,
  });

  @override
  _ImageViewerScreenState createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  bool _showAppBar = true;
  final PhotoViewController _photoViewController = PhotoViewController();

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showAppBar ? _buildAppBar() : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showAppBar = !_showAppBar;
          });
        },
        child: Hero(
          tag: widget.heroTag,
          child: PhotoView(
            imageProvider: FileImage(widget.imageFile),
            controller: _photoViewController,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4.0,
            initialScale: PhotoViewComputedScale.contained,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null ? 0 : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                color: Colors.white,
              ),
            ),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _showAppBar ? _buildBottomBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black54,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        widget.imageFile.path.split('/').last,
        style: const TextStyle(fontSize: 16),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showImageInfo,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _confirmDelete,
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'zoom_fit',
              child: Row(
                children: [
                  Icon(Icons.fit_screen, color: Colors.black54),
                  SizedBox(width: 8),
                  Text('Fit to Screen'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'zoom_fill',
              child: Row(
                children: [
                  Icon(Icons.fullscreen, color: Colors.black54),
                  SizedBox(width: 8),
                  Text('Fill Screen'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'zoom_original',
              child: Row(
                children: [
                  Icon(Icons.crop_original, color: Colors.black54),
                  SizedBox(width: 8),
                  Text('Original Size'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'zoom_fit':
                _photoViewController.updateMultiple(scale: 1.0);
                break;
              case 'zoom_fill':
                _photoViewController.updateMultiple(scale: 2.0);
                break;
              case 'zoom_original':
                _photoViewController.updateMultiple(scale: 1.0);
                break;
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomButton(
              icon: Icons.zoom_in,
              label: 'Zoom In',
              onPressed: () {
                final currentScale = _photoViewController.scale;
                if (currentScale != null) {
                  _photoViewController.updateMultiple(scale: currentScale * 1.5);
                }
              },
            ),
            _buildBottomButton(
              icon: Icons.zoom_out,
              label: 'Zoom Out',
              onPressed: () {
                final currentScale = _photoViewController.scale;
                if (currentScale != null) {
                  _photoViewController.updateMultiple(scale: currentScale / 1.5);
                }
              },
            ),
            _buildBottomButton(
              icon: Icons.refresh,
              label: 'Reset',
              onPressed: () {
                _photoViewController.updateMultiple(scale: 1.0);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  void _showImageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Information'),
        content: FutureBuilder<FileStat>(
          future: widget.imageFile.stat(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return const Text('Error loading file information');
            }

            final stat = snapshot.data!;
            final fileName = widget.imageFile.path.split('/').last;
            final filePath = widget.imageFile.path;
            final fileSize = _formatFileSize(stat.size);
            final dateModified = _formatDateTime(stat.modified);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('Name:', fileName),
                _buildInfoRow('Size:', fileSize),
                _buildInfoRow('Modified:', dateModified),
                const SizedBox(height: 8),
                const Text('Path:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  filePath,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await context.read<custom.ImageProvider>().deleteImage(widget.imageFile);
                Navigator.pop(context); // Close image viewer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete image')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}