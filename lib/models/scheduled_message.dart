import 'package:uuid/uuid.dart';

class ScheduledMessage {
  final String id;
  final String phone;
  final String contactName;
  final String message;
  final DateTime scheduledTime;
  final MessageStatus status;
  final String? workId;

  ScheduledMessage({
    String? id,
    required this.phone,
    required this.contactName,
    required this.message,
    required this.scheduledTime,
    this.status = MessageStatus.pending,
    this.workId,
  }) : id = id ?? const Uuid().v4();

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'contactName': contactName,
      'message': message,
      'scheduled_time': scheduledTime.millisecondsSinceEpoch,
      'status': status.name,
      'work_id': workId,
    };
  }

  // Create from JSON
  factory ScheduledMessage.fromJson(Map<String, dynamic> json) {
    return ScheduledMessage(
      id: json['id'],
      phone: json['phone'],
      contactName: json['contactName'] ?? '',
      message: json['message'],
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(json['scheduled_time']),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.pending,
      ),
      workId: json['work_id'],
    );
  }

  // Create a copy with updated fields
  ScheduledMessage copyWith({
    String? id,
    String? phone,
    String? contactName,
    String? message,
    DateTime? scheduledTime,
    MessageStatus? status,
    String? workId,
  }) {
    return ScheduledMessage(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      contactName: contactName ?? this.contactName,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      workId: workId ?? this.workId,
    );
  }

  @override
  String toString() {
    return 'ScheduledMessage(id: $id, phone: $phone, contactName: $contactName, scheduledTime: $scheduledTime, status: $status)';
  }
}

enum MessageStatus {
  pending,
  sent,
  failed,
  cancelled,
}