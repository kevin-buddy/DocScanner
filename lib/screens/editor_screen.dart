import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/scan_provider.dart';
import '../models/scanned_document.dart';
import '../widgets/filter_selector.dart';
import '../widgets/page_thumbnail.dart';

/// Editor screen for processing and editing scanned documents
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  FilterType _selectedFilter = FilterType.magicColor;
  bool _isGeneratingPDF = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Document'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _saveAndExport(context),
          ),
        ],
      ),
      body: Consumer<ScanProvider>(
        builder: (context, scanProvider, child) {
          final document = scanProvider.currentDocument;
          final page = scanProvider.currentPage;

          if (document == null || page == null) {
            return const Center(
              child: Text('No document to edit'),
            );
          }

          return Column(
            children: [
              // Image preview with zoom
              Expanded(
                flex: 4,
                child: _buildImagePreview(page),
              ),
              
              // Filter selector
              Expanded(
                flex: 1,
                child: FilterSelector(
                  selectedFilter: _selectedFilter,
                  onFilterSelected: (filter) => _applyFilter(scanProvider, page, filter),
                ),
              ),
              
              // Page thumbnails
              Expanded(
                flex: 1,
                child: _buildPageThumbnails(scanProvider, document),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildImagePreview(ScannedPage page) {
    final imageFile = page.processedImage ?? page.originalImage;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ClipRect(
          child: Image.file(
            imageFile,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildPageThumbnails(ScanProvider scanProvider, ScannedDocument document) {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: document.pages.length,
        itemBuilder: (context, index) {
          final docPage = document.pages[index];
          final isSelected = docPage.id == scanProvider.currentPage?.id;
          
          return PageThumbnail(
            page: docPage,
            isSelected: isSelected,
            onTap: () => scanProvider.selectDocument(document),
            onDelete: document.pages.length > 1
                ? () => _deletePage(scanProvider, docPage.id)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.crop_rotate,
              label: 'Crop',
              onPressed: () => _showCropDialog(context),
            ),
            _buildActionButton(
              icon: Icons.rotate_right,
              label: 'Rotate',
              onPressed: () => _rotateCurrentPage(context),
            ),
            _buildActionButton(
              icon: Icons.add_photo_alternate,
              label: 'Add',
              onPressed: () => _addMorePages(context),
            ),
            _buildActionButton(
              icon: Icons.picture_as_pdf,
              label: 'PDF',
              onPressed: _isGeneratingPDF ? null : () => _generatePDF(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilter(ScanProvider scanProvider, ScannedPage page, FilterType filter) {
    setState(() => _selectedFilter = filter);
    scanProvider.applyFilterToPage(page, filter);
  }

  Future<void> _saveAndExport(BuildContext context) async {
    // Navigate back to home
    Navigator.pop(context);
  }

  Future<void> _generatePDF(BuildContext context) async {
    final scanProvider = context.read<ScanProvider>();
    
    setState(() => _isGeneratingPDF = true);

    try {
      final pdfFile = await scanProvider.generatePDF(searchable: true);
      
      if (!mounted) return;
      
      // Share the PDF
      await Share.shareXFiles([XFile(pdfFile.path)]);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPDF = false);
      }
    }
  }

  void _showCropDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Document'),
        content: const Text('Adjust the corners to match your document edges.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement crop functionality with corner detection
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _rotateCurrentPage(BuildContext context) async {
    final scanProvider = context.read<ScanProvider>();
    final page = scanProvider.currentPage;
    
    if (page != null) {
      await scanProvider.rotatePage(page, 90);
    }
  }

  Future<void> _addMorePages(BuildContext context) async {
    final scanProvider = context.read<ScanProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                // Navigate to camera screen
                // For now, just show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera navigation not implemented yet')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final imageFile = await scanProvider.pickImageFromGallery();
                  if (imageFile != null) {
                    await scanProvider.addPage(imageFile);
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add page: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deletePage(ScanProvider scanProvider, String pageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Page'),
        content: const Text('Are you sure you want to delete this page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              scanProvider.removePage(pageId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
