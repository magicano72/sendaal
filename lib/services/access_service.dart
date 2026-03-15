import '../models/access_request_model.dart';
import 'api_client.dart';
import 'endpoint.dart';

/// Handles access request creation and management
class AccessService {
  final ApiClient _api;

  AccessService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient.instance;

  /// Send a new access request from requester to receiver
  Future<AccessRequest> createRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    final response = await _api.post(
      Endpoints.accessRequests,
      body: {
        'requester': requesterId,
        'receiver': receiverId,
        'status': 'pending',
        'visible_for_requester': true,
        'visible_for_receiver': true,
      },
    );
    return AccessRequest.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Approve or reject an incoming request
  Future<AccessRequest> updateStatus({
    required String requestId,
    required String status, // 'approved' | 'rejected'
  }) async {
    final response = await _api.patch(
      Endpoints.accessRequestById(requestId),
      body: {'status': status},
    );
    return AccessRequest.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Get all requests received by a user (receiver perspective)
  Future<List<AccessRequest>> getReceivedRequests(
    String userId, {
    bool includeHidden = false,
  }) async {
    final response = await _api.get(
      Endpoints.accessRequests,
      queryParams: {
        'filter[receiver][_eq]': userId,
        if (!includeHidden) 'filter[visible_for_receiver][_eq]': 'true',
      },
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AccessRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all requests sent by a user (requester perspective)
  Future<List<AccessRequest>> getSentRequests(
    String userId, {
    bool includeHidden = false,
  }) async {
    final response = await _api.get(
      Endpoints.accessRequests,
      queryParams: {
        'filter[requester][_eq]': userId,
        if (!includeHidden) 'filter[visible_for_requester][_eq]': 'true',
      },
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AccessRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get rejection count for a requester-receiver pair
  Future<int> getRejectionCount({
    required String requesterId,
    required String receiverId,
  }) async {
    final response = await _api.get(
      Endpoints.accessRequests,
      queryParams: {
        'filter[requester][_eq]': requesterId,
        'filter[receiver][_eq]': receiverId,
        'filter[status][_eq]': 'rejected',
      },
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list.length;
  }

  /// Get last request sent to a receiver
  Future<AccessRequest?> getLastSentRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.accessRequests,
        queryParams: {
          'filter[requester][_eq]': requesterId,
          'filter[receiver][_eq]': receiverId,
          'sort': '-created_at',
          'limit': '1',
        },
      );
      final list = response['data'] as List<dynamic>? ?? [];
      if (list.isEmpty) return null;
      return AccessRequest.fromJson(list[0] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Find pending request between requester and receiver
  Future<AccessRequest?> getPendingRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.accessRequests,
        queryParams: {
          'filter[requester][_eq]': requesterId,
          'filter[receiver][_eq]': receiverId,
          'filter[status][_eq]': 'pending',
          'limit': '1',
        },
      );
      final list = response['data'] as List<dynamic>? ?? [];
      if (list.isEmpty) return null;
      return AccessRequest.fromJson(list[0] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Find an approved request between two users, regardless of direction.
  /// Returns the first matching approved request or null if none exists.
  Future<AccessRequest?> getApprovedRequestBetween({
    required String userA,
    required String userB,
  }) async {
    final response = await _api.get(
      Endpoints.accessRequests,
      queryParams: {
        'filter[_or][0][_and][0][requester][_eq]': userA,
        'filter[_or][0][_and][1][receiver][_eq]': userB,
        'filter[_or][0][_and][2][status][_eq]': 'approved',
        'filter[_or][1][_and][0][requester][_eq]': userB,
        'filter[_or][1][_and][1][receiver][_eq]': userA,
        'filter[_or][1][_and][2][status][_eq]': 'approved',
        'limit': '1',
        'sort': '-created_at',
      },
    );

    final list = response['data'] as List<dynamic>? ?? [];
    if (list.isEmpty) return null;
    return AccessRequest.fromJson(list.first as Map<String, dynamic>);
  }

  /// Find active request (pending or approved) between requester and receiver
  /// Only one active request allowed per sender → receiver pair
  Future<AccessRequest?> getActiveRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.accessRequests,
        queryParams: {
          'filter[requester][_eq]': requesterId,
          'filter[receiver][_eq]': receiverId,
          'filter[status][_in]': 'pending,approved',
          'limit': '1',
        },
      );
      final list = response['data'] as List<dynamic>? ?? [];
      if (list.isEmpty) return null;
      return AccessRequest.fromJson(list[0] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Delete/Cancel an access request
  Future<void> deleteRequest(String requestId) async {
    await _api.delete(Endpoints.accessRequestById(requestId));
  }

  /// Hide a request for the requester (UI clear)
  Future<AccessRequest> hideForRequester(String requestId) async {
    final response = await _api.patch(
      Endpoints.accessRequestById(requestId),
      body: {'visible_for_requester': false},
    );
    return AccessRequest.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Hide a request for the receiver (UI clear)
  Future<AccessRequest> hideForReceiver(String requestId) async {
    final response = await _api.patch(
      Endpoints.accessRequestById(requestId),
      body: {'visible_for_receiver': false},
    );
    return AccessRequest.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Fetch approved access requests where the current user is requester or receiver.
  /// Used to build the "My Contacts" list.
  Future<List<Map<String, dynamic>>> getApprovedConnections(
    String userId,
  ) async {
    final response = await _api.get(
      Endpoints.accessRequests,
      queryParams: {
        'filter[_and][0][status][_eq]': 'approved',
        'filter[_and][1][_or][0][requester][_eq]': userId,
        'filter[_and][1][_or][1][receiver][_eq]': userId,
        'fields': '*,requester.*,receiver.*',
        'sort': '-created_at',
      },
    );

    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Toggle favorite flag on an access request (optional improvement).
  Future<AccessRequest> updateFavorite(
    String requestId, {
    required bool isFavorite,
  }) async {
    final response = await _api.patch(
      Endpoints.accessRequestById(requestId),
      body: {'is_favorite': isFavorite},
    );
    return AccessRequest.fromJson(response['data'] as Map<String, dynamic>);
  }
}
