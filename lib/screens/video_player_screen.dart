import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../models/lesson_content_model.dart';
import '../services/screen_protection_service.dart';
import 'fullscreen_video_player_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final int lessonId;
  final String lessonName;

  const VideoPlayerScreen({
    super.key,
    required this.lessonId,
    required this.lessonName,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  VideoLessonResponse? _videoLesson;
  bool _isLoading = true;
  String? _error;
  bool _isGoogleMeet = false;
  String? _meetUrl;

  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
    _loadVideoLesson();
  }

  @override
  void dispose() {
    _controller?.dispose();
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }



  Future<void> _openFullscreenPlayer() async {
    if (_controller == null) return;
    
    // Get current playback position
    final currentPosition = _controller!.value.position;
    final videoId = _controller!.metadata.videoId;
    
    // Pause current player
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    }
    
    // Navigate to fullscreen landscape player
    final returnedPosition = await Navigator.push<Duration>(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayerScreen(
          videoId: videoId,
          startAt: currentPosition,
        ),
      ),
    );
    
    // Resume from the position when returned (if available)
    if (returnedPosition != null && mounted) {
      _controller!.seekTo(returnedPosition);
    }
  }

  Future<void> _loadVideoLesson() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        setState(() {
          _error = 'Please login to view this lesson';
          _isLoading = false;
        });
        return;
      }

      final result = await CourseService.getLessonContent(
        lessonId: widget.lessonId,
        token: token,
      );

      if (mounted) {
        if (result is VideoLessonResponse && result.success && result.data != null) {
          final videoUrl = result.data!.videoUrl;
          
          // Check if it's a Google Meet URL
          if (videoUrl != null && videoUrl.toLowerCase().contains('meet.google')) {
            setState(() {
              _videoLesson = result;
              _isGoogleMeet = true;
              _meetUrl = videoUrl;
              _isLoading = false;
            });
            return;
          }
          
          final videoId = videoUrl != null ? YoutubePlayer.convertUrlToId(videoUrl) : null;

          if (videoId != null) {
            _controller = YoutubePlayerController(
              initialVideoId: videoId,
              flags: const YoutubePlayerFlags(
                autoPlay: false,
                mute: false,
                enableCaption: false,
                forceHD: false,
                // Disable auto fullscreen to handle it manually
                hideControls: false,
              ),
            );
            
            // Listen for fullscreen button taps
            _controller!.addListener(() {
              if (_controller!.value.isFullScreen && mounted) {
                // Exit the default fullscreen mode
                _controller!.toggleFullScreenMode();
                // Navigate to our custom landscape fullscreen screen
                _openFullscreenPlayer();
              }
            });
          }

          setState(() {
            _videoLesson = result;
            _isGoogleMeet = false;
            _isLoading = false;
            if (videoId == null) {
              _error = 'Video not available';
            }
          });
        } else {
          setState(() {
            _error = result is VideoLessonResponse ? result.message : 'Failed to load lesson';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading lesson: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const SizedBox(width: 48), // Balance for back button
              Expanded(
                child: Text(
                  widget.lessonName,
                  style: const TextStyle(
                    color: Color(0xFF4A5F7A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Color(0xFF4A5F7A)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B8CAE)),
                ),
              )
            : _error != null
                ? _buildErrorState()
                : _isGoogleMeet
                    ? _buildGoogleMeetContent()
                    : _buildVideoContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5F7A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'تعذر تشغيل الفيديو',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadVideoLesson();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B8CAE),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinLiveSession() async {
    if (_meetUrl == null) return;
    
    final uri = Uri.parse(_meetUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the meeting link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGoogleMeetContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Meet Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00832D),
                    const Color(0xFF34A853),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34A853).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.videocam_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            
            // Title
            Text(
              widget.lessonName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5F7A),
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Description
            const Text(
              'This is a live session. Click the button below to join.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Join Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _joinLiveSession,
                icon: const Icon(Icons.video_call_rounded, size: 24),
                label: const Text(
                  'Join Live Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0xFF34A853).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Info text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6B8CAE).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF6B8CAE),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The meeting will open in your browser or Google Meet app',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF4A5F7A).withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Video Player
          if (_controller != null)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayer(
                  controller: _controller!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: const Color(0xFF6B8CAE),
                  progressColors: const ProgressBarColors(
                    playedColor: Color(0xFF6B8CAE),
                    handleColor: Color(0xFF4A5F7A),
                  ),
                ),
              ),
            ),
            
          // Lesson Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lessonName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5F7A),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (_videoLesson?.data?.attachmentUrl != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Attachments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A5F7A),
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.attach_file, color: Color(0xFF6B8CAE)),
                        title: Text(
                          _videoLesson?.data?.attachmentTitle ?? 'Attached File',
                          style: const TextStyle(color: Color(0xFF4A5F7A)),
                          textDirection: TextDirection.ltr,
                        ),
                        onTap: () {
                          // Handle attachment download/view
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
