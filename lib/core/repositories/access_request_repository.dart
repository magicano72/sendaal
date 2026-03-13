import '../../models/access_request_model.dart';
import '../../services/access_service.dart';
import '../error/exceptions.dart';

class AccessRequestRepository {
  final AccessService accessService;

  AccessRequestRepository(this.accessService);

  /// Create a new access request from requester to receiver
  Future<AccessRequest> createAccessRequest({
    required String requesterId,
    required String receiverId,
    required int rejectionCount,
  }) async {
    try {
      // Backend-side guard: prevent duplicate pending requests
      final existingPending = await accessService.getPendingRequest(
        requesterId: requesterId,
        receiverId: receiverId,
      );

      if (existingPending != null) {
        throw ApiException(
          message:
              'You already have a pending request. Please wait for approval or cancel it first.',
        );
      }

      final response = await accessService.createRequest(
        requesterId: requesterId,
        receiverId: receiverId,
      );
      return response;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create access request: ${e.toString()}',
      );
    }
  }

  /// Get all access requests received by a user (where receiver = user)
  Future<List<AccessRequest>> getReceivedRequests(String userId) async {
    try {
      return await accessService.getReceivedRequests(userId);
    } catch (e) {
      throw ApiException(message: 'Failed to fetch requests: ${e.toString()}');
    }
  }

  /// Get all access requests sent by a user (where requester = user)
  Future<List<AccessRequest>> getSentRequests(String userId) async {
    try {
      return await accessService.getSentRequests(userId);
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch sent requests: ${e.toString()}',
      );
    }
  }

  /// Approve an access request
  Future<AccessRequest> approveRequest(String requestId) async {
    try {
      return await accessService.updateStatus(
        requestId: requestId,
        status: 'approved',
      );
    } catch (e) {
      throw ApiException(message: 'Failed to approve request: ${e.toString()}');
    }
  }

  /// Reject an access request
  Future<AccessRequest> rejectRequest(String requestId) async {
    try {
      return await accessService.updateStatus(
        requestId: requestId,
        status: 'rejected',
      );
    } catch (e) {
      throw ApiException(message: 'Failed to reject request: ${e.toString()}');
    }
  }
}
