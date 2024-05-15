import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this for haptic feedback
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tiktok_clone/controllers/auth_controller.dart';
import 'package:tiktok_clone/controllers/user_controller.dart';
import 'package:tiktok_clone/models/video_stat.dart' as model;
import 'package:tiktok_clone/models/video_stat.dart';
import 'package:tiktok_clone/views/screens/video_stats_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:tiktok_clone/controllers/csv_manager.dart';

class VideoScroll extends StatefulWidget {
  const VideoScroll({Key? key}) : super(key: key);

  @override
  State<VideoScroll> createState() => _VideoScrollState();
}

class _VideoScrollState extends State<VideoScroll> {
  late PageController _controller;
  List<File> _videoFiles = [];
  int _currentPage = 0;
  List<List<dynamic>> rows = [];
  Map<int, DateTime> videoStartTimes = {};

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
    _controller.addListener(_handlePageChange);
    rows.add(["Video Name", "Start Time", "End Time", "Total Time (Seconds)"]);
    checkAndRequestPermission();
  }

  Future<void> _handlePageChange() async {
    int newPage = _controller.page!.round();
    if (_currentPage != newPage) {
      if (videoStartTimes.containsKey(_currentPage)) {
        await _recordStats(_currentPage);
      }
      videoStartTimes[newPage] = DateTime.now();
      if (mounted) {
        setState(() {
          _currentPage = newPage;
        });
      }
    }
  }

  Future<void> _recordStats(int pageIndex) async {
    String videoName = _videoFiles[pageIndex].path.split('/').last;
    DateTime startTime = videoStartTimes[pageIndex] ?? DateTime.now();
    DateTime endTime = DateTime.now();
    Duration totalWatchTime = endTime.difference(startTime);

    // Add data to rows if it doesn't already exist
    bool exists = rows.any((row) => row[0] == videoName);
    if (!exists) {
      rows.add([
        videoName,
        startTime.toString(),
        endTime.toString(),
        totalWatchTime.inSeconds.toString()
      ]);
      await saveDataToCsv();
    }
  }

  Future<void> saveDataToCsv() async {
    // Request permission to access storage
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      print("Storage permission not granted");
      return;
    }

    try {
      // Get the external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        print("Could not get the external storage directory");
        return;
      }

      // Build the path to the Downloads directory
      final path = '${directory.path}/Download';

      // Check if the Download directory exists, if not create it
      final downloadDirectory = Directory(path);
      if (!await downloadDirectory.exists()) {
        await downloadDirectory.create(
            recursive: true); // Create the directory if it doesn't exist
      }

      String filePath = '$path/video_stats.csv';
      String csvData = const ListToCsvConverter().convert(rows);

      // Save CSV data to file in the Downloads folder
      File file = File(filePath);
      await file.writeAsString(csvData);
      print("Data saved to CSV at $filePath");
    } catch (e) {
      print("Failed to save CSV: $e");
    }
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

  Future<void> _loadVideos() async {
    final videoDirectory =
        Directory('/storage/emulated/0/Download/control feed/');
    try {
      final videoList = videoDirectory
          .listSync()
          .where((item) => item.path.endsWith('.mp4'))
          .toList();

      // Sort the videoList based on the file name
      videoList.sort((a, b) {
        String aName = a.path.split('/').last.split('.').first;
        String bName = b.path.split('/').last.split('.').first;
        return aName.compareTo(bName);
      });

      setState(() {
        _videoFiles = videoList.map((item) => File(item.path)).toList();
      });
    } catch (e) {
      print("Error accessing videos: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _videoFiles.isNotEmpty
          ? PageView.builder(
              itemCount: _videoFiles.length,
              controller: _controller,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                Provider.of<VideoStatsProvider>(context, listen: false)
                    .recordEndAndCalculateDuration(index);
              },
              itemBuilder: (_, index) => VideoPlayerScreen(
                videoFile: _videoFiles[index],
                pageIndex: index,
                controller: _controller,
                onEndCallback: () => _recordStats(index),
              ),
            )
          : Center(child: Text("No videos found or permission denied")),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;
  final int pageIndex;
  final PageController controller;
  final VoidCallback onEndCallback;

  const VideoPlayerScreen(
      {Key? key,
      required this.videoFile,
      required this.pageIndex,
      required this.controller,
      required this.onEndCallback})
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
  Offset _tapPosition = Offset.zero;
  DateTime? startTime;
  bool hasRecorded = false;
  DateTime? endTime;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _controller.setLooping(true);
          startTime = DateTime.now();
          hasRecorded = false;
        });
      });

    _controller.addListener(checkAndRecordStats);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.fastOutSlowIn));
  }

  void recordStats() {
    if (startTime != null && endTime != null) {
      final duration = endTime!.difference(startTime!).inSeconds;
      print("Video: ${widget.videoFile.path}, Duration: $duration seconds");
      // Here you would save to CSV or perform another action
    }
  }

  void checkAndRecordStats() {
    if (!_controller.value.isPlaying && startTime != null && !hasRecorded) {
      endTime = DateTime.now();
      recordStats();
      hasRecorded = true;
      widget.onEndCallback(); // Call the callback when stats are recorded
    }
    if (_controller.value.isPlaying) {
      startTime = DateTime.now(); // Reset start time when video is played again
      hasRecorded = false; // Reset flag when video is played
    }
  }

  @override
  void dispose() {
    _controller.removeListener(checkAndRecordStats);
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    _animationController.forward(from: 0.0);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onTap: () => _controller.value.isPlaying
          ? _controller.pause()
          : _controller.play(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          Positioned(
            top: _tapPosition.dy - 50,
            left: _tapPosition.dx - 50,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (_, __) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Icon(Icons.favorite, size: 100, color: Colors.red),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
