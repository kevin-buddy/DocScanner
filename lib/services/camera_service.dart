import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for camera and image picking operations
class CameraService {
  final ImagePicker _imagePicker = ImagePicker();
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;

  /// Request camera permissions
  Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    
    return cameraStatus.isGranted && (storageStatus.isGranted || storageStatus.isLimited);
  }

  /// Initialize camera
  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.max,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
      }
    } catch (e) {
      throw Exception('Failed to initialize camera: $e');
    }
  }

  /// Get camera controller
  CameraController? get cameraController => _cameraController;

  /// Get available cameras
  List<CameraDescription>? get cameras => _cameras;

  /// Capture image from camera
  Future<File> captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      final XFile capturedImage = await _cameraController!.takePicture();
      return File(capturedImage.path);
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImagesFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 4096,
        maxHeight: 4096,
      );

      return pickedFiles.map((file) => File(file.path)).toList();
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  /// Dispose camera resources
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentLensDirection = _cameraController!.description.lensDirection;
    CameraDescription? newCamera;

    if (currentLensDirection == CameraLensDirection.back) {
      newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
    } else {
      newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
    }

    if (newCamera != _cameraController!.description) {
      await _cameraController?.dispose();
      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.max,
        enableAudio: false,
      );
      await _cameraController!.initialize();
    }
  }
}
