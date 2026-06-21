import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

import '../providers/scan_provider.dart';
import '../models/scanned_document.dart';
import 'editor_screen.dart';

/// Camera screen for capturing document images
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCapturing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              final scanProvider = Provider.of<ScanProvider>(context, listen: false);
              _pickFromGallery(scanProvider);
            },
          ),
        ],
      ),
      body: Consumer<ScanProvider>(
        builder: (context, scanProvider, child) {
          if (scanProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final cameraController = scanProvider.cameraController;
          
          if (cameraController == null || !cameraController.value.isInitialized) {
            return const Center(
              child: Text('Camera not initialized'),
            );
          }

          return Stack(
            children: [
              // Camera preview
              Positioned.fill(
                child: CameraPreview(cameraController),
              ),
              
              // Overlay with corner guides
              _buildCornerGuides(),
              
              // Bottom controls
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: _buildControls(scanProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCornerGuides() {
    const double cornerSize = 40.0;
    const double margin = 60.0;
    
    return Center(
      child: CustomPaint(
        size: Size.infinite,
        painter: CornerGuidePainter(
          cornerSize: cornerSize,
          margin: margin,
        ),
      ),
    );
  }

  Widget _buildControls(ScanProvider scanProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Flash toggle (placeholder)
        IconButton(
          icon: const Icon(Icons.flash_auto, color: Colors.white),
          iconSize: 32,
          onPressed: () {
            // TODO: Implement flash toggle
          },
        ),
        
        // Capture button
        GestureDetector(
          onTap: _isCapturing ? null : () => _captureImage(scanProvider),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: _isCapturing
                ? const CircularProgressIndicator(color: Colors.white)
                : Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
        
        // Switch camera
        IconButton(
          icon: const Icon(Icons.cameraswitch, color: Colors.white),
          iconSize: 32,
          onPressed: () => scanProvider.switchCamera(),
        ),
      ],
    );
  }

  Future<void> _captureImage(ScanProvider scanProvider) async {
    setState(() => _isCapturing = true);

    try {
      final imageFile = await scanProvider.captureImage();
      await scanProvider.addPage(imageFile);
      
      if (!mounted) return;
      
      // Navigate to editor screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EditorScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery(ScanProvider scanProvider) async {
    try {
      final imageFile = await scanProvider.pickImageFromGallery();
      
      if (imageFile != null) {
        await scanProvider.addPage(imageFile);
        
        if (!mounted) return;
        
        // Navigate to editor screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EditorScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }
}

/// Custom painter for drawing corner guides
class CornerGuidePainter extends CustomPainter {
  final double cornerSize;
  final double margin;

  CornerGuidePainter({required this.cornerSize, required this.margin});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerSize),
      Offset(rect.left, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerSize, rect.top),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerSize, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerSize),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerSize),
      Offset(rect.right, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right - cornerSize, rect.bottom),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left + cornerSize, rect.bottom),
      Offset(rect.left, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left, rect.bottom - cornerSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(CornerGuidePainter oldDelegate) => false;
}
