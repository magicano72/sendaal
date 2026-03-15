import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/connectivity_service.dart';

class ConnectivityState {
  final bool isOnline;
  final bool isChecking;

  const ConnectivityState({
    required this.isOnline,
    this.isChecking = false,
  });

  ConnectivityState copyWith({
    bool? isOnline,
    bool? isChecking,
  }) => ConnectivityState(
    isOnline: isOnline ?? this.isOnline,
    isChecking: isChecking ?? this.isChecking,
  );

  bool get isOffline => !isOnline;
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier(this._service)
      : super(const ConnectivityState(isOnline: true, isChecking: true)) {
    _init();
  }

  final ConnectivityService _service;
  StreamSubscription<bool>? _subscription;

  Future<void> _init() async {
    final initial = await _service.hasInternetConnection();
    state = state.copyWith(isOnline: initial, isChecking: false);

    _subscription = _service.statusStream.listen((isOnline) {
      state = state.copyWith(isOnline: isOnline, isChecking: false);
    });
  }

  Future<bool> refreshStatus() async {
    final isOnline = await _service.hasInternetConnection();
    state = state.copyWith(isOnline: isOnline, isChecking: false);
    return isOnline;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      final service = ref.watch(connectivityServiceProvider);
      return ConnectivityNotifier(service);
    });
