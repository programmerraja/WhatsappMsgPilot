import 'package:workmanager/workmanager.dart';
import '../models/scheduled_message.dart';

class SchedulingService {
  static const String _taskName = "sendWhatsAppMessage";
  
  // Initialize the WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for debugging
    );
  }

  // Schedule a message to be sent
  Future<String> scheduleMessage(ScheduledMessage message) async {
    final uniqueId = message.id;
    final now = DateTime.now();
    final delay = message.scheduledTime.difference(now);
    
    if (delay.isNegative) {
      throw SchedulingException('Cannot schedule message in the past');
    }

    try {
      await Workmanager().registerOneOffTask(
        uniqueId,
        _taskName,
        initialDelay: delay,
        inputData: {
          'phone': message.phone,
          'message': message.message,
          'contactName': message.contactName,
          'scheduleId': message.id,
        },
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      
      return uniqueId;
    } catch (e) {
      throw SchedulingException('Failed to schedule message: $e');
    }
  }

  // Cancel a scheduled message
  Future<void> cancelScheduledMessage(String workId) async {
    try {
      await Workmanager().cancelByUniqueName(workId);
    } catch (e) {
      throw SchedulingException('Failed to cancel scheduled message: $e');
    }
  }

  // Cancel all scheduled messages
  Future<void> cancelAllScheduledMessages() async {
    try {
      await Workmanager().cancelAll();
    } catch (e) {
      throw SchedulingException('Failed to cancel all scheduled messages: $e');
    }
  }

  // Reschedule a message (cancel old and create new)
  Future<String> rescheduleMessage(ScheduledMessage message, String? oldWorkId) async {
    if (oldWorkId != null) {
      await cancelScheduledMessage(oldWorkId);
    }
    return await scheduleMessage(message);
  }
}

// This function is called when a background task is triggered
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Extract data from inputData
      final phone = inputData?['phone'] as String?;
      final message = inputData?['message'] as String?;
      final contactName = inputData?['contactName'] as String?;
      final scheduleId = inputData?['scheduleId'] as String?;

      if (phone == null || message == null) {
        print('WorkManager: Missing required data (phone or message)');
        return Future.value(false);
      }

      print('WorkManager: Attempting to send message to $phone: $message');
      
      // Here we would normally call the native method to open WhatsApp
      // For now, we'll just log it
      // TODO: Implement native method call to open WhatsApp
      
      return Future.value(true);
    } catch (e) {
      print('WorkManager error: $e');
      return Future.value(false);
    }
  });
}

class SchedulingException implements Exception {
  final String message;
  SchedulingException(this.message);
  
  @override
  String toString() => 'SchedulingException: $message';
}