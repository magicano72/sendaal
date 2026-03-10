import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../providers/search_provider.dart';
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
    Navigator.pushNamed(context, AppRoutes.recipient, arguments: user);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Send Money')),
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

    // Empty query — show prompt
    if (state.query.isEmpty) {
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'Find someone to pay',
        subtitle:
            'Search by their Sendaal username\nor phone number to get started.',
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
          profileImage: user.profileImage,
          onTap: () => _openRecipient(user),
        );
      },
    );
  }
}
