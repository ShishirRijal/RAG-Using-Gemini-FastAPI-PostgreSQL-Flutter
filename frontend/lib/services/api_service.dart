import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class UploadResult {
  final bool success;
  final String? fileName;
  final String? errorMessage;

  UploadResult({required this.success, this.fileName, this.errorMessage});
}

class QueryResult {
  final bool success;
  final String? answer;
  final List<Map<String, String>>? citations;
  final String? errorMessage;

  QueryResult({
    required this.success,
    this.answer,
    this.citations,
    this.errorMessage,
  });
}

class ApiService {
  // Use a getter for the base URL in case it needs to be dynamic later
  final String _baseUrl = 'http://localhost:8000';
  String get baseUrl => _baseUrl;

  Future<UploadResult> uploadPdf(File file) async {
    try {
      String fileName = path.basename(file.path);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload/'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // You might parse a success message or file identifier from the body
        return UploadResult(success: true, fileName: fileName);
      } else {
        // Attempt to parse error message from response body if available
        String errorDetail = 'Unknown error';
        try {
          final errorJson = json.decode(responseBody);
          if (errorJson != null && errorJson['detail'] != null) {
            errorDetail = errorJson['detail'];
          }
        } catch (_) {
          // Ignore parsing errors, use default error message
        }
        return UploadResult(
          success: false,
          errorMessage: 'HTTP ${response.statusCode}: $errorDetail',
        );
      }
    } catch (e) {
      return UploadResult(success: false, errorMessage: 'Network Error: $e');
    }
  }

  Future<QueryResult> query(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/query/?query=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        List<Map<String, String>> parsedCitations = [];
        if (data['citations'] != null) {
          parsedCitations =
              (data['citations'] as List)
                  .map(
                    (c) => {
                      'url': c['url']?.toString() ?? '',
                      'title': c['title']?.toString() ?? 'Unknown Source',
                    },
                  )
                  .toList();
        }

        return QueryResult(
          success: true,
          answer: data['answer']?.toString(),
          citations: parsedCitations,
        );
      } else {
        String errorDetail = 'Unknown error';
        try {
          final errorJson = json.decode(response.body);
          if (errorJson != null && errorJson['detail'] != null) {
            errorDetail = errorJson['detail'];
          }
        } catch (_) {
          // Ignore parsing errors
        }
        return QueryResult(
          success: false,
          errorMessage: 'HTTP ${response.statusCode}: $errorDetail',
        );
      }
    } catch (e) {
      return QueryResult(success: false, errorMessage: 'Network Error: $e');
    }
  }
}
