import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart' as custom;
import 'image_viewer_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isGridView = true;
  int _crossAxisCount = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          if (_isGridView)
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                setState(() {
                  _crossAxisCount = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 2, child: Text('2 Columns')),
                const PopupMenuItem(value: 3, child: Text('3 Columns')),
                const PopupMenuItem(value: 4, child: Text('4 Columns')),
                const PopupMenuItem(value: 5, child: Text('5 Columns')),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<custom.ImageProvider>().refreshImages();
            },
          ),
        ],
      ),
      body: Consumer<custom.ImageProvider>(
        builder: (context, imageProvider, child) {
          if (imageProvider.selectedDirectory == null) {
            return _buildWelcomeScreen(context);
          }

          if (imageProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (imageProvider.images.isEmpty) {
            return _buildEmptyState(context);
          }

          return _isGridView
              ? _buildGridView(imageProvider.images)
              : _buildListView(imageProvider.images);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<custom.ImageProvider>().selectDirectory();
        },
        child: const Icon(Icons.folder_open),
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              Icons.photo_library_outlined,
              size: 100,
              color: Colors.grey[400]
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Photo Gallery',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a folder to view your images',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600]
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<custom.ImageProvider>().selectDirectory();
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Select Folder'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              Icons.image_not_supported_outlined,
              size: 80,
              color: Colors.grey[400]
          ),
          const SizedBox(height: 16),
          Text(
            'No images found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This folder doesn\'t contain any image files',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600]
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<File> images) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: MasonryGridView.count(
        crossAxisCount: _crossAxisCount,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return _buildImageTile(images[index], index);
        },
      ),
    );
  }

  Widget _buildListView(List<File> images) {
    return ListView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return _buildListTile(images[index], index);
      },
    );
  }

  Widget _buildImageTile(File imageFile, int index) {
    return GestureDetector(
      onTap: () => _openImageViewer(imageFile, index),
      child: Hero(
        tag: 'image_$index',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            imageFile,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                color: Colors.grey[300],
                child: Icon(Icons.broken_image, color: Colors.grey[600]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(File imageFile, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            imageFile,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              );
            },
          ),
        ),
        title: Text(
          imageFile.path.split('/').last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: FutureBuilder<FileStat>(
          future: imageFile.stat(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final stat = snapshot.data!;
              return Text(
                '${_formatFileSize(stat.size)} • ${_formatDate(stat.modified)}',
                style: const TextStyle(fontSize: 12),
              );
            }
            return const Text('Loading...');
          },
        ),
        onTap: () => _openImageViewer(imageFile, index),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDelete(imageFile);
            }
          },
        ),
      ),
    );
  }

  void _openImageViewer(File imageFile, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageFile: imageFile,
          heroTag: 'image_$index',
        ),
      ),
    );
  }

  void _confirmDelete(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<custom.ImageProvider>().deleteImage(imageFile);
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}