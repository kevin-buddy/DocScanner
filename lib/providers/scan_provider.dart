import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/scanned_document.dart';
import 'camera_service.dart';
import 'image_processing_service.dart';
import 'ocr_service.dart';
import 'pdf_service.dart';

/// Provider class for managing scan state and operations
class ScanProvider with ChangeNotifier {
  final _uuid = const Uuid();
  
  final CameraService _cameraService = CameraService();
  final ImageProcessingService _imageProcessingService = ImageProcessingService();
  final OCRService _ocrService = OCRService();
  final PDFService _pdfService = PDFService();

  List<ScannedDocument> _documents = [];
  ScannedDocument? _currentDocument;
  ScannedPage? _currentPage;
  
  bool _isProcessing = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ScannedDocument> get documents => _documents;
  ScannedDocument? get currentDocument => _currentDocument;
  ScannedPage? get currentPage => _currentPage;
  bool get isProcessing => _isProcessing;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize camera
  Future<void> initializeCamera() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final hasPermission = await _cameraService.requestPermissions();
      if (!hasPermission) {
        throw Exception('Camera permission denied');
      }

      await _cameraService.initializeCamera();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new document
  void createNewDocument(String title) {
    _currentDocument = ScannedDocument(
      id: _uuid.v4(),
      title: title,
    );
    notifyListeners();
  }

  /// Capture image from camera
  Future<File> captureImage() async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      final imageFile = await _cameraService.captureImage();
      
      return imageFile;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      final imageFile = await _cameraService.pickImageFromGallery();
      
      return imageFile;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Add page to current document
  Future<void> addPage(File imageFile) async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      if (_currentDocument == null) {
        createNewDocument('Document_${DateTime.now().millisecondsSinceEpoch}');
      }

      final page = ScannedPage(
        id: _uuid.v4(),
        originalImage: imageFile,
      );

      _currentDocument!.addPage(page);
      _currentPage = page;
      
      // Auto-process the page
      await processPage(page);
      
      _documents.add(_currentDocument!);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Process a page (apply filter and OCR)
  Future<void> processPage(ScannedPage page, {FilterType filterType = FilterType.magicColor}) async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      // Apply perspective correction if corner points are available
      File processedImage = page.originalImage;
      
      if (page.cornerPoints != null && page.cornerPoints!.length == 4) {
        processedImage = await _imageProcessingService.applyPerspectiveCorrection(
          page.originalImage,
          page.cornerPoints!,
        );
      }

      // Apply filter
      processedImage = await _imageProcessingService.applyFilter(
        processedImage,
        filterType,
      );

      page.processedImage = processedImage;
      page.appliedFilter = filterType;

      // Extract OCR text
      final ocrText = await _ocrService.extractText(processedImage);
      page.ocrText = ocrText;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Apply filter to a page
  Future<void> applyFilterToPage(ScannedPage page, FilterType filterType) async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      final filteredImage = await _imageProcessingService.applyFilter(
        page.processedImage ?? page.originalImage,
        filterType,
      );

      page.processedImage = filteredImage;
      page.appliedFilter = filterType;

      // Re-extract OCR text with new filter
      final ocrText = await _ocrService.extractText(filteredImage);
      page.ocrText = ocrText;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Update corner points for perspective correction
  void updateCornerPoints(ScannedPage page, List<Offset> cornerPoints) {
    page.cornerPoints = cornerPoints;
    notifyListeners();
  }

  /// Rotate page
  Future<void> rotatePage(ScannedPage page, int degrees) async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      final imageToRotate = page.processedImage ?? page.originalImage;
      final rotatedImage = await _imageProcessingService.rotateImage(
        imageToRotate,
        degrees,
      );

      if (page.processedImage != null) {
        page.processedImage = rotatedImage;
      } else {
        page.originalImage = rotatedImage;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Generate PDF from current document
  Future<File> generatePDF({bool searchable = true}) async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      if (_currentDocument == null || _currentDocument!.pages.isEmpty) {
        throw Exception('No pages to generate PDF');
      }

      File pdfFile;
      if (searchable) {
        pdfFile = await _pdfService.generateSearchablePDF(_currentDocument!);
      } else {
        pdfFile = await _pdfService.generatePDF(_currentDocument!);
      }

      return pdfFile;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Remove page from current document
  void removePage(String pageId) {
    if (_currentDocument != null) {
      _currentDocument!.removePage(pageId);
      if (_currentDocument!.pages.isNotEmpty) {
        _currentPage = _currentDocument!.pages.first;
      } else {
        _currentPage = null;
      }
      notifyListeners();
    }
  }

  /// Delete document
  void deleteDocument(String documentId) {
    _documents.removeWhere((doc) => doc.id == documentId);
    if (_currentDocument?.id == documentId) {
      _currentDocument = _documents.isNotEmpty ? _documents.first : null;
      _currentPage = _currentDocument?.pages.first;
    }
    notifyListeners();
  }

  /// Select document
  void selectDocument(ScannedDocument document) {
    _currentDocument = document;
    _currentPage = document.pages.isNotEmpty ? document.pages.first : null;
    notifyListeners();
  }

  /// Clear current document
  void clearCurrentDocument() {
    _currentDocument = null;
    _currentPage = null;
    notifyListeners();
  }

  /// Switch camera
  Future<void> switchCamera() async {
    try {
      await _cameraService.switchCamera();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _ocrService.dispose();
    super.dispose();
  }
}
