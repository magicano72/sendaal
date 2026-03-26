import '../../models/access_request_account_model.dart';
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
    required String requestAccessType,
    List<String> selectedAccountIds = const [],
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
        requestAccessType: requestAccessType,
      );

      // If custom access, attach selected accounts for requester side
      if (requestAccessType == 'custom' && selectedAccountIds.isNotEmpty) {
        await accessService.addRequestAccounts(
          accessRequestId: response.id,
          accountIds: selectedAccountIds,
          side: 'requester',
        );
      }

      return response;
    } catch (e) {
      throw ApiException(
        message: 'Failed to create access request: ${e.toString()}',
      );
    }
  }

  /// Get all access requests received by a user (where receiver = user)
  Future<List<AccessRequest>> getReceivedRequests(
    String userId, {
    bool includeHidden = false,
  }) async {
    try {
      return await accessService.getReceivedRequests(
        userId,
        includeHidden: includeHidden,
      );
    } catch (e) {
      throw ApiException(message: 'Failed to fetch requests: ${e.toString()}');
    }
  }

  /// Get all access requests sent by a user (where requester = user)
  Future<List<AccessRequest>> getSentRequests(
    String userId, {
    bool includeHidden = false,
  }) async {
    try {
      return await accessService.getSentRequests(
        userId,
        includeHidden: includeHidden,
      );
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch sent requests: ${e.toString()}',
      );
    }
  }

  /// Approve an access request
  Future<AccessRequest> approveRequest(
    String requestId, {
    required String approvedAccessType,
    List<String> selectedAccountIds = const [],
  }) async {
    try {
      final updated = await accessService.patchRequest(
        requestId: requestId,
        status: 'approved',
        approvedAccessType: approvedAccessType,
      );

      if (approvedAccessType == 'custom' && selectedAccountIds.isNotEmpty) {
        await accessService.addRequestAccounts(
          accessRequestId: requestId,
          accountIds: selectedAccountIds,
          side: 'receiver',
        );
      }
      return updated;
    } catch (e) {
      throw ApiException(message: 'Failed to approve request: ${e.toString()}');
    }
  }

  /// Reject an access request
  Future<AccessRequest> rejectRequest(String requestId) async {
    try {
      return await accessService.patchRequest(
        requestId: requestId,
        status: 'rejected',
      );
    } catch (e) {
      throw ApiException(message: 'Failed to reject request: ${e.toString()}');
    }
  }

  /// Hide a request for the requester (UI only)
  Future<AccessRequest> hideForRequester(String requestId) async {
    try {
      return await accessService.hideForRequester(requestId);
    } catch (e) {
      throw ApiException(message: 'Failed to hide request: ${e.toString()}');
    }
  }

  /// Hide a request for the receiver (UI only)
  Future<AccessRequest> hideForReceiver(String requestId) async {
    try {
      return await accessService.hideForReceiver(requestId);
    } catch (e) {
      throw ApiException(message: 'Failed to hide request: ${e.toString()}');
    }
  }

  Future<List<AccessRequestAccount>> getRequestAccounts({
    required String requestId,
    String? side,
  }) {
    return accessService.getRequestAccounts(
      accessRequestId: requestId,
      side: side,
    );
  }

  Future<AccessRequest> patchRequest({
    required String requestId,
    String? status,
    String? requestAccessType,
    String? approvedAccessType,
  }) {
    return accessService.patchRequest(
      requestId: requestId,
      status: status,
      requestAccessType: requestAccessType,
      approvedAccessType: approvedAccessType,
    );
  }

  Future<void> deleteAccountsForSide({
    required String requestId,
    required String side,
  }) {
    return accessService.deleteAccountsForSide(
      accessRequestId: requestId,
      side: side,
    );
  }

  Future<void> deleteRequestAccount(String accountLinkId) {
    return accessService.deleteRequestAccountById(accountLinkId);
  }

  /// Update access type for a side and sync selected accounts.
  Future<AccessRequest> updateAccessTypeAndAccounts({
    required String requestId,
    required bool isRequesterSide,
    required String accessType, // full | custom
    List<String> selectedAccountIds = const [],
  }) async {
    try {
      final side = isRequesterSide ? 'requester' : 'receiver';
      final updated = await accessService.patchRequest(
        requestId: requestId,
        requestAccessType: isRequesterSide ? accessType : null,
        approvedAccessType: isRequesterSide ? null : accessType,
      );

      if (accessType == 'full') {
        await accessService.deleteAccountsForSide(
          accessRequestId: requestId,
          side: side,
        );
        return updated;
      }

      final current = await accessService.getRequestAccounts(
        accessRequestId: requestId,
        side: side,
      );
      final currentIds = current
          .map((a) => a.financialAccount.id)
          .where((id) => id.isNotEmpty)
          .toSet();
      final desired = selectedAccountIds.toSet();

      final toRemove = current
          .where((a) => !desired.contains(a.financialAccount.id))
          .map((a) => a.id)
          .toList();
      final toAdd = desired.difference(currentIds).toList();

      for (final linkId in toRemove) {
        await accessService.deleteRequestAccountById(linkId);
      }
      if (toAdd.isNotEmpty) {
        await accessService.addRequestAccounts(
          accessRequestId: requestId,
          accountIds: toAdd,
          side: side,
        );
      }
      return updated;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update access type: ${e.toString()}',
      );
    }
  }

  Future<AccessRequest> revokeAccess({
    required String requestId,
    required bool isRequesterSide,
    required String currentUserId,
  }) async {
    try {
      // Unified revoked status; revoker tracked via revoked_by.
      final updated = await accessService.patchRequest(
        requestId: requestId,
        status: AccessStatus.revoked.apiValue,
        revokedByUserId: currentUserId,
      );
      return updated;
    } catch (e) {
      throw ApiException(
        message: 'Failed to revoke access: ${e.toString()}',
      );
    }
  }

  Future<AccessRequest> cancelRevoke({
    required String requestId,
  }) async {
    try {
      // Restores access; backend keeps account links intact.
      return await accessService.patchRequest(
        requestId: requestId,
        status: AccessStatus.approved.apiValue,
        clearRevokedBy: true,
      );
    } catch (e) {
      throw ApiException(
        message: 'Failed to cancel revoke: ${e.toString()}',
      );
    }
  }
}
