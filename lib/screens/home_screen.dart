import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scheduled_message.dart';
import '../services/storage_service.dart';
import '../services/scheduling_service.dart';
import 'add_edit_schedule_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  final SchedulingService _schedulingService = SchedulingService();
  List<ScheduledMessage> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      setState(() => _isLoading = true);
      final schedules = await _storageService.loadSchedules();
      
      // Sort by scheduled time (upcoming first)
      schedules.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load schedules: $e');
    }
  }

  Future<void> _deleteSchedule(ScheduledMessage schedule) async {
    try {
      // Cancel the scheduled task
      if (schedule.workId != null) {
        await _schedulingService.cancelScheduledMessage(schedule.workId!);
      }
      
      // Remove from storage
      await _storageService.deleteSchedule(schedule.id);
      
      // Refresh the list
      await _loadSchedules();
      
      _showSuccessSnackBar('Schedule deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete schedule: $e');
    }
  }

  void _showDeleteConfirmation(ScheduledMessage schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Are you sure you want to delete the message to ${schedule.contactName.isNotEmpty ? schedule.contactName : schedule.phone}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSchedule(schedule);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddSchedule() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditScheduleScreen(),
      ),
    );
    
    if (result == true) {
      _loadSchedules();
    }
  }

  void _navigateToEditSchedule(ScheduledMessage schedule) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditScheduleScreen(
          scheduleToEdit: schedule,
        ),
      ),
    );
    
    if (result == true) {
      _loadSchedules();
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Scheduler'),
        backgroundColor: const Color(0xFF25D366), // WhatsApp green
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? _buildEmptyState()
              : _buildSchedulesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSchedule,
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_send,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No scheduled messages',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to schedule your first message',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList() {
    return RefreshIndicator(
      onRefresh: _loadSchedules,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _schedules.length,
        itemBuilder: (context, index) {
          final schedule = _schedules[index];
          return _buildScheduleCard(schedule);
        },
      ),
    );
  }

  Widget _buildScheduleCard(ScheduledMessage schedule) {
    final now = DateTime.now();
    final isOverdue = schedule.scheduledTime.isBefore(now);
    final timeFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: Dismissible(
        key: Key(schedule.id),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 24,
          ),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          _showDeleteConfirmation(schedule);
          return false; // Don't auto-dismiss, let the dialog handle it
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: isOverdue ? Colors.red : const Color(0xFF25D366),
            child: Icon(
              isOverdue ? Icons.warning : Icons.schedule,
              color: Colors.white,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  schedule.contactName.isNotEmpty 
                      ? schedule.contactName 
                      : schedule.phone,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildStatusChip(schedule.status),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                schedule.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeFormat.format(schedule.scheduledTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: isOverdue ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _navigateToEditSchedule(schedule);
                  break;
                case 'delete':
                  _showDeleteConfirmation(schedule);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
          onTap: () => _navigateToEditSchedule(schedule),
        ),
      ),
    );
  }

  Widget _buildStatusChip(MessageStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case MessageStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case MessageStatus.sent:
        color = Colors.green;
        text = 'Sent';
        break;
      case MessageStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
      case MessageStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}