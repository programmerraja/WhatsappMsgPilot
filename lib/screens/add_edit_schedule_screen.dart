import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scheduled_message.dart';
import '../services/storage_service.dart';
import '../services/scheduling_service.dart';
import '../services/contact_service.dart';
import '../widgets/contact_picker_dialog.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final ScheduledMessage? scheduleToEdit;

  const AddEditScheduleScreen({super.key, this.scheduleToEdit});

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _messageController = TextEditingController();
  
  final StorageService _storageService = StorageService();
  final SchedulingService _schedulingService = SchedulingService();
  final ContactService _contactService = ContactService();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(minutes: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.scheduleToEdit != null;
    
    if (_isEditMode) {
      final schedule = widget.scheduleToEdit!;
      _phoneController.text = schedule.phone;
      _contactNameController.text = schedule.contactName;
      _messageController.text = schedule.message;
      _selectedDate = schedule.scheduledTime;
      _selectedTime = TimeOfDay.fromDateTime(schedule.scheduledTime);
    } else {
      // Default to 1 minute from now for new schedules
      final now = DateTime.now().add(const Duration(minutes: 1));
      _selectedDate = now;
      _selectedTime = TimeOfDay.fromDateTime(now);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _contactNameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectContact() async {
    try {
      final hasPermission = await _contactService.hasContactsPermission();
      if (!hasPermission) {
        final granted = await _contactService.requestContactsPermission();
        if (!granted) {
          _showErrorSnackBar('Contacts permission is required to select contacts');
          return;
        }
      }

      if (!mounted) return;
      
      final selectedContact = await showDialog<ContactInfo>(
        context: context,
        builder: (context) => const ContactPickerDialog(),
      );

      if (selectedContact != null && mounted) {
        setState(() {
          _phoneController.text = selectedContact.phoneNumber;
          _contactNameController.text = selectedContact.name;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load contacts: $e');
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date != null) {
      setState(() {
        _selectedDate = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate phone number
    if (!_contactService.isValidPhoneNumber(_phoneController.text)) {
      _showErrorSnackBar('Please enter a valid phone number');
      return;
    }

    // Check if scheduled time is in the future
    final now = DateTime.now();
    if (_selectedDate.isBefore(now)) {
      _showErrorSnackBar('Scheduled time must be in the future');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final schedule = ScheduledMessage(
        id: _isEditMode ? widget.scheduleToEdit!.id : null,
        phone: _contactService.cleanPhoneNumber(_phoneController.text),
        contactName: _contactNameController.text.trim(),
        message: _messageController.text.trim(),
        scheduledTime: _selectedDate,
        status: MessageStatus.pending,
      );

      String? workId;
      
      if (_isEditMode) {
        // Cancel old scheduled task
        if (widget.scheduleToEdit!.workId != null) {
          await _schedulingService.cancelScheduledMessage(widget.scheduleToEdit!.workId!);
        }
        
        // Schedule new task
        workId = await _schedulingService.scheduleMessage(schedule);
        
        // Update storage
        final updatedSchedule = schedule.copyWith(workId: workId);
        await _storageService.updateSchedule(updatedSchedule);
      } else {
        // Schedule new task
        workId = await _schedulingService.scheduleMessage(schedule);
        
        // Save to storage
        final newSchedule = schedule.copyWith(workId: workId);
        await _storageService.addSchedule(newSchedule);
      }

      setState(() => _isLoading = false);
      
      _showSuccessSnackBar(_isEditMode 
          ? 'Schedule updated successfully' 
          : 'Schedule created successfully');
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to save schedule: $e');
    }
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
        title: Text(_isEditMode ? 'Edit Schedule' : 'New Schedule'),
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildContactSection(),
              const SizedBox(height: 24),
              _buildMessageSection(),
              const SizedBox(height: 24),
              _buildDateTimeSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF25D366)),
                const SizedBox(width: 8),
                const Text(
                  'Contact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _selectContact,
                  icon: const Icon(Icons.contacts),
                  label: const Text('Select Contact'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactNameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => null, // Optional field
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '+91 9876543210',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.message, color: Color(0xFF25D366)),
                SizedBox(width: 8),
                Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                hintText: 'Enter your message here...',
              ),
              maxLines: 4,
              maxLength: 1000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Message is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule, color: Color(0xFF25D366)),
                SizedBox(width: 8),
                Text(
                  'Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                dateFormat.format(_selectedDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                timeFormat.format(_selectedDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveSchedule,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              _isEditMode ? 'Update Schedule' : 'Save Schedule',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}