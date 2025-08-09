import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/scheduled_message.dart';

class StorageService {
  static const String _fileName = 'schedules.json';
  
  // Get the file path for storing schedules
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Save a list of scheduled messages to storage
  Future<void> saveSchedules(List<ScheduledMessage> schedules) async {
    try {
      final file = await _getFile();
      final jsonList = schedules.map((schedule) => schedule.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      throw StorageException('Failed to save schedules: $e');
    }
  }

  // Load all scheduled messages from storage
  Future<List<ScheduledMessage>> loadSchedules() async {
    try {
      final file = await _getFile();
      
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList
          .map((json) => ScheduledMessage.fromJson(json))
          .toList();
    } catch (e) {
      throw StorageException('Failed to load schedules: $e');
    }
  }

  // Add a new scheduled message
  Future<void> addSchedule(ScheduledMessage schedule) async {
    final schedules = await loadSchedules();
    schedules.add(schedule);
    await saveSchedules(schedules);
  }

  // Update an existing scheduled message
  Future<void> updateSchedule(ScheduledMessage updatedSchedule) async {
    final schedules = await loadSchedules();
    final index = schedules.indexWhere((s) => s.id == updatedSchedule.id);
    
    if (index == -1) {
      throw StorageException('Schedule not found for update');
    }
    
    schedules[index] = updatedSchedule;
    await saveSchedules(schedules);
  }

  // Delete a scheduled message by ID
  Future<void> deleteSchedule(String scheduleId) async {
    final schedules = await loadSchedules();
    schedules.removeWhere((s) => s.id == scheduleId);
    await saveSchedules(schedules);
  }

  // Get a single scheduled message by ID
  Future<ScheduledMessage?> getSchedule(String scheduleId) async {
    final schedules = await loadSchedules();
    try {
      return schedules.firstWhere((s) => s.id == scheduleId);
    } catch (e) {
      return null;
    }
  }

  // Clear all scheduled messages (useful for debugging)
  Future<void> clearAllSchedules() async {
    final file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Get file size for debugging
  Future<int> getStorageSize() async {
    final file = await _getFile();
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  
  @override
  String toString() => 'StorageException: $message';
}