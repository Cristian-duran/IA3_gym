import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/correction_response.dart';
import '../utils/constants.dart';

class ApiService {
  Future<CorrectionResponse> sendVideo(
    Uint8List bytes,
    String exercise,
  ) async {
    final uri = Uri.parse('${Constants.baseUrl}/video?exercise=$exercise');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'video',
        bytes,
        filename: '$exercise.mp4',
        contentType: MediaType('video', 'mp4'),
      ));

    final streamed = await req.send().timeout(Constants.httpTimeout);
    if (streamed.statusCode != 200) {
      throw Exception('Error ${streamed.statusCode}');
    }

    final resp = await http.Response.fromStream(streamed);
    final Map<String, dynamic> jsonMap = json.decode(resp.body);
    return CorrectionResponse.fromJson(jsonMap);
  }
}
