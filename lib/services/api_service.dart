import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // for debugPrint
import '../utils/app_constants.dart';

class ApiService {
  /// Upload image file to RapidAPI Cartoon Yourself and return cartoon image URL (or null)
  static Future<String?> cartoonifyImage(File imageFile) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.cartoonEndpoint}');

      // Prepare request
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'x-rapidapi-key': AppConstants.apiKey,
        'x-rapidapi-host': AppConstants.apiHost,
        'Content-Type': 'application/x-www-form-urlencoded',
      });

      // Attach file
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final data = json.decode(body);

        // Check typical RapidAPI response
        if (data is Map && data['url'] != null) {
          return data['url'] as String;
        }

        if (data['output_url'] != null) {
          return data['output_url'] as String;
        }

        return null;
      } else {
        debugPrint('RapidAPI error ${streamed.statusCode}: $body');
        return null;
      }
    } catch (e) {
      debugPrint('API Error: $e');
      return null;
    }
  }
}
