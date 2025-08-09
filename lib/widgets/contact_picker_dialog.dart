import 'package:flutter/material.dart';
import '../services/contact_service.dart';

class ContactPickerDialog extends StatefulWidget {
  const ContactPickerDialog({super.key});

  @override
  State<ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<ContactPickerDialog> {
  final ContactService _contactService = ContactService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ContactInfo> _allContacts = [];
  List<ContactInfo> _filteredContacts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => _isLoading = true);
      
      final contacts = await _contactService.getContacts();
      
      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts
            .where((contact) =>
                contact.name.toLowerCase().contains(query.toLowerCase()) ||
                contact.phoneNumber.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchField(),
            const SizedBox(height: 16),
            Expanded(child: _buildContactsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.contacts,
          color: Color(0xFF25D366),
          size: 24,
        ),
        const SizedBox(width: 8),
        const Text(
          'Select Contact',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search contacts...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _filterContacts('');
                },
                icon: const Icon(Icons.clear),
              )
            : null,
      ),
      onChanged: _filterContacts,
    );
  }

  Widget _buildContactsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_allContacts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.contacts,
        title: 'No contacts found',
        subtitle: 'Make sure you have contacts saved on your device',
      );
    }

    if (_filteredContacts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No matching contacts',
        subtitle: 'Try a different search term',
      );
    }

    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return _buildContactTile(contact);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(ContactInfo contact) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF25D366),
          child: Text(
            contact.name.isNotEmpty 
                ? contact.name[0].toUpperCase() 
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _contactService.formatPhoneNumberForDisplay(contact.phoneNumber),
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            if (contact.label.isNotEmpty)
              Text(
                contact.label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF25D366),
        ),
        onTap: () => Navigator.pop(context, contact),
      ),
    );
  }
}