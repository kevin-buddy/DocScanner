import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/scanned_document.dart';

/// Service for image processing operations
class ImageProcessingService {
  final _uuid = const Uuid();

  /// Apply perspective correction to straighten the document
  Future<File> applyPerspectiveCorrection(
    File imageFile,
    List<Offset> cornerPoints,
  ) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Sort corner points: top-left, top-right, bottom-right, bottom-left
    final sortedPoints = _sortCornerPoints(cornerPoints);
    
    // Calculate dimensions for the output image
    final width = _distance(sortedPoints[0], sortedPoints[1])
        .clamp(_distance(sortedPoints[3], sortedPoints[2]), 
               _distance(sortedPoints[0], sortedPoints[1]));
    
    final height = _distance(sortedPoints[0], sortedPoints[3])
        .clamp(_distance(sortedPoints[1], sortedPoints[2]),
               _distance(sortedPoints[0], sortedPoints[3]));

    // Apply perspective transform
    final transformed = img.copyCrop(
      image,
      x: sortedPoints[0].dx.toInt(),
      y: sortedPoints[0].dy.toInt(),
      width: width.toInt(),
      height: height.toInt(),
    );

    // Save processed image
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/scanned_${_uuid.v4()}.jpg';
    final processedFile = File(outputPath);
    await processedFile.writeAsBytes(img.encodeJpg(transformed));
    
    return processedFile;
  }

  /// Apply filter to enhance document appearance
  Future<File> applyFilter(File imageFile, FilterType filterType) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    img.Image processed;

    switch (filterType) {
      case FilterType.none:
        processed = image;
        break;
      case FilterType.grayscale:
        processed = img.grayscale(image);
        break;
      case FilterType.blackAndWhite:
        processed = _applyBinarization(image);
        break;
      case FilterType.magicColor:
        processed = _applyMagicColor(image);
        break;
      case FilterType.lighten:
        processed = img.adjustColor(image, brightness: 30);
        break;
      case FilterType.darken:
        processed = img.adjustColor(image, brightness: -30);
        break;
    }

    // Save processed image
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/filtered_${_uuid.v4()}.jpg';
    final filteredFile = File(outputPath);
    await filteredFile.writeAsBytes(img.encodeJpg(processed, quality: 95));
    
    return filteredFile;
  }

  /// Apply binarization filter for black and white effect
  img.Image _applyBinarization(img.Image image) {
    final grayscale = img.grayscale(image);
    final threshold = 128;
    
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = pixel.r; // Already grayscale
        
        final newValue = luminance > threshold ? 255 : 0;
        grayscale.setPixelR(x, y, newValue);
        grayscale.setPixelG(x, y, newValue);
        grayscale.setPixelB(x, y, newValue);
      }
    }
    
    return grayscale;
  }

  /// Apply magic color filter (enhances contrast and saturation)
  img.Image _applyMagicColor(img.Image image) {
    // Convert to grayscale first
    var processed = img.grayscale(image);
    
    // Enhance contrast
    processed = img.contrast(processed, contrast: 50);
    
    // Slight brightness adjustment
    processed = img.adjustColor(processed, brightness: 10);
    
    return processed;
  }

  /// Sort corner points in order: top-left, top-right, bottom-right, bottom-left
  List<Offset> _sortCornerPoints(List<Offset> points) {
    if (points.length != 4) {
      throw ArgumentError('Exactly 4 corner points required');
    }

    // Sort by y-coordinate to separate top and bottom points
    points.sort((a, b) => a.dy.compareTo(b.dy));
    
    final topTwo = points.sublist(0, 2)..sort((a, b) => a.dx.compareTo(b.dx));
    final bottomTwo = points.sublist(2)..sort((a, b) => a.dx.compareTo(b.dx));
    
    return [
      topTwo[0], // top-left
      topTwo[1], // top-right
      bottomTwo[1], // bottom-right
      bottomTwo[0], // bottom-left
    ];
  }

  /// Calculate distance between two points
  double _distance(Offset a, Offset b) {
    return sqrt(pow(b.dx - a.dx, 2) + pow(b.dy - a.dy, 2));
  }

  /// Rotate image by specified degrees
  Future<File> rotateImage(File imageFile, int degrees) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    img.Image rotated;
    switch (degrees) {
      case 90:
        rotated = img.copyRotate(image, angle: 90);
        break;
      case 180:
        rotated = img.copyRotate(image, angle: 180);
        break;
      case 270:
        rotated = img.copyRotate(image, angle: 270);
        break;
      default:
        rotated = image;
    }

    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/rotated_${_uuid.v4()}.jpg';
    final rotatedFile = File(outputPath);
    await rotatedFile.writeAsBytes(img.encodeJpg(rotated));
    
    return rotatedFile;
  }
}
