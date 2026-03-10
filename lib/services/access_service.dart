import '../core/models/access_request_model.dart';
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

  /// Get all requests received by a user
  Future<List<AccessRequest>> getReceivedRequests(String userId) async {
    final response = await _api.get(
      Endpoints.accessRequests,
      queryParams: {'filter[receiver][_eq]': userId},
    );
    final list = response['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AccessRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
