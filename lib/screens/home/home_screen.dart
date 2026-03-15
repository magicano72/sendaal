import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sendaal/core/config/index.dart';
import 'package:sendaal/widgets/shimmer_widgets.dart';

import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../models/access_request_model.dart';
import '../../providers/access_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/access_request_card.dart';
import '../../widgets/app_widgets.dart';

/// Home Screen — shows access requests or empty state, with search
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  DateTime _lastSearch = DateTime.now();
  bool _selectionMode = false;
  final Map<String, bool> _selectedMap = {}; // id -> isReceived

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
    if (currentUser != null && user.id == currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open your profile from the Profile tab.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, AppRoutes.recipient, arguments: user);
  }

  Future<void> _refreshHome() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await Future.wait([
        ref.read(accessRequestProvider.notifier).loadReceivedRequests(user.id),
        ref.read(accessRequestProvider.notifier).loadSentRequests(user.id),
        ref.read(notificationsProvider.notifier).loadNotifications(user.id),
      ]);
    }
    final query = ref.read(searchProvider).query;
    if (query.isNotEmpty) {
      await ref.read(searchProvider.notifier).search(query);
    } else {
      ref.read(searchProvider.notifier).clear();
    }
  }

  void _toggleSelection(AccessRequest request, bool isReceived) {
    setState(() {
      _selectionMode = true;
      if (_selectedMap.containsKey(request.id)) {
        _selectedMap.remove(request.id);
        if (_selectedMap.isEmpty) _selectionMode = false;
      } else {
        _selectedMap[request.id] = isReceived;
      }
    });
  }

  void _selectAll(List<(AccessRequest, bool)> all) {
    setState(() {
      _selectionMode = true;
      _selectedMap
        ..clear()
        ..addEntries(all.map((tuple) => MapEntry(tuple.$1.id, tuple.$2)));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedMap.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedMap.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete ${_selectedMap.length} selected request(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final notifier = ref.read(accessRequestProvider.notifier);
    await Future.wait(
      _selectedMap.entries.map(
        (e) => notifier.hideRequest(requestId: e.key, isReceived: e.value),
      ),
    );

    await _refreshHome();
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final hasNotifications = ref.watch(notificationsProvider).hasUnread;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom Header ──────────────────────────────────────────────
            _buildHeader(user, hasNotifications),

            // ── Search Bar ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
              child: SearchField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchCtrl.clear();
                  ref.read(searchProvider.notifier).clear();
                },
                hint: 'Search username or phone number',
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshHome,
                color: const Color(0xFF2D7AE8),
                child: _buildBody(searchState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(user, bool hasNotifications) {
    return Container(
      color: AppTheme.surfaceColor,
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22.r,
            backgroundColor: const Color(0xFFE8D5C4),
            backgroundImage: user?.avatarUrl != null
                ? NetworkImage(user!.avatarUrl!)
                : null,
            child: user?.avatarUrl == null
                ? Icon(Icons.person, size: 22.r, color: Colors.white)
                : null,
          ),
          SizedBox(width: 10.w),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sendaal',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  user != null
                      ? 'Welcome back, ${user.firstName.split(' ').first}'
                      : 'Welcome back',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Bell icon
          Stack(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.18),
                    width: 0.6,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.notifications_outlined,
                    size: 20.r,
                    color: Colors.black87,
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.notifications),
                ),
              ),
              if (hasNotifications)
                Positioned(
                  top: 6.r,
                  right: 6.r,
                  child: Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body dispatcher ─────────────────────────────────────────────────────
  Widget _buildBody(SearchState state) {
    // Loading spinner
    if (state.isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 140.h),
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF2D7AE8)),
          ),
        ],
      );
    }

    // Error banner
    if (state.error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: ErrorBanner(
              message: state.error!,
              onRetry: () =>
                  ref.read(searchProvider.notifier).search(state.query),
            ),
          ),
        ],
      );
    }

    // Empty query → show access requests OR empty state
    if (state.query.isEmpty) {
      return _buildHomeContent();
    }

    final filteredResults = _filterCurrentUser(state.results);

    // No search results
    if (filteredResults.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 48.h),
          EmptyState(
            icon: Icons.search_off_outlined,
            title: 'No users found',
            subtitle:
                'Try searching for "${state.query}" differently. Your profile lives in the Profile tab.',
          ),
        ],
      );
    }

    // Search results list
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 14.h),
      itemCount: filteredResults.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, i) {
        final user = filteredResults[i];
        return _UserResultCard(user: user, onTap: () => _openRecipient(user));
      },
    );
  }

  List<User> _filterCurrentUser(List<User> users) {
    final currentUserId = ref.read(authProvider).user?.id;
    if (currentUserId == null) return users;
    return users.where((u) => u.id != currentUserId).toList();
  }

  // ── Home content: access requests or empty state ─────────────────────
  Widget _buildHomeContent() {
    final accessRequests = ref.watch(accessRequestProvider);

    // Shimmer while loading
    if (accessRequests.isLoading) {
      return const AccessRequestShimmer(count: 2);
    }

    final allRequests = [
      ...accessRequests.receivedRequests,
      ...accessRequests.sentRequests,
    ];

    // ── Empty state ──────────────────────────────────────────────────────
    if (allRequests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 48.h),
          _buildEmptyState(),
        ],
      );
    }

    // ── Access requests list ─────────────────────────────────────────────
    final pendingReceivedCount = accessRequests.receivedRequests
        .where((r) => r.status.name == 'pending')
        .length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
          child: Row(
            children: [
              Text(
                'Access Requests',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.allAccessRequests),
                child: Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2D7AE8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Received requests
        if (accessRequests.receivedRequests.isNotEmpty) ...[
          _buildSectionLabel(
            icon: Icons.inbox_outlined,
            label: 'Incoming Requests',
            pendingCount: pendingReceivedCount,
            pendingColor: const Color(0xFF2D7AE8),
          ),
          ...accessRequests.receivedRequests.map(
            (req) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              child: AccessRequestCard(request: req, isReceived: true),
            ),
          ),
          SizedBox(height: 8.h),
        ],

        // Sent requests
        if (accessRequests.sentRequests.isNotEmpty) ...[
          _buildSectionLabel(
            icon: Icons.send_outlined,
            label: 'My Requests',
            pendingCount: accessRequests.sentRequests
                .where((r) => r.status.name == 'pending')
                .length,
            pendingColor: Colors.orange,
          ),
          ...accessRequests.sentRequests.map(
            (req) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              child: AccessRequestCard(request: req, isReceived: false),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ],
    );
  }

  // ── Sub-section label row ────────────────────────────────────────────
  Widget _buildSectionLabel({
    required IconData icon,
    required String label,
    required int pendingCount,
    required Color pendingColor,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 6.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.r,
            color: pendingCount > 0 ? pendingColor : Colors.grey,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          if (pendingCount > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: pendingColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '$pendingCount Pending',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: pendingColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Empty state widget ───────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Outer soft circle
            Container(
              width: 90.r,
              height: 90.r,
              decoration: const BoxDecoration(
                color: Color(0xFFDCE8F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                // Inner blue circle with checkmark
                child: Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D7AE8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 26.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'No pending access requests. New requests will appear here when others share their accounts with you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserResultCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _UserResultCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.isNotEmpty
        ? user.displayName
        : user.username;
    final avatarUrl = user.avatarUrl;
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(
                        initials,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.primaryColor,
                size: 20.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
