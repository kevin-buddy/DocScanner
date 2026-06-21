import 'dart:io';
import 'dart:typed_data';

/// Represents a single scanned document page
class ScannedPage {
  final String id;
  File originalImage;
  File? processedImage;
  List<Offset>? cornerPoints; // For perspective correction
  String? ocrText;
  FilterType appliedFilter;
  DateTime createdAt;

  ScannedPage({
    required this.id,
    required this.originalImage,
    this.processedImage,
    this.cornerPoints,
    this.ocrText,
    this.appliedFilter = FilterType.none,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isProcessed => processedImage != null;
  bool get hasOCRText => ocrText != null && ocrText!.isNotEmpty;
}

/// Document containing multiple scanned pages
class ScannedDocument {
  final String id;
  final String title;
  final List<ScannedPage> pages;
  DateTime createdAt;
  DateTime updatedAt;

  ScannedDocument({
    required this.id,
    required this.title,
    List<ScannedPage>? pages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : pages = pages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  void addPage(ScannedPage page) {
    pages.add(page);
    updatedAt = DateTime.now();
  }

  void removePage(String pageId) {
    pages.removeWhere((page) => page.id == pageId);
    updatedAt = DateTime.now();
  }

  int get pageCount => pages.length;
}

/// Available filter types for document enhancement
enum FilterType {
  none,
  grayscale,
  blackAndWhite,
  magicColor,
  lighten,
  darken,
}

/// Extension to get display name for filters
extension FilterTypeExtension on FilterType {
  String get displayName {
    switch (this) {
      case FilterType.none:
        return 'None';
      case FilterType.grayscale:
        return 'Grayscale';
      case FilterType.blackAndWhite:
        return 'B&W';
      case FilterType.magicColor:
        return 'Magic Color';
      case FilterType.lighten:
        return 'Lighten';
      case FilterType.darken:
        return 'Darken';
    }
  }
}
