import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoSendEnabled = true;
  bool _notificationsEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load settings from shared preferences
    // For now, using default values
    setState(() {
      _autoSendEnabled = true;
      _notificationsEnabled = true;
    });
  }

  Future<void> _saveSettings() async {
    // TODO: Save settings to shared preferences
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      // Show dialog explaining how to enable accessibility service
      _showAccessibilityDialog();
    } catch (e) {
      _showErrorSnackBar('Failed to open accessibility settings');
    }
  }

  void _showAccessibilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Accessibility Service'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To automatically send WhatsApp messages, you need to enable the accessibility service:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '1. Go to Settings > Accessibility',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '2. Find "WhatsApp Scheduler" in the list',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '3. Turn on the accessibility service',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '4. Grant the necessary permissions',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openSystemAccessibilitySettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSystemAccessibilitySettings() async {
    // This would open the system accessibility settings
    // For now, just show a message
    _showInfoSnackBar('Please manually navigate to Settings > Accessibility');
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      _showSuccessSnackBar('Notification permission granted');
    } else {
      _showErrorSnackBar('Notification permission denied');
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'WhatsApp Scheduler',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.schedule_send,
        size: 64,
        color: Color(0xFF25D366),
      ),
      children: [
        const Text(
          'Schedule WhatsApp messages to be sent automatically at a specific time.',
        ),
        const SizedBox(height: 16),
        const Text(
          'This app uses the accessibility service to automatically send messages. Please ensure you grant the necessary permissions.',
        ),
      ],
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Message Settings',
            children: [
              _buildSwitchTile(
                title: 'Auto Send Messages',
                subtitle: 'Automatically send scheduled messages',
                value: _autoSendEnabled,
                onChanged: (value) {
                  setState(() => _autoSendEnabled = value);
                  _saveSettings();
                },
              ),
              _buildTile(
                title: 'Accessibility Service',
                subtitle: 'Required for automatic message sending',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _openAccessibilitySettings,
              ),
            ],
          ),
          _buildSection(
            title: 'Notifications',
            children: [
              _buildSwitchTile(
                title: 'Enable Notifications',
                subtitle: 'Get notified when messages are sent',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  if (value) {
                    _requestNotificationPermission();
                  }
                  _saveSettings();
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Permissions',
            children: [
              _buildTile(
                title: 'Contacts Permission',
                subtitle: 'Access contacts for easy selection',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final status = await Permission.contacts.request();
                  if (status.isGranted) {
                    _showSuccessSnackBar('Contacts permission granted');
                  } else {
                    _showErrorSnackBar('Contacts permission denied');
                  }
                },
              ),
              _buildTile(
                title: 'Notification Permission',
                subtitle: 'Show notifications for scheduled messages',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _requestNotificationPermission,
              ),
            ],
          ),
          _buildSection(
            title: 'Support',
            children: [
              _buildTile(
                title: 'Help & FAQ',
                subtitle: 'Get help with using the app',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showInfoSnackBar('Help documentation coming soon');
                },
              ),
              _buildTile(
                title: 'Report a Bug',
                subtitle: 'Let us know about any issues',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showInfoSnackBar('Bug reporting feature coming soon');
                },
              ),
            ],
          ),
          _buildSection(
            title: 'About',
            children: [
              _buildTile(
                title: 'About WhatsApp Scheduler',
                subtitle: 'Version, licenses, and more',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showAboutDialog,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      activeColor: const Color(0xFF25D366),
      onChanged: onChanged,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'WhatsApp Scheduler v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Made with ❤️ for personal use',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}