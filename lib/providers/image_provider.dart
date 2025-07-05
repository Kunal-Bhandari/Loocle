import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class ImageProvider extends ChangeNotifier {
  List<File> _images = [];
  String? _selectedDirectory;
  bool _isLoading = false;

  List<File> get images => _images;
  String? get selectedDirectory => _selectedDirectory;
  bool get isLoading => _isLoading;

  Future<void> selectDirectory() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if we're on web or mobile platforms where directory selection might not be available
      if (kIsWeb) {
        // Web platform - use file picker
        await _selectFilesFromPicker();
      } else {
        // Try platform detection safely
        bool isMobile = false;
        try {
          isMobile = Platform.isAndroid || Platform.isIOS;
        } catch (e) {
          // If Platform detection fails, assume we need file picker
          await _selectFilesFromPicker();
          return;
        }

        if (isMobile) {
          // Mobile platforms - use file picker
          await _selectFilesFromPicker();
        } else {
          // Desktop platforms - try directory selection
          await _selectDirectoryFromPicker();
        }
      }
    } catch (e) {
      print('Error selecting directory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _selectFilesFromPicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      _images = result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();

      // Get directory from first file
      if (_images.isNotEmpty) {
        _selectedDirectory = path.dirname(_images.first.path);
      }

      // Sort by modification date (newest first)
      _images.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    }
  }

  Future<void> _selectDirectoryFromPicker() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        _selectedDirectory = selectedDirectory;
        await _loadImagesFromDirectory(selectedDirectory);
      }
    } catch (e) {
      // If directory selection fails, fall back to file selection
      print('Directory selection not supported, falling back to file selection');
      await _selectFilesFromPicker();
    }
  }

  Future<void> _loadImagesFromDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      final List<FileSystemEntity> entities = await directory.list().toList();

      _images = entities
          .whereType<File>()
          .where((file) => _isImageFile(file.path))
          .toList();

      // Sort by modification date (newest first)
      _images.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    } catch (e) {
      print('Error loading images: $e');
      _images = [];
    }
  }

  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.tiff']
        .contains(extension);
  }

  Future<void> deleteImage(File imageFile) async {
    try {
      await imageFile.delete();
      _images.remove(imageFile);
      notifyListeners();
    } catch (e) {
      print('Error deleting image: $e');
      rethrow;
    }
  }

  void refreshImages() {
    if (_selectedDirectory != null) {
      _loadImagesFromDirectory(_selectedDirectory!);
    }
  }
}