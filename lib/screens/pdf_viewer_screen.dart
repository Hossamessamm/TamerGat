import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../widgets/pdf_drawing_overlay.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../models/lesson_content_model.dart';

class PdfViewerScreen extends StatefulWidget {
  final int lessonId;
  final String lessonName;

  const PdfViewerScreen({
    super.key,
    required this.lessonId,
    required this.lessonName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  FileLessonResponse? _fileLesson;
  bool _isLoading = true;
  String? _error;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPageNumber = 1;
  int _totalPages = 0;
  bool _isDrawingMode = false;

  @override
  void initState() {
    super.initState();
    // Enable screenshot and screen recording protection
    ScreenProtector.preventScreenshotOn();
    _loadFileLesson();
  }

  @override
  void dispose() {
    // Disable screenshot protection when leaving
    ScreenProtector.preventScreenshotOff();
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<void> _loadFileLesson() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await CourseService.getLessonContent(
        lessonId: widget.lessonId,
        token: token,
      );

      if (response is FileLessonResponse) {
        setState(() {
          _fileLesson = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Invalid lesson type';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading PDF: $e';
        _isLoading = false;
      });
    }
  }

  String? _getGoogleDriveDirectLink(String? url) {
    if (url == null) return null;
    
    // Convert Google Drive sharing link to viewable link for PDF viewer
    // Multiple formats supported:
    // 1. https://drive.google.com/file/d/FILE_ID/view?usp=sharing
    // 2. https://drive.google.com/file/d/FILE_ID/view?usp=drive_link
    // 3. https://drive.google.com/open?id=FILE_ID
    
    if (url.contains('drive.google.com')) {
      String? fileId;
      
      // Try to extract file ID from /d/ format
      final fileIdMatch = RegExp(r'/d/([^/\?]+)').firstMatch(url);
      if (fileIdMatch != null) {
        fileId = fileIdMatch.group(1);
      } else {
        // Try to extract from ?id= format
        final idMatch = RegExp(r'[?&]id=([^&]+)').firstMatch(url);
        if (idMatch != null) {
          fileId = idMatch.group(1);
        }
      }
      
      if (fileId != null) {
        // Use the preview URL which works better with PDF viewers
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      }
    }
    
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2C2C2C),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.lessonName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_totalPages > 0)
                Text(
                  'Page $_currentPageNumber of $_totalPages',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          actions: [
            if (!_isLoading && _fileLesson != null)
              IconButton(
                icon: Icon(
                  _isDrawingMode ? Icons.brush_outlined : Icons.edit,
                  color: Colors.white,
                ),
                tooltip: _isDrawingMode ? 'Exit drawing mode' : 'Draw on PDF',
                onPressed: () {
                  setState(() {
                    _isDrawingMode = !_isDrawingMode;
                  });
                },
              ),
            if (!_isLoading && _fileLesson != null)
              IconButton(
                icon: const Icon(Icons.zoom_in, color: Colors.white),
                onPressed: () {
                  _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
                },
                tooltip: 'Zoom In',
              ),
            if (!_isLoading && _fileLesson != null)
              IconButton(
                icon: const Icon(Icons.zoom_out, color: Colors.white),
                onPressed: () {
                  if (_pdfViewerController.zoomLevel > 1) {
                    _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
                  }
                },
                tooltip: 'Zoom Out',
              ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: !_isLoading && _fileLesson != null && _totalPages > 0
            ? _buildNavigationBar()
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38026B)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadFileLesson();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38026B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_fileLesson?.data?.filePath1 == null) {
      return const Center(
        child: Text(
          'No PDF file available',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }

    final originalUrl = _fileLesson!.data!.filePath1;
    final pdfUrl = _getGoogleDriveDirectLink(originalUrl);

    // Debug print
    print('📄 Original URL: $originalUrl');
    print('📄 Converted URL: $pdfUrl');

    if (pdfUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Invalid PDF URL',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'URL: $originalUrl',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Stack(
        children: [
          SfPdfViewer.network(
            pdfUrl,
            controller: _pdfViewerController,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              print('✅ PDF loaded successfully! Pages: ${details.document.pages.count}');
              setState(() {
                _totalPages = details.document.pages.count;
              });
            },
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() {
                _currentPageNumber = details.newPageNumber;
              });
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              print('❌ PDF load failed: ${details.error}');
              print('❌ Description: ${details.description}');
              setState(() {
                _error = 'Failed to load PDF: ${details.error}\n\nURL: $pdfUrl\n\nPlease check:\n1. The file is a valid PDF\n2. The Google Drive link has public access\n3. Your internet connection is stable';
                _isLoading = false;
              });
            },
            enableDoubleTapZooming: true,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            pageLayoutMode: PdfPageLayoutMode.single,
          ),
          if (_fileLesson != null)
            PdfDrawingOverlay(
              isDrawingMode: _isDrawingMode,
              currentPage: _currentPageNumber,
              totalPages: _totalPages,
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      color: const Color(0xFF2C2C2C),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + safeBottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Page Button
          ElevatedButton.icon(
            onPressed: _currentPageNumber > 1
                ? () {
                    _pdfViewerController.previousPage();
                  }
                : null,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38026B),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade700,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),

          // Page Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3C3C3C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_currentPageNumber / $_totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Next Page Button
          ElevatedButton.icon(
            onPressed: _currentPageNumber < _totalPages
                ? () {
                    _pdfViewerController.nextPage();
                  }
                : null,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38026B),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade700,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

