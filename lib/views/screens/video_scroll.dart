import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class VideoScroll extends StatefulWidget {
  const VideoScroll({super.key});

  @override
  State<VideoScroll> createState() => _VideoScrollState();
}

class _VideoScrollState extends State<VideoScroll> {
  late PageController controller;
  late List<Widget> reel;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = PageController(initialPage: 0);
    reel = [
      VideoPlayerScreen(videoAsset: 'assets/videos/ATV+Game3.mp4'),
      VideoPlayerScreen(videoAsset: 'assets/videos/LATV+Craft2.mp4'),
      VideoPlayerScreen(videoAsset: 'assets/videos/LATV+Craft3.mp4'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        scrollDirection: Axis.vertical,
        children: reel,
        controller: controller,
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoAsset;
  const VideoPlayerScreen({Key? key, required this.videoAsset})
      : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Offset _tapPosition = Offset.zero; // Initial tap position

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoAsset)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _controller.setLooping(true);
        });
      });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.fastOutSlowIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    setState(() {
      _tapPosition = details.globalPosition;
    });
    _animationController.forward(from: 0.0);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          Positioned(
            top: _tapPosition.dy - 50, // Adjust the icon to the tap location
            left: _tapPosition.dx - 50,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(Icons.favorite, size: 100, color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
