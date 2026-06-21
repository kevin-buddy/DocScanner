import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for OCR (Optical Character Recognition) operations
class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from an image file
  Future<String> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final StringBuffer extractedText = StringBuffer();
      
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText.writeln(line.text);
        }
        extractedText.writeln(); // Add spacing between blocks
      }
      
      return extractedText.toString().trim();
    } catch (e) {
      throw Exception('Failed to extract text: $e');
    }
  }

  /// Extract text with bounding box information
  Future<List<TextBlock>> extractTextWithBlocks(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.blocks;
    } catch (e) {
      throw Exception('Failed to extract text with blocks: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
