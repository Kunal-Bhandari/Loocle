import 'package:http/http.dart' as http;
import '../config/gallery_config.dart';
import 'dart:convert';

class PhotoService {
  static Future<List<ImageData>> fetchImageUrls() async {
    try {
      final client = http.Client();

      final response = await client
          .get(
            Uri.parse('${GalleryConfig.baseUrl}/api/images'),
            headers: {
              'User-Agent': 'PhotoGalleryApp/1.0',
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(GalleryConfig.requestTimeout);

      if (response.statusCode == 200) {
        return _parseImageData(response.body);
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection Failed: $e');
    }
  }

  static List<ImageData> _parseImageData(String responseBody) {
    List<ImageData> images = [];
    
    try {
      final Map<String, dynamic> jsonData = json.decode(responseBody);
      final List<dynamic> imageList = jsonData['images'] ?? [];
      
      for (var item in imageList) {
        images.add(ImageData(
          url: '${GalleryConfig.baseUrl}${item['url']}',
          name: item['name'],
          modifiedDate: DateTime.parse(item['modified'] ?? DateTime.now().toIso8601String()),
        ));
      }
    } catch (e) {
      // Fallback to HTML parsing if JSON fails
      return _extractImageUrlsFromHtml(responseBody);
    }
    
    // Sort by date (newest first)
    images.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
    return images;
  }

  static List<ImageData> _extractImageUrlsFromHtml(String htmlContent) {
    List<ImageData> images = [];
    RegExp hrefRegex = RegExp(r'href="([^"]*)"');
    Iterable<RegExpMatch> matches = hrefRegex.allMatches(htmlContent);

    for (RegExpMatch match in matches) {
      String? href = match.group(1);
      if (href != null) {
        String lowerHref = href.toLowerCase();
        for (String ext in GalleryConfig.imageExtensions) {
          if (lowerHref.endsWith(ext)) {
            images.add(ImageData(
              url: '${GalleryConfig.baseUrl}/$href',
              name: href.split('/').last,
              modifiedDate: DateTime.now(), // Default to current date
            ));
            break;
          }
        }
      }
    }
    
    return images;
  }
}

class ImageData {
  final String url;
  final String name;
  final DateTime modifiedDate;

  ImageData({
    required this.url,
    required this.name,
    required this.modifiedDate,
  });
}