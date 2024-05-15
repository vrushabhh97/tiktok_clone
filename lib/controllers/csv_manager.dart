import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CSVManager {
  Future<File> getLocalFile(String guestId) async {
    // Request and check storage permission
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted');
    }

    // Get the external storage directory
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('Unable to locate external storage directory');
    }

    // Build the path to the 'Download' directory
    final downloadDirectoryPath =
        '${directory.path.split('Android')[0]}Download';
    final downloadDirectory = Directory(downloadDirectoryPath);
    if (!await downloadDirectory.exists()) {
      await downloadDirectory.create(
          recursive: true); // Ensure the Download directory exists
    }

    // Full path to the CSV file within the 'Download' directory
    final filePath = '$downloadDirectoryPath/$guestId.csv';
    return File(filePath);
  }

  // Method to append or create a new CSV file
  Future<void> appendToCsv(String guestId, List<List<dynamic>> rows) async {
    final file = await getLocalFile(guestId);

    // Check if file exists and read existing content
    String existingData = '';
    if (await file.exists()) {
      existingData = await file.readAsString();
    }

    // Convert rows to CSV data
    String csvData = ListToCsvConverter().convert(rows);

    // Append new data or write new file
    await file.writeAsString('$existingData$csvData',
        mode: FileMode.writeOnlyAppend);
  }
}
