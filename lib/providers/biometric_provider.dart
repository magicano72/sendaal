import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/biometric_service.dart';

/// Provider for BiometricService
final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);
