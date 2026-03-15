import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/exceptions.dart';
import '../core/repositories/access_request_repository.dart';
import '../models/access_request_model.dart';
import '../services/access_service.dart';
import 'auth_provider.dart';
import 'contacts_provider.dart';

/// Provider for AccessService
final accessServiceProvider = Provider<AccessService>((ref) => AccessService());

/// Provider for AccessRequestRepository
final accessRequestRepositoryProvider = Provider<AccessRequestRepository>((
  ref,
) {
  return AccessRequestRepository(ref.read(accessServiceProvider));
});

/// State for access requests
class AccessRequestsState {
  final List<AccessRequest> receivedRequests;
  final List<AccessRequest> sentRequests;
  final bool isLoading;
  final bool isCreating;
  final String? error;

  const AccessRequestsState({
    this.receivedRequests = const [],
    this.sentRequests = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.error,
  });

  AccessRequestsState copyWith({
    List<AccessRequest>? receivedRequests,
    List<AccessRequest>? sentRequests,
    bool? isLoading,
    bool? isCreating,
    String? error,
    bool clearError = false,
  }) => AccessRequestsState(
    receivedRequests: receivedRequests ?? this.receivedRequests,
    sentRequests: sentRequests ?? this.sentRequests,
    isLoading: isLoading ?? this.isLoading,
    isCreating: isCreating ?? this.isCreating,
    error: clearError ? null : error ?? this.error,
  );
}

/// Notifier for managing access request state
class AccessRequestNotifier extends StateNotifier<AccessRequestsState> {
  final AccessRequestRepository _repository;
  final Ref _ref;

  AccessRequestNotifier(this._repository, this._ref)
    : super(const AccessRequestsState());

  /// Load all received access requests for current user
  Future<void> loadReceivedRequests(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final requests = await _repository.getReceivedRequests(userId);
      state = state.copyWith(isLoading: false, receivedRequests: requests);
    } catch (e) {
      print('[AccessRequestNotifier] Error loading requests: $e');
      String errorMessage = 'Failed to load access requests';
      if (e is ApiException) {
        errorMessage = e.message;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Load all sent access requests by current user
  Future<void> loadSentRequests(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final requests = await _repository.getSentRequests(userId);
      state = state.copyWith(isLoading: false, sentRequests: requests);
    } catch (e) {
      print('[AccessRequestNotifier] Error loading sent requests: $e');
      String errorMessage = 'Failed to load sent requests';
      if (e is ApiException) {
        errorMessage = e.message;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Check if user can send a request to receiver
  /// Returns (canSend, reason) where reason is error message if canSend=false
  /// Enforces: single active request rule + 1-hour cooldown + 3-rejection limit
  Future<(bool, String?)> canSendRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    try {
      final service = _ref.read(accessServiceProvider);

      // Guard: block duplicate pending requests for this sender → receiver
      final pendingRequest = await service.getPendingRequest(
        requesterId: requesterId,
        receiverId: receiverId,
      );

      if (pendingRequest != null) {
        return (
          false,
          'You already have a pending request. Please wait for approval or cancel it first.',
        );
      }

      // Check 1: Single active request rule (pending or approved)
      final activeRequest = await service.getActiveRequest(
        requesterId: requesterId,
        receiverId: receiverId,
      );
      if (activeRequest != null) {
        if (activeRequest.status == AccessStatus.approved) {
          return (false, 'You already have access to this user\'s accounts.');
        } else {
          return (
            false,
            'You already have a pending request. Please wait for approval or cancel it first.',
          );
        }
      }

      // Check 2: 3-rejection limit
      final rejectionCount = await service.getRejectionCount(
        requesterId: requesterId,
        receiverId: receiverId,
      );
      if (rejectionCount >= 3) {
        return (
          false,
          'Cannot send request: You have been rejected 3 times by this user.',
        );
      }

      // Check 3: 1-hour cooldown between rejected requests
      final lastRequest = await service.getLastSentRequest(
        requesterId: requesterId,
        receiverId: receiverId,
      );

      if (lastRequest != null) {
        final now = DateTime.now();
        final timeSinceLastRequest = now.difference(lastRequest.createdAt);
        const cooldownDuration = Duration(hours: 1);

        // If last request was rejected within 1 hour
        if (timeSinceLastRequest < cooldownDuration &&
            lastRequest.status == AccessStatus.rejected) {
          final minutesLeft =
              (cooldownDuration.inMinutes - timeSinceLastRequest.inMinutes)
                  .toStringAsFixed(0);
          return (
            false,
            'Please wait $minutesLeft minutes before sending another request.',
          );
        }
      }

      return (true, null);
    } catch (e) {
      print('[AccessRequestNotifier] Error checking request eligibility: $e');
      return (true, null); // Allow request if check fails
    }
  }

  /// Create a new access request with validation
  Future<(bool, String?)> createAccessRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    // Check if user can send request
    final (canSend, reason) = await canSendRequest(
      requesterId: requesterId,
      receiverId: receiverId,
    );

    if (!canSend) {
      return (false, reason);
    }

    state = state.copyWith(isCreating: true, clearError: true);
    try {
      print('[AccessRequestNotifier] Starting to create access request...');
      print(
        '[AccessRequestNotifier] Requester: $requesterId, Receiver: $receiverId',
      );

      final rejectionCount = await _ref
          .read(accessServiceProvider)
          .getRejectionCount(requesterId: requesterId, receiverId: receiverId);

      print('[AccessRequestNotifier] Rejection count: $rejectionCount');

      final request = await _repository.createAccessRequest(
        requesterId: requesterId,
        receiverId: receiverId,
        rejectionCount: rejectionCount,
      );
      print('[AccessRequestNotifier] Access request created: ${request.id}');

      // Add to sent requests list
      state = state.copyWith(
        isCreating: false,
        sentRequests: [...state.sentRequests, request],
      );

      // Invalidate sentRequestsProvider to refresh UI with new request
      _ref.invalidate(sentRequestsProvider);

      return (true, null);
    } catch (e) {
      print('[AccessRequestNotifier] Error creating request: $e');
      print('[AccessRequestNotifier] Error type: ${e.runtimeType}');
      String errorMessage = 'Failed to create access request';
      if (e is ApiException) {
        errorMessage = e.message;
      }
      state = state.copyWith(isCreating: false, error: errorMessage);
      return (false, errorMessage);
    }
  }

  /// Approve an access request
  Future<bool> approveRequest(String requestId) async {
    try {
      final approved = await _repository.approveRequest(requestId);
      print('[AccessRequestNotifier] Request approved: $requestId');

      // Update the request in the list
      state = state.copyWith(
        receivedRequests: [
          for (final req in state.receivedRequests)
            if (req.id == requestId) approved else req,
        ],
      );

      // Refresh contacts so approved users appear immediately
      try {
        await _ref.read(contactsProvider.notifier).load();
      } catch (_) {}
      return true;
    } catch (e) {
      print('[AccessRequestNotifier] Error approving request: $e');
      String errorMessage = 'Failed to approve request';
      if (e is ApiException) {
        errorMessage = e.message;
      }
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// Reject an access request
  Future<bool> rejectRequest(String requestId) async {
    try {
      final rejected = await _repository.rejectRequest(requestId);
      print('[AccessRequestNotifier] Request rejected: $requestId');

      // Update the request in the list
      state = state.copyWith(
        receivedRequests: [
          for (final req in state.receivedRequests)
            if (req.id == requestId) rejected else req,
        ],
      );
      return true;
    } catch (e) {
      print('[AccessRequestNotifier] Error rejecting request: $e');
      String errorMessage = 'Failed to reject request';
      if (e is ApiException) {
        errorMessage = e.message;
      }
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// Cancel a pending access request (sender side)
  Future<bool> cancelRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    try {
      print(
        '[AccessRequestNotifier] Cancelling request: requester=$requesterId, receiver=$receiverId',
      );

      final service = _ref.read(accessServiceProvider);

      // Find the pending request
      final pendingRequest = await service.getPendingRequest(
        requesterId: requesterId,
        receiverId: receiverId,
      );

      if (pendingRequest == null) {
        print('[AccessRequestNotifier] No pending request found to cancel');
        return false;
      }

      // Delete the request
      await service.deleteRequest(pendingRequest.id);
      print('[AccessRequestNotifier] Request cancelled: ${pendingRequest.id}');

      // Remove from sent requests list
      state = state.copyWith(
        sentRequests: [
          for (final req in state.sentRequests)
            if (req.id != pendingRequest.id) req,
        ],
      );

      // Invalidate sentRequestsProvider to refresh UI
      _ref.invalidate(sentRequestsProvider);

      return true;
    } catch (e) {
      print('[AccessRequestNotifier] Error cancelling request: $e');
      String errorMessage = 'Failed to cancel request';
      if (e is ApiException) {
        errorMessage = e.message;
      }
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// Hide/clear a request card from UI (requester or receiver side)
  /// Only allowed when status is approved or rejected
  Future<bool> hideRequest({
    required String requestId,
    required bool isReceived,
  }) async {
    final existing = isReceived
        ? state.receivedRequests.firstWhere(
            (r) => r.id == requestId,
            orElse: () => AccessRequest(
              id: '',
              requesterId: '',
              receiverId: '',
              status: AccessStatus.pending,
              createdAt: DateTime.now(),
            ),
          )
        : state.sentRequests.firstWhere(
            (r) => r.id == requestId,
            orElse: () => AccessRequest(
              id: '',
              requesterId: '',
              receiverId: '',
              status: AccessStatus.pending,
              createdAt: DateTime.now(),
            ),
          );

    if (existing.id.isEmpty || !existing.canHide) return false;

    final prevReceived = state.receivedRequests;
    final prevSent = state.sentRequests;

    // Optimistically remove from UI
    state = state.copyWith(
      receivedRequests: isReceived
          ? prevReceived.where((r) => r.id != requestId).toList()
          : prevReceived,
      sentRequests: isReceived
          ? prevSent
          : prevSent.where((r) => r.id != requestId).toList(),
    );

    try {
      if (isReceived) {
        await _repository.hideForReceiver(requestId);
      } else {
        await _repository.hideForRequester(requestId);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        receivedRequests: prevReceived,
        sentRequests: prevSent,
        error: e is ApiException ? e.message : 'Failed to hide request',
      );
      return false;
    }
  }
}

/// Provider for access request state
final accessRequestProvider =
    StateNotifierProvider<AccessRequestNotifier, AccessRequestsState>((ref) {
      return AccessRequestNotifier(
        ref.read(accessRequestRepositoryProvider),
        ref,
      );
    });

/// Utility provider to check if a user has access to another user's accounts
/// Returns true only if there's an approved access request from requester to receiver
final hasAccessToAccountsProvider = FutureProvider.family<bool, String>((
  ref,
  otherUserId,
) async {
  final currentUser = ref.watch(authProvider).user;
  if (currentUser == null) return false;

  try {
    final service = ref.read(accessServiceProvider);
    final approved = await service.getApprovedRequestBetween(
      userA: currentUser.id,
      userB: otherUserId,
    );
    return approved != null;
  } catch (e) {
    print('[hasAccessToAccountsProvider] Error checking access: $e');
    return false;
  }
});

/// Get a specific access request by ID
final getAccessRequestProvider = FutureProvider.family<AccessRequest?, String>((
  ref,
  requestId,
) async {
  final requests = ref.watch(accessRequestProvider).receivedRequests;
  try {
    return requests.firstWhere((req) => req.id == requestId);
  } catch (e) {
    return null;
  }
});

/// Check if a user can send a request to a specific receiver
/// Returns (canSend, reason) where reason is error if canSend=false
final canSendRequestProvider =
    FutureProvider.family<(bool, String?), (String, String)>((
      ref,
      params,
    ) async {
      final (requesterId, receiverId) = params;
      final notifier = ref.read(accessRequestProvider.notifier);
      return notifier.canSendRequest(
        requesterId: requesterId,
        receiverId: receiverId,
      );
    });

/// Get the last sent request from requester to receiver
final getLastSentRequestProvider =
    FutureProvider.family<AccessRequest?, (String, String)>((
      ref,
      params,
    ) async {
      final (requesterId, receiverId) = params;
      final service = ref.read(accessServiceProvider);
      return service.getLastSentRequest(
        requesterId: requesterId,
        receiverId: receiverId,
      );
    });

/// Rejection count for a requester → receiver pair
final rejectionCountProvider =
    FutureProvider.family<int, (String, String)>((ref, params) async {
      final (requesterId, receiverId) = params;
      final service = ref.read(accessServiceProvider);
      return service.getRejectionCount(
        requesterId: requesterId,
        receiverId: receiverId,
      );
    });

/// Provider to get all sent requests for current user
final sentRequestsProvider = FutureProvider<List<AccessRequest>>((ref) async {
  final currentUser = ref.watch(authProvider).user;
  if (currentUser == null) return [];

  try {
    final repository = ref.read(accessRequestRepositoryProvider);
    return repository.getSentRequests(currentUser.id);
  } catch (e) {
    print('[sentRequestsProvider] Error fetching sent requests: $e');
    return [];
  }
});
