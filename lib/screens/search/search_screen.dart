import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sendaal/widgets/shimmer_widgets.dart';

import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../providers/access_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/access_request_card.dart';
import '../../widgets/app_widgets.dart';

/// Search & Pay Screen — find users by username or phone, then pay them
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();

  // Debounce timer to avoid firing on every keystroke
  DateTime _lastSearch = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(accessRequestProvider.notifier).loadReceivedRequests(user.id);
        ref.read(accessRequestProvider.notifier).loadSentRequests(user.id);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _lastSearch = DateTime.now();
    final captured = _lastSearch;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (captured == _lastSearch && mounted) {
        ref.read(searchProvider.notifier).search(query);
      }
    });
  }

  void _openRecipient(User user) {
    final currentUser = ref.read(authProvider).user;

    // Prevent self-access request - navigate to profile instead
    if (currentUser != null && user.id == currentUser.id) {
      Navigator.pushNamed(context, AppRoutes.profile);
      return;
    }

    Navigator.pushNamed(context, AppRoutes.recipient, arguments: user);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Send Money'), leading: SizedBox()),
      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SearchField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              onClear: () => ref.read(searchProvider.notifier).clear(),
              hint: 'Search by @username or phone number...',
            ),
          ),

          // ── Results / States ───────────────────────────────────────────────
          Expanded(child: _buildBody(searchState)),
        ],
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    // Loading
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: ErrorBanner(
          message: state.error!,
          onRetry: () => ref.read(searchProvider.notifier).search(state.query),
        ),
      );
    }

    // Empty query — show access requests and prompt
    if (state.query.isEmpty) {
      final accessRequests = ref.watch(accessRequestProvider);
      final hasPendingReceived = accessRequests.receivedRequests.any(
        (r) => r.status.name == 'pending',
      );
      final hasPendingSent = accessRequests.sentRequests.any(
        (r) => r.status.name == 'pending',
      );

      // Show shimmer while loading access requests
      if (accessRequests.isLoading) {
        return const AccessRequestShimmer(count: 2);
      }

      return SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              // RECEIVED Requests Section
              if (accessRequests.receivedRequests.isNotEmpty)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            color: hasPendingReceived
                                ? Colors.blue
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Incoming Requests',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (hasPendingReceived)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${accessRequests.receivedRequests.where((r) => r.status.name == 'pending').length} Pending',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...accessRequests.receivedRequests.map(
                      (req) =>
                          AccessRequestCard(request: req, isReceived: true),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // SENT Requests Section
              if (accessRequests.sentRequests.isNotEmpty)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.send_outlined,
                            color: hasPendingSent ? Colors.orange : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'My Requests',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (hasPendingSent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${accessRequests.sentRequests.where((r) => r.status.name == 'pending').length} Pending',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...accessRequests.sentRequests.map(
                      (req) =>
                          AccessRequestCard(request: req, isReceived: false),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Empty state with prompt
              if (accessRequests.receivedRequests.isEmpty &&
                  accessRequests.sentRequests.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: EmptyState(
                    icon: Icons.person_search_outlined,
                    title: 'Find someone to pay',
                    subtitle:
                        'Search by their Sendaal username\nor phone number to get started.',
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: EmptyState(
                    icon: Icons.person_search_outlined,
                    title: 'Find someone to pay',
                    subtitle:
                        'Search by their Sendaal username\nor phone number to get started.',
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // No results
    if (state.results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_outlined,
        title: 'No users found',
        subtitle: 'Try searching for "${state.query}" differently.',
      );
    }

    // Results list
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: state.results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final user = state.results[i];
        return UserTile(
          displayName: user.displayName,
          username: user.username,
          profileImage: user.avatarUrl,
          onTap: () => _openRecipient(user),
        );
      },
    );
  }
}
