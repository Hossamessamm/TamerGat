import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FullscreenVideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final Duration? startAt;

  const FullscreenVideoPlayerScreen({
    super.key,
    required this.videoId,
    this.startAt,
  });

  @override
  State<FullscreenVideoPlayerScreen> createState() => _FullscreenVideoPlayerScreenState();
}

class _FullscreenVideoPlayerScreenState extends State<FullscreenVideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
    
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        startAt: widget.startAt?.inSeconds ?? 0,
      ),
    );
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    // Restore portrait orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return the current position when exiting
        Navigator.pop(context, _controller.value.position);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: const Color(0xFF6B8CAE),
                progressColors: const ProgressBarColors(
                  playedColor: Color(0xFF6B8CAE),
                  handleColor: Color(0xFF4A5F7A),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.pop(context, _controller.value.position);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
