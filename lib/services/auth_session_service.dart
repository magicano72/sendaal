import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/models/user_model.dart';
import 'api_client.dart';

const String kAccessToken = 'access_token';
const String kRefreshToken = 'refresh_token';
const String kTokenExpiry = 'token_expires_at';
const String kPinHash = 'pin_hash';
const String kBiometricEnabled = 'biometric_enabled';
const String kUserId = 'user_id';
const String kDeviceId = 'device_id';
const String kUserDisplayName = 'user_display_name';
const String kPinAttempts = 'pin_attempts';
const String kPinLockUntil = 'pin_lock_until';

class PinVerificationResult {
  final bool isSuccess;
  final String? message;
  final int attemptsRemaining;
  final int? lockRemainingSeconds;

  const PinVerificationResult({
    required this.isSuccess,
    this.message,
    this.attemptsRemaining = 5,
    this.lockRemainingSeconds,
  });
}

class AuthSessionService {
  AuthSessionService._internal() {
    _apiClient.configureSessionPersistence(_persistSessionFromApiClient);
  }

  static final AuthSessionService instance = AuthSessionService._internal();

  static const int kMaxAttempts = 5;
  static const int kLockSeconds = 30;

  final ApiClient _apiClient = ApiClient.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _didLogUserDevicesAccessWarning = false;

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(),
  );

  Future<String> getInitialRoute() async {
    final refreshToken = await secureStorage.read(key: kRefreshToken);
    final pinHash = await secureStorage.read(key: kPinHash);

    if (refreshToken != null && pinHash != null) {
      return '/pin-login';
    }

    if (refreshToken != null && pinHash == null) {
      return '/pin-setup';
    }

    return '/login';
  }

  Future<void> storeAuthSession({
    required String accessToken,
    required String refreshToken,
    required int expiresMs,
  }) async {
    final expiry = DateTime.now()
        .add(Duration(milliseconds: expiresMs))
        .toUtc()
        .toIso8601String();

    await secureStorage.write(key: kAccessToken, value: accessToken);
    await secureStorage.write(key: kRefreshToken, value: refreshToken);
    await secureStorage.write(key: kTokenExpiry, value: expiry);

    _apiClient.setToken(
      accessToken,
      refreshToken: refreshToken,
      expiresInMs: expiresMs,
    );
  }

  Future<void> persistUser(User user) async {
    await secureStorage.write(key: kUserId, value: user.id);
    await secureStorage.write(
      key: kUserDisplayName,
      value: _displayNameFor(user),
    );
  }

  Future<String?> readStoredDisplayName() async {
    return secureStorage.read(key: kUserDisplayName);
  }

  Future<void> savePin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await secureStorage.write(key: kPinHash, value: hash);
  }

  Future<PinVerificationResult> verifyPin(String enteredPin) async {
    final lockUntilStr = await secureStorage.read(key: kPinLockUntil);
    if (lockUntilStr != null) {
      final lockUntil = DateTime.tryParse(lockUntilStr);
      if (lockUntil != null && DateTime.now().isBefore(lockUntil)) {
        final remaining = lockUntil.difference(DateTime.now()).inSeconds;
        return PinVerificationResult(
          isSuccess: false,
          message: 'Too many attempts. Try again in $remaining seconds.',
          lockRemainingSeconds: remaining,
          attemptsRemaining: 0,
        );
      }

      await secureStorage.delete(key: kPinLockUntil);
      await secureStorage.delete(key: kPinAttempts);
    }

    final storedHash = await secureStorage.read(key: kPinHash);
    final enteredHash = sha256.convert(utf8.encode(enteredPin)).toString();

    if (storedHash == null || enteredHash != storedHash) {
      final attempts =
          int.parse(await secureStorage.read(key: kPinAttempts) ?? '0') + 1;

      if (attempts >= kMaxAttempts) {
        final lockUntil = DateTime.now().add(
          const Duration(seconds: kLockSeconds),
        );
        await secureStorage.write(
          key: kPinLockUntil,
          value: lockUntil.toIso8601String(),
        );
        await secureStorage.write(key: kPinAttempts, value: '0');
        return const PinVerificationResult(
          isSuccess: false,
          message: 'Too many attempts. Locked for 30 seconds.',
          attemptsRemaining: 0,
          lockRemainingSeconds: kLockSeconds,
        );
      }

      await secureStorage.write(key: kPinAttempts, value: attempts.toString());
      final remaining = kMaxAttempts - attempts;
      return PinVerificationResult(
        isSuccess: false,
        message: 'Incorrect PIN. $remaining attempts remaining.',
        attemptsRemaining: remaining,
      );
    }

    await clearPinLockState();
    return const PinVerificationResult(isSuccess: true);
  }

  Future<void> clearPinLockState() async {
    await secureStorage.delete(key: kPinAttempts);
    await secureStorage.delete(key: kPinLockUntil);
  }

  Future<String?> validateOrRefreshToken() async {
    final accessToken = await secureStorage.read(key: kAccessToken);
    final expiryStr = await secureStorage.read(key: kTokenExpiry);
    final refreshToken = await secureStorage.read(key: kRefreshToken);

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    var isExpired = true;
    DateTime? expiry;
    if (expiryStr != null) {
      expiry = DateTime.tryParse(expiryStr);
      if (expiry != null) {
        isExpired = DateTime.now().isAfter(
          expiry.subtract(const Duration(minutes: 5)),
        );
      }
    }

    if (!isExpired) {
      _apiClient.setToken(
        accessToken,
        refreshToken: refreshToken,
        expiresAt: expiry,
      );
      return accessToken;
    }

    try {
      final response = await _apiClient.post(
        '/auth/refresh',
        body: {'refresh_token': refreshToken, 'mode': 'json'},
      );

      final data = response['data'] as Map<String, dynamic>;
      final newAccess = data['access_token'] as String;
      final newRefresh = data['refresh_token'] as String;
      final newExpiresMs = data['expires'] as int;

      await storeAuthSession(
        accessToken: newAccess,
        refreshToken: newRefresh,
        expiresMs: newExpiresMs,
      );

      return newAccess;
    } catch (error, stackTrace) {
      debugPrint('[AuthSessionService] Token refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> registerDevice({
    required String userId,
    required String accessToken,
  }) async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceMetadata = await _resolveDeviceMetadata(deviceInfoPlugin);

      await secureStorage.write(key: kDeviceId, value: deviceMetadata.deviceId);
      _apiClient.setToken(accessToken, refreshToken: await readRefreshToken());

      final existing = await _apiClient.get(
        '/items/user_device',
        queryParams: {
          'filter[user][_eq]': userId,
          'filter[device_id][_eq]': deviceMetadata.deviceId,
          'fields': 'id',
        },
      );

      final records = existing['data'] as List<dynamic>? ?? const [];
      final payload = {
        'user': userId,
        'device_id': deviceMetadata.deviceId,
        'device_name': deviceMetadata.deviceName,
        'platform': deviceMetadata.platform,
        'app_version': packageInfo.version,
        'is_active': true,
      };

      if (records.isEmpty) {
        await _apiClient.post('/items/user_device', body: payload);
      } else {
        final record = records.first as Map<String, dynamic>;
        await _apiClient.patch(
          '/items/user_device/${record['id']}',
          body: payload,
        );
      }
    } on ApiException catch (error) {
      if (_isUserDevicesAccessIssue(error)) {
        _logUserDevicesAccessWarningOnce('register device', error.message);
        return;
      }
      debugPrint('[AuthSessionService] Device registration failed: $error');
    } catch (error, stackTrace) {
      debugPrint('[AuthSessionService] Device registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> markDeviceInactive() async {
    try {
      final userId = await secureStorage.read(key: kUserId);
      final deviceId = await secureStorage.read(key: kDeviceId);
      if (userId == null || deviceId == null) {
        return;
      }

      final accessToken = await validateOrRefreshToken();
      if (accessToken == null) {
        return;
      }

      final existing = await _apiClient.get(
        '/items/user_device',
        queryParams: {
          'filter[user][_eq]': userId,
          'filter[device_id][_eq]': deviceId,
          'fields': 'id',
          'limit': '1',
        },
      );

      final records = existing['data'] as List<dynamic>? ?? const [];
      if (records.isEmpty) {
        return;
      }

      final record = records.first as Map<String, dynamic>;
      await _apiClient.patch(
        '/items/user_device/${record['id']}',
        body: {'is_active': false},
      );
    } on ApiException catch (error) {
      if (_isUserDevicesAccessIssue(error)) {
        _logUserDevicesAccessWarningOnce('mark device inactive', error.message);
        return;
      }
      debugPrint('[AuthSessionService] Mark device inactive failed: $error');
    } catch (error, stackTrace) {
      debugPrint('[AuthSessionService] Mark device inactive failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> logout() async {
    try {
      await markDeviceInactive();
      final refreshToken = await secureStorage.read(key: kRefreshToken);

      if (refreshToken != null) {
        await _apiClient.post(
          '/auth/logout',
          body: {'refresh_token': refreshToken, 'mode': 'json'},
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[AuthSessionService] Logout request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      await clearAllSecureState();
    }
  }

  Future<void> forceLogout() async {
    await clearAllSecureState();
  }

  Future<void> clearAllSecureState() async {
    await secureStorage.deleteAll();
    _apiClient.clearToken();
  }

  Future<String?> readRefreshToken() async {
    return secureStorage.read(key: kRefreshToken);
  }

  Future<bool> isBiometricEnabled() async {
    return (await secureStorage.read(key: kBiometricEnabled)) == 'true';
  }

  Future<bool> canUseBiometric() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return false;
    }

    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    if (!await canUseBiometric()) {
      return false;
    }

    try {
      return await _localAuth.authenticate(
        localizedReason: 'Log in to Sendaal',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[AuthSessionService] Biometric auth failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> toggleBiometric(bool enable) async {
    if (!enable) {
      await secureStorage.write(key: kBiometricEnabled, value: 'false');
      return true;
    }

    final authenticated = await authenticateWithBiometric();
    if (authenticated) {
      await secureStorage.write(key: kBiometricEnabled, value: 'true');
    }
    return authenticated;
  }

  String displayNameForUser(User? user, {String fallback = 'there'}) {
    if (user == null) {
      return fallback;
    }
    return _displayNameFor(user);
  }

  Future<void> _persistSessionFromApiClient({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    await secureStorage.write(key: kAccessToken, value: accessToken);
    await secureStorage.write(key: kRefreshToken, value: refreshToken);
    if (expiresAt != null) {
      await secureStorage.write(
        key: kTokenExpiry,
        value: expiresAt.toUtc().toIso8601String(),
      );
    }
  }

  Future<_DeviceMetadata> _resolveDeviceMetadata(
    DeviceInfoPlugin plugin,
  ) async {
    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return _DeviceMetadata(
        deviceId: (info.identifierForVendor ?? info.name).trim(),
        deviceName: info.name,
        platform: 'ios',
      );
    }

    final info = await plugin.androidInfo;
    final deviceId = info.id.trim().isNotEmpty
        ? info.id.trim()
        : '${info.brand}-${info.model}-${info.device}'.trim();
    return _DeviceMetadata(
      deviceId: deviceId,
      deviceName: '${info.brand} ${info.model}'.trim(),
      platform: 'android',
    );
  }

  String _displayNameFor(User user) {
    final firstName = user.firstName?.trim();
    if (firstName != null && firstName.isNotEmpty) {
      return firstName;
    }

    final displayName = user.displayName.trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }

    return user.username;
  }

  bool _isUserDevicesAccessIssue(ApiException error) {
    final message = error.message.toLowerCase();
    return (error.statusCode == 403 || error.statusCode == 404) &&
        message.contains('user_device');
  }

  void _logUserDevicesAccessWarningOnce(String action, String message) {
    if (_didLogUserDevicesAccessWarning) {
      return;
    }
    _didLogUserDevicesAccessWarning = true;
    debugPrint(
      '[AuthSessionService] Skipping $action because `user_devices` is not accessible for this role. Directus response: $message',
    );
  }
}

class _DeviceMetadata {
  final String deviceId;
  final String deviceName;
  final String platform;

  const _DeviceMetadata({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });
}
