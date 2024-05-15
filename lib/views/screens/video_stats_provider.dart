import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:tiktok_clone/controllers/csv_manager.dart';
import 'package:tiktok_clone/models/video_stat.dart'; // Ensure this is correctly imported

class VideoStatsProvider with ChangeNotifier {
  Map<int, VideoStat> _videoStats = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This method should be called when you change the video being viewed.
  void recordEndAndCalculateDuration(int pageIndex) {
    VideoStat? currentStat = _videoStats[pageIndex];
    if (currentStat != null && currentStat.startTime != null) {
      currentStat.endTime = DateTime.now(); // Set end time
      if (currentStat.endTime != null) {
        // Calculate the duration in seconds
        currentStat.totalTime =
            currentStat.endTime!.difference(currentStat.startTime).inSeconds;

        // Save the stat, ideally this should also take a userId if you're tracking per user
        saveVideoStat('userId', currentStat);
      }
      notifyListeners();
    }
  }

  // Add a new stat when a video starts playing
  void startWatching(int pageIndex, String videoPath) {
    _videoStats[pageIndex] = VideoStat(
      videoName: videoPath,
      startTime: DateTime.now(),
      endTime: null,
      totalTime: null,
    );
  }

  Future<void> saveVideoStat(String userId, VideoStat stat) async {
    // Example: saving locally for now, adjust according to your requirements
    try {
      final file =
          await CSVManager().getLocalFile(userId); // Pass userId as guestId
      List<List<dynamic>> rows = [];

      if (await file.exists()) {
        String contents = await file.readAsString();
        final converter = CsvToListConverter();
        rows = converter.convert(contents);
      }

      // Add new data to rows
      rows.add([
        userId,
        stat.videoName,
        stat.startTime.toString(),
        stat.endTime.toString(),
        stat.totalTime
      ]);
      final String csv = const ListToCsvConverter().convert(rows);
      await file.writeAsString(csv, mode: FileMode.writeOnlyAppend);

      print("Data saved to CSV at ${file.path}");
    } catch (e) {
      print("Failed to save data: $e");
    }
  }
}
