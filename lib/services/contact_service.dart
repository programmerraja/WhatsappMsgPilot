import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  // Request permission to access contacts
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  // Check if contacts permission is granted
  Future<bool> hasContactsPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  // Get all contacts with phone numbers
  Future<List<ContactInfo>> getContacts() async {
    if (!await hasContactsPermission()) {
      final granted = await requestContactsPermission();
      if (!granted) {
        throw ContactPermissionException('Contacts permission not granted');
      }
    }

    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      
      List<ContactInfo> contactList = [];
      
      for (Contact contact in contacts) {
        if (contact.phones.isNotEmpty) {
          for (Phone phone in contact.phones) {
            if (phone.number.isNotEmpty) {
              contactList.add(ContactInfo(
                name: contact.displayName.isNotEmpty ? contact.displayName : 'Unknown',
                phoneNumber: cleanPhoneNumber(phone.number),
                label: phone.label.name,
              ));
            }
          }
        }
      }
      
      // Sort contacts alphabetically by name
      contactList.sort((a, b) => a.name.compareTo(b.name));
      
      return contactList;
    } catch (e) {
      throw ContactServiceException('Failed to fetch contacts: $e');
    }
  }

  // Search contacts by name or phone number
  Future<List<ContactInfo>> searchContacts(String query) async {
    final contacts = await getContacts();
    final lowercaseQuery = query.toLowerCase();
    
    return contacts.where((contact) {
      return contact.name.toLowerCase().contains(lowercaseQuery) ||
             contact.phoneNumber.contains(query);
    }).toList();
  }

  // Clean and format phone number
  String cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except + at the beginning
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If it starts with +, keep it, otherwise remove any leading +
    if (cleaned.startsWith('+')) {
      return cleaned;
    } else {
      cleaned = cleaned.replaceAll('+', '');
      
      // If it's an Indian number and doesn't start with +91, add it
      if (cleaned.length == 10 && !cleaned.startsWith('91')) {
        return '+91$cleaned';
      } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
        return '+$cleaned';
      }
      
      return cleaned.startsWith('+') ? cleaned : '+$cleaned';
    }
  }

  // Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    final cleaned = cleanPhoneNumber(phoneNumber);
    // Basic validation - should start with + and have at least 10 digits
    return RegExp(r'^\+\d{10,15}$').hasMatch(cleaned);
  }

  // Format phone number for display
  String formatPhoneNumberForDisplay(String phoneNumber) {
    final cleaned = cleanPhoneNumber(phoneNumber);
    
    // Format Indian numbers
    if (cleaned.startsWith('+91') && cleaned.length == 13) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 8)} ${cleaned.substring(8)}';
    }
    
    return cleaned;
  }
}

class ContactInfo {
  final String name;
  final String phoneNumber;
  final String label;

  ContactInfo({
    required this.name,
    required this.phoneNumber,
    required this.label,
  });

  @override
  String toString() {
    return '$name ($label): $phoneNumber';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactInfo &&
           other.name == name &&
           other.phoneNumber == phoneNumber;
  }

  @override
  int get hashCode => name.hashCode ^ phoneNumber.hashCode;
}

class ContactPermissionException implements Exception {
  final String message;
  ContactPermissionException(this.message);
  
  @override
  String toString() => 'ContactPermissionException: $message';
}

class ContactServiceException implements Exception {
  final String message;
  ContactServiceException(this.message);
  
  @override
  String toString() => 'ContactServiceException: $message';
}