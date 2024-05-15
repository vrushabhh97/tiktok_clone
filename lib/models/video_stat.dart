import 'package:cloud_firestore/cloud_firestore.dart';

class VideoStat {
  String videoName;
  DateTime startTime;
  DateTime? endTime; // Make endTime nullable
  int? totalTime; // Make totalTime nullable since it depends on endTime

  VideoStat({
    required this.videoName,
    required this.startTime,
    this.endTime, // endTime is nullable
    this.totalTime, // totalTime is nullable
  });

  Map<String, dynamic> toJson() {
    return {
      'videoName': videoName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'totalTime': totalTime,
    };
  }

  static VideoStat fromJson(Map<String, dynamic> data) {
    return VideoStat(
      videoName: data['videoName'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      totalTime: data['totalTime'] as int?,
    );
  }

  List<dynamic> toList() {
    return [
      videoName,
      startTime.toIso8601String(),
      endTime?.toIso8601String(),
      totalTime.toString(),
    ];
  }
}
