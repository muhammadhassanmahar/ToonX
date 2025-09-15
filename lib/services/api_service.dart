import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_constants.dart';

class ApiService {
  /// Upload image file to DeepAI CartoonGAN and return cartoon image URL (or null)
  static Future<String?> cartoonifyImage(File imageFile) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/cartoon-gan');
      final request = http.MultipartRequest('POST', uri);
      request.headers['api-key'] = AppConstants.apiKey;

      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final data = json.decode(body);
        // DeepAI typically returns 'output_url'
        if (data is Map && data['output_url'] != null) {
          return data['output_url'] as String;
        }
        // Defensive: sometimes model returns nested output
        if (data['output'] != null && data['output'] is List && data['output'].isNotEmpty) {
          final candidate = data['output'][0];
          if (candidate is Map && candidate['url'] != null) return candidate['url'] as String;
        }
        return null;
      } else {
        // print server error for debugging
        print('DeepAI error ${streamed.statusCode}: $body');
        return null;
      }
    } catch (e) {
      print('API Error: $e');
      return null;
    }
  }
}
