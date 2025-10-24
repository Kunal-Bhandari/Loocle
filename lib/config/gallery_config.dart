class GalleryConfig {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const List<String> imageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp'
  ];
  static const Duration requestTimeout = Duration(seconds: 10);
}