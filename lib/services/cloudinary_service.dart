import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dldpbacf5';
  static const String _uploadPreset = 'echothread_upload';

  /// Uploads an image file to Cloudinary and returns the secure URL.
  static Future<String> uploadImage(File file) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = utf8.decode(responseData);
      final decodedData = jsonDecode(responseString);
      return decodedData['secure_url'] as String;
    } else {
      final responseData = await response.stream.toBytes();
      final responseString = utf8.decode(responseData);
      throw Exception('Cloudinary upload failed: $responseString');
    }
  }
}
