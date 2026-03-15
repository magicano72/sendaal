import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Permission state for device contacts.
enum ContactsPermissionStatus { unknown, granted, denied }

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
  static const _prefAskedKey = 'contacts_permission_requested_v1';

  /// Ask for contacts permission on first launch and remember the prompt state.
  Future<ContactsPermissionStatus> bootstrapPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(_prefAskedKey) ?? false;

    if (!alreadyAsked) {
      await prefs.setBool(_prefAskedKey, true);
      return requestPermission();
    }

    // If we already asked before, just check current status without forcing UI
    final granted = await FlutterContacts.requestPermission(readonly: true);
    return granted
        ? ContactsPermissionStatus.granted
        : ContactsPermissionStatus.denied;
  }

  /// Prompt the user for contacts access.
  Future<ContactsPermissionStatus> requestPermission() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    return granted
        ? ContactsPermissionStatus.granted
        : ContactsPermissionStatus.denied;
  }

  /// Fetch device contacts (single primary phone per contact).
  Future<List<DeviceContact>> getDeviceContacts() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) return [];

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

  String _normalizePhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    // Collapse leading zeros/spaces; keep + if present.
    if (cleaned.startsWith('+')) return cleaned;
    return cleaned;
  }
}
