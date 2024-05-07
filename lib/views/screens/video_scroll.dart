import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class VideoScroll extends StatefulWidget {
  const VideoScroll({Key? key}) : super(key: key);

  @override
  State<VideoScroll> createState() => _VideoScrollState();
}

class _VideoScrollState extends State<VideoScroll> {
  late PageController _controller;
  List<File> _videoFiles = [];

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
    checkAndRequestPermission();
  }

  Future<void> checkAndRequestPermission() async {
    print("Checking storage permission...");
    var status = await Permission.storage.status;
    print("Current permission status: $status");

    if (!status.isGranted) {
      print("Requesting storage permission...");
      status = await Permission.storage.request();
      print("Permission status after request: $status");
    }

    if (status.isGranted) {
      print("Permission granted, loading videos...");
      _loadVideos();
    } else {
      print("Storage permission is denied.");
      showPermissionDeniedDialog();
    }
  }

  Future<void> showPermissionRationale() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Storage Permission Needed"),
        content: const Text("This app needs storage access to display videos."),
        actions: <Widget>[
          TextButton(
            child: const Text("Deny"),
            onPressed: () {
              Navigator.of(context).pop();
              showPermissionDeniedDialog();
            },
          ),
          TextButton(
            child: const Text("Allow"),
            onPressed: () {
              Navigator.of(context).pop();
              requestPermission();
            },
          ),
        ],
      ),
    );
  }

  Future<void> requestPermission() async {
    var result = await Permission.storage.request();
    if (result.isGranted) {
      _loadVideos();
    } else {
      showPermissionDeniedDialog();
    }
  }

  void showPermissionDeniedDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("Permission Denied"),
          content: Text(
              "Without storage permission, this app cannot display videos. You can enable it from app settings."),
          actions: <Widget>[
            TextButton(
              child: Text("Open Settings"),
              onPressed: () {
                openAppSettings();
              },
            ),
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadVideos() async {
    final videoDirectory = Directory('/storage/emulated/0/Download/');
    try {
      final videoList =
          videoDirectory.listSync().where((item) => item.path.endsWith('.mp4'));
      setState(() {
        _videoFiles = videoList.map((item) => File(item.path)).toList();
      });
    } catch (e) {
      print("Error accessing videos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _videoFiles.isNotEmpty
          ? PageView.builder(
              itemCount: _videoFiles.length,
              controller: _controller,
              scrollDirection: Axis.vertical,
              itemBuilder: (_, index) =>
                  VideoPlayerScreen(videoFile: _videoFiles[index]),
            )
          : Center(child: Text("No videos found or permission denied")),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;
  const VideoPlayerScreen({Key? key, required this.videoFile})
      : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _controller.setLooping(true);
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}
