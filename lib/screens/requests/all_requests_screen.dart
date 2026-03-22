import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/access_request_model.dart';
import '../../providers/access_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/access_request_card.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/shimmer_widgets.dart';

/// Screen that lists all access requests (received + sent).
class AllRequestsScreen extends ConsumerStatefulWidget {
  const AllRequestsScreen({super.key});

  @override
  ConsumerState<AllRequestsScreen> createState() => _AllRequestsScreenState();
}

class _AllRequestsScreenState extends ConsumerState<AllRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
  }

  Future<void> _loadRequests() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    await Future.wait([
      ref.read(accessRequestProvider.notifier).loadReceivedRequests(user.id),
      ref.read(accessRequestProvider.notifier).loadSentRequests(user.id),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(accessRequestProvider);
    final combined = [
      ...accessState.receivedRequests.map((r) => (r, true)),
      ...accessState.sentRequests.map((r) => (r, false)),
    ];
    combined.sort((a, b) => b.$1.createdAt.compareTo(a.$1.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Requests'),
        elevation: 0.3,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        color: const Color(0xFF2D7AE8),
        child: _buildBody(accessState, combined),
      ),
    );
  }

  Widget _buildBody(
    AccessRequestsState state,
    List<(AccessRequest, bool)> combined,
  ) {
    if (state.isLoading) {
      return const AccessRequestShimmer(count: 3);
    }

    if (combined.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 80.h),
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No requests yet',
            subtitle: 'Access requests you receive or send will appear here.',
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 12.h),
      itemCount: combined.length,
      itemBuilder: (_, i) {
        final (request, isReceived) = combined[i];
        return AccessRequestCard(
          request: request,
          isReceived: isReceived,
        );
      },
    );
  }
}
