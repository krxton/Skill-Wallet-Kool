// lib/services/youtube_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeService {
  // static const String _baseUrl =
  //     'http://192.168.1.58:3000'; // 👈 เปลี่ยนเป็น IP Backend
  static const String _baseUrl = 'http://127.0.0.1:3000';

  static Future<String?> getDirectVideoUrl(String videoId) async {
    try {
      final youtubeUrl = 'https://youtu.be/$videoId';
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/get-direct-url?url=${Uri.encodeComponent(youtubeUrl)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['directUrl'] as String?;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting video URL: $e');
      return null;
    }
  }
}
