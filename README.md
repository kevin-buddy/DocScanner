# DocScanner - CamScanner Clone

A powerful document scanning application built with Flutter that captures documents, straightens them, applies filters, converts to PDF, and uses OCR for text enhancement.

## Features

### 📸 Camera & Image Capture

- Take photos of documents using the device camera
- Pick images from the gallery
- Real-time camera preview with corner guides
- Support for multiple pages per document

### ✨ Image Processing

- **Perspective Correction**: Automatically detect and straighten document edges
- **Filters**:
  - None (original)
  - Grayscale
  - Black & White (binarization)
  - Magic Color (enhanced contrast)
  - Lighten
  - Darken
- **Rotation**: Rotate pages by 90° increments
- **Crop**: Manual corner adjustment for precise cropping

### 📄 PDF Generation

- Convert scanned documents to PDF
- Searchable PDF support with OCR text layer
- Multiple page support
- Share PDF directly from the app

### 🔍 OCR (Optical Character Recognition)

- Extract text from scanned documents using Google ML Kit
- Text is embedded in PDF for searchability
- Clear text visibility when zooming in
- Automatic text extraction on scan

### 📱 User Interface

- Modern Material Design 3 UI
- Document list with thumbnails
- Page thumbnails in editor
- Interactive image viewer with zoom (0.5x - 4x)
- Filter selection with visual previews
- Empty state with helpful guidance

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── scanned_document.dart # Data models
├── providers/
│   └── scan_provider.dart    # State management
├── screens/
│   ├── home_screen.dart      # Document list
│   ├── camera_screen.dart    # Camera capture
│   └── editor_screen.dart    # Image editing
├── services/
│   ├── camera_service.dart   # Camera operations
│   ├── image_processing_service.dart # Image filters & corrections
│   ├── ocr_service.dart      # Text recognition
│   └── pdf_service.dart      # PDF generation
└── widgets/
    ├── document_card.dart    # Document list item
    ├── page_thumbnail.dart   # Page preview
    └── filter_selector.dart  # Filter selection UI
```

## Dependencies

- **provider**: State management
- **camera**: Camera access and preview
- **image_picker**: Gallery image selection
- **image**: Image processing operations
- **google_mlkit_text_recognition**: OCR functionality
- **pdf**: PDF document creation
- **printing**: PDF printing and sharing
- **path_provider**: File system paths
- **share_plus**: File sharing
- **permission_handler**: Runtime permissions
- **uuid**: Unique ID generation

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Android Studio / Xcode
- Android SDK (for Android development)
- iOS SDK (for iOS development)

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd doc_scanner
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure platform-specific settings:

#### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

Update `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 33

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }
}
```

#### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan documents</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select images</string>
```

4. Run the app:

```bash
flutter run
```

## Usage

1. **Launch the app** - You'll see the home screen with your scanned documents
2. **Tap "Scan"** - Opens the camera with corner guides
3. **Capture document** - Take a photo or select from gallery
4. **Edit the scan**:
   - Apply filters (Magic Color recommended for documents)
   - Adjust corners if needed
   - Rotate if necessary
   - Add more pages
5. **Generate PDF** - Tap the PDF button to create and share
6. **View OCR text** - Zoom in to see enhanced text clarity

## Architecture

The app follows the **Provider** state management pattern with a service-layer architecture:

- **Models**: Define data structures (ScannedDocument, ScannedPage, FilterType)
- **Providers**: Manage app state and business logic (ScanProvider)
- **Services**: Handle specific operations (Camera, Image Processing, OCR, PDF)
- **Screens**: UI pages (Home, Camera, Editor)
- **Widgets**: Reusable UI components

## Best Practices Implemented

✅ Clean architecture with separation of concerns  
✅ State management using Provider  
✅ Async/await for all I/O operations  
✅ Error handling with try-catch blocks  
✅ Responsive UI with Material Design 3  
✅ Proper resource disposal  
✅ Type-safe enums and extensions  
✅ Comprehensive documentation

## Future Enhancements

- [ ] Auto edge detection using OpenCV
- [ ] Cloud storage integration
- [ ] Document organization with folders
- [ ] Multi-language OCR support
- [ ] Batch PDF generation
- [ ] Document signing capability
- [ ] QR code scanning
- [ ] Dark mode support

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and feature requests, please create an issue in the repository.
