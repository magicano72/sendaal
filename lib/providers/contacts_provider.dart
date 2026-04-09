import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/user_model.dart';
import '../models/access_request_model.dart';
import '../services/access_service.dart';
import '../services/device_contacts_service.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';

class DeviceContactView {
  final DeviceContact contact;
  final User? matchedUser;

  const DeviceContactView({required this.contact, this.matchedUser});

  bool get hasAccount => matchedUser != null;
}

class DeviceContactsState {
  final ContactsPermissionStatus permission;
  final bool isLoading;
  final bool isMatching;
  final List<DeviceContactView> contacts;
  final String? error;

  const DeviceContactsState({
    this.permission = ContactsPermissionStatus.unknown,
    this.isLoading = false,
    this.isMatching = false,
    this.contacts = const [],
    this.error,
  });

  DeviceContactsState copyWith({
    ContactsPermissionStatus? permission,
    bool? isLoading,
    bool? isMatching,
    List<DeviceContactView>? contacts,
    String? error,
    bool clearError = false,
  }) =>
      DeviceContactsState(
        permission: permission ?? this.permission,
        isLoading: isLoading ?? this.isLoading,
        isMatching: isMatching ?? this.isMatching,
        contacts: contacts ?? this.contacts,
        error: clearError ? null : error ?? this.error,
      );
}

class DeviceContactsNotifier extends StateNotifier<DeviceContactsState> {
  final DeviceContactsService _service;
  final UserService _userService;

  DeviceContactsNotifier(this._service, this._userService)
      : super(const DeviceContactsState());

  Future<ContactsPermissionStatus> bootstrap() async {
    final status = await _service.bootstrapPermission();
    state = state.copyWith(permission: status);
    if (status == ContactsPermissionStatus.granted) {
      await loadContacts();
    }
    return status;
  }

  Future<ContactsPermissionStatus> refreshPermission() async {
    final status = await _service.checkPermission();
    state = state.copyWith(permission: status);
    return status;
  }

  Future<ContactsPermissionStatus> requestPermission() async {
    final status = await _service.requestPermission();
    state = state.copyWith(permission: status);
    if (status == ContactsPermissionStatus.granted) {
      await loadContacts();
    }
    return status;
  }

  Future<void> loadContacts() async {
    if (state.permission != ContactsPermissionStatus.granted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final device = await _service.getDeviceContacts();
      final matched = await _matchWithUsers(device);
      state = state.copyWith(isLoading: false, contacts: matched);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load contacts: $e',
      );
    }
  }

  Future<List<DeviceContactView>> _matchWithUsers(
    List<DeviceContact> contacts,
  ) async {
    state = state.copyWith(isMatching: true);
    try {
      final phoneMap = await _userService.findUsersByPhoneNumbers(
        contacts.map((c) => c.phone).toList(),
      );
      final results = contacts
          .map(
            (c) => DeviceContactView(
              contact: c,
              matchedUser: phoneMap[c.phone],
            ),
          )
          .toList();
      state = state.copyWith(isMatching: false);
      return results;
    } catch (e) {
      state = state.copyWith(isMatching: false);
      return contacts
          .map((c) => DeviceContactView(contact: c, matchedUser: null))
          .toList();
    }
  }
}

final deviceContactsProvider =
    StateNotifierProvider<DeviceContactsNotifier, DeviceContactsState>(
  (ref) => DeviceContactsNotifier(
    DeviceContactsService(),
    UserService(),
  ),
);

class ApprovedContact {
  final User user;
  final AccessRequest request;

  const ApprovedContact({required this.user, required this.request});

  bool get isFavorite => request.isFavorite;
}

class ContactsState {
  final bool isLoading;
  final List<ApprovedContact> contacts;
  final String? error;

  const ContactsState({
    this.isLoading = false,
    this.contacts = const [],
    this.error,
  });

  ContactsState copyWith({
    bool? isLoading,
    List<ApprovedContact>? contacts,
    String? error,
    bool clearError = false,
  }) =>
      ContactsState(
        isLoading: isLoading ?? this.isLoading,
        contacts: contacts ?? this.contacts,
        error: clearError ? null : error ?? this.error,
      );
}

class ContactsNotifier extends StateNotifier<ContactsState> {
  final AccessService _accessService;
  final Ref _ref;

  ContactsNotifier(this._accessService, this._ref)
      : super(const ContactsState());

  Future<void> load() async {
    final currentUser = _ref.read(authProvider).user;
    if (currentUser == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final raw = await _accessService.getApprovedConnections(currentUser.id);
      final list = <ApprovedContact>[];

      for (final item in raw) {
        final request = AccessRequest.fromJson(item);
        final requesterJson = item['requester'];
        final receiverJson = item['receiver'];
        if (requesterJson is! Map || receiverJson is! Map) continue;

        final requester =
            User.fromJson(Map<String, dynamic>.from(requesterJson));
        final receiver = User.fromJson(Map<String, dynamic>.from(receiverJson));
        final otherUser = request.requesterId == currentUser.id
            ? receiver
            : requester;

        list.add(ApprovedContact(user: otherUser, request: request));
      }

      state = state.copyWith(isLoading: false, contacts: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load contacts: $e',
      );
    }
  }

  Future<void> toggleFavorite(String requestId, bool isFavorite) async {
    try {
      final updated = await _accessService.updateFavorite(
        requestId,
        isFavorite: isFavorite,
      );
      state = state.copyWith(
        contacts: state.contacts
            .map(
              (c) => c.request.id == requestId
                  ? ApprovedContact(user: c.user, request: updated)
                  : c,
            )
            .toList(),
      );
    } catch (_) {}
  }
}

final contactsProvider =
    StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
      return ContactsNotifier(AccessService(), ref);
    });
