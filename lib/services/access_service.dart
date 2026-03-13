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
}
