import 'api_client.dart';

class AccessService {
  final ApiClient apiClient;

  AccessService(this.apiClient);

  /// Create new access request
  Future<Map<String, dynamic>> createAccessRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    return await apiClient.post(
      '/items/access_requests',
      body: {
        'requester': requesterId,
        'receiver': receiverId,
        'status': 'pending',
      },
    );
  }

  /// Get access requests received by user
  Future<List<Map<String, dynamic>>> getReceivedRequests(String userId) async {
    try {
      final result = await apiClient.get(
        '/items/access_requests',
        queryParams: {'filter[receiver][_eq]': userId},
      );

      if (result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get access requests created by user
  Future<List<Map<String, dynamic>>> getSentRequests(String userId) async {
    try {
      final result = await apiClient.get(
        '/items/access_requests',
        queryParams: {'filter[requester][_eq]': userId},
      );

      if (result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Approve access request
  Future<Map<String, dynamic>> approveRequest(String requestId) async {
    return await apiClient.patch(
      '/items/access_requests/$requestId',
      body: {'status': 'approved'},
    );
  }

  /// Reject access request
  Future<Map<String, dynamic>> rejectRequest(String requestId) async {
    return await apiClient.patch(
      '/items/access_requests/$requestId',
      body: {'status': 'rejected'},
    );
  }
}
