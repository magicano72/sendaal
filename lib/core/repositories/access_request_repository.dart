import '../error/exceptions.dart';
import '../models/access_request_model.dart';
import '../services/access_service.dart';

class AccessRequestRepository {
  final AccessService accessService;

  AccessRequestRepository(this.accessService);

  Future<AccessRequest> createAccessRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    try {
      final response = await accessService.createAccessRequest(
        requesterId: requesterId,
        receiverId: receiverId,
      );
      return AccessRequest.fromJson(response);
    } catch (e) {
      throw ApiException(
        message: 'Failed to create access request: ${e.toString()}',
      );
    }
  }

  Future<List<AccessRequest>> getReceivedRequests(String userId) async {
    try {
      final responses = await accessService.getReceivedRequests(userId);
      return responses.map((data) => AccessRequest.fromJson(data)).toList();
    } catch (e) {
      throw ApiException(message: 'Failed to fetch requests: ${e.toString()}');
    }
  }
}
