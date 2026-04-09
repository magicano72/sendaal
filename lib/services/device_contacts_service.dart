import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission state for device contacts.
enum ContactsPermissionStatus {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

/// Lightweight representation of a device contact (one primary phone per entry).
class DeviceContact {
  final String id;
  final String name;
  final String phone;

  const DeviceContact({
    required this.id,
    required this.name,
    required this.phone,
  });
}

/// Handles permission requests and contact retrieval from the device.
class DeviceContactsService {
  /// Check current permission state without prompting the user.
  Future<ContactsPermissionStatus> bootstrapPermission() async {
    return checkPermission();
  }

  /// Check current status without showing a system dialog.
  Future<ContactsPermissionStatus> checkPermission() async {
    final status = await Permission.contacts.status;
    return _mapStatus(status);
  }

  /// Prompt the user for contacts access.
  Future<ContactsPermissionStatus> requestPermission() async {
    final status = await Permission.contacts.request();
    return _mapStatus(status);
  }

  /// Fetch device contacts (single primary phone per contact).
  Future<List<DeviceContact>> getDeviceContacts() async {
    final status = await checkPermission();
    if (status != ContactsPermissionStatus.granted) return [];

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    final result = <DeviceContact>[];

    for (final contact in contacts) {
      if (contact.phones.isEmpty) continue;
      final phone = _normalizePhone(contact.phones.first.number);
      if (phone.isEmpty) continue;

      final name = contact.displayName.trim().isNotEmpty
          ? contact.displayName.trim()
          : (contact.name.first + ' ' + contact.name.last).trim();

      result.add(
        DeviceContact(
          id: contact.id,
          name: name.isNotEmpty ? name : 'Unknown',
          phone: phone,
        ),
      );
    }

    return result;
  }

  ContactsPermissionStatus _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return ContactsPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return ContactsPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) {
      return ContactsPermissionStatus.restricted;
    }
    return ContactsPermissionStatus.denied;
  }

  String _normalizePhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    // Collapse leading zeros/spaces; keep + if present.
    if (cleaned.startsWith('+')) return cleaned;
    return cleaned;
  }
}
