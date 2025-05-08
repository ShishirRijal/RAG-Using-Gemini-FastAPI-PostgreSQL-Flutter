import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileService {
  Future<File?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      } else {
        // User cancelled the picker
        return null;
      }
    } catch (e) {
      // Handle or rethrow the exception as needed
      print('Error picking file: $e'); // Log the error
      throw Exception(
        'Failed to pick PDF file: $e',
      ); // Re-throw or return null/error result
    }
  }
}
