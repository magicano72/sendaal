import 'package:Sendaal/core/config/index.dart';
import 'package:Sendaal/core/theme/app_theme.dart' hide AppTheme;
import 'package:Sendaal/services/device_contacts_service.dart'
    show ContactsPermissionStatus;
import 'package:Sendaal/widgets/app_snackbar.dart';
import 'package:Sendaal/widgets/shimmer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/text_style.dart';
import '../../models/access_request_model.dart';
import '../../providers/access_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contacts_provider.dart';
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
      ref.read(deviceContactsProvider.notifier).bootstrap();
      ref.read(contactsProvider.notifier).load();
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

  void _openDeviceContacts() {
    Navigator.pushNamed(context, AppRoutes.deviceContacts);
  }

  void _openApprovedContacts() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _ApprovedContactsScreen()));
  }

  void _openRecipient(User user) {
    final currentUser = ref.read(authProvider).user;
    if (currentUser != null && user.id == currentUser.id) {
      AppSnackBar.info(
        context,
        'This is you! Your profile is in the Profile tab.',
      );
      return;
    }
    Navigator.pushNamed(context, AppRoutes.recipient, arguments: user);
  }

  Future<void> _requestContactsPermission() async {
    final notifier = ref.read(deviceContactsProvider.notifier);
    final currentStatus = await notifier.refreshPermission();

    if (currentStatus == ContactsPermissionStatus.granted) {
      await notifier.loadContacts();
      return;
    }

    if (currentStatus == ContactsPermissionStatus.permanentlyDenied ||
        currentStatus == ContactsPermissionStatus.restricted) {
      final goSettings = await _showContactsSettingsDialog();
      if (goSettings) await openAppSettings();
      return;
    }

    final proceed = await _showContactsRationaleDialog();
    if (!proceed) return;

    final result = await notifier.requestPermission();
    if (result == ContactsPermissionStatus.granted) {
      await notifier.loadContacts();
      return;
    }

    if (result == ContactsPermissionStatus.permanentlyDenied ||
        result == ContactsPermissionStatus.restricted) {
      final goSettings = await _showContactsSettingsDialog();
      if (goSettings) await openAppSettings();
    }
  }

  Future<bool> _showContactsRationaleDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow contacts access'),
        content: const Text(
          'Sendaal needs access to your contacts to help you find people you know.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _showContactsSettingsDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable contacts in Settings'),
        content: const Text(
          'Contacts access is blocked. Open Settings to enable contacts for Sendaal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _refreshHome() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await Future.wait([
        ref.read(accessRequestProvider.notifier).loadReceivedRequests(user.id),
        ref.read(accessRequestProvider.notifier).loadSentRequests(user.id),
        ref.read(notificationsProvider.notifier).loadNotifications(user.id),
      ]);
      await ref.read(contactsProvider.notifier).load();
    }
    await ref.read(deviceContactsProvider.notifier).loadContacts();
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
                hint: 'Search username or phone',
                onContactsTap: _openDeviceContacts,
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
                  style: TextStyles.bodyBold.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  user != null
                      ? 'Welcome back, ${user.firstName.split(' ').first}'
                      : 'Welcome back',
                  style: TextStyles.label.copyWith(
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

  // Home content: access requests or empty state
  Widget _buildHomeContent() {
    final accessRequests = ref.watch(accessRequestProvider);
    final contactsState = ref.watch(contactsProvider);
    final deviceContactsState = ref.watch(deviceContactsProvider);
    final contactsSection = _buildContactsSection(
      contactsState,
      deviceContactsState,
    );

    if (accessRequests.isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 12.h),
          contactsSection,
          const AccessRequestShimmer(count: 2),
        ],
      );
    }

    final allRequests = [
      ...accessRequests.receivedRequests,
      ...accessRequests.sentRequests,
    ];

    final receivedSorted = [...accessRequests.receivedRequests]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final sentSorted = [...accessRequests.sentRequests]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (allRequests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 12.h),
          contactsSection,
          SizedBox(height: 24.h),
          _buildEmptyState(),
        ],
      );
    }

    final pendingReceivedCount = receivedSorted
        .where((r) => r.status.name == 'pending')
        .length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 12.h),
        contactsSection,
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
          child: Row(
            children: [
              Text(
                'Access Requests',
                style: TextStyles.h2Medium.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.allAccessRequests),
                child: Text(
                  'View all',
                  style: TextStyles.bodySmallBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (receivedSorted.isNotEmpty) ...[
          _buildSectionLabel(
            icon: Icons.inbox_outlined,
            label: 'Incoming Requests',
            pendingCount: pendingReceivedCount,
            pendingColor: const Color(0xFF2D7AE8),
          ),
          ...receivedSorted.map(
            (req) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              child: AccessRequestCard(request: req, isReceived: true),
            ),
          ),
          SizedBox(height: 8.h),
        ],
        if (sentSorted.isNotEmpty) ...[
          _buildSectionLabel(
            icon: Icons.send_outlined,
            label: 'My Requests',
            pendingCount: sentSorted
                .where((r) => r.status.name == 'pending')
                .length,
            pendingColor: Colors.orange,
          ),
          ...sentSorted.map(
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

  Widget _buildContactsSection(
    ContactsState contactsState,
    DeviceContactsState deviceState,
  ) {
    final hasContacts = contactsState.contacts.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
          child: Row(
            children: [
              Text(
                'Contacts',
                style: TextStyles.h2Medium.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _openApprovedContacts,
                child: Text(
                  'View all',
                  style: TextStyles.bodySmallBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: hasContacts ? 118.h : 140.h,
          child: hasContacts
              ? ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  scrollDirection: Axis.horizontal,
                  itemCount: contactsState.contacts.length,
                  separatorBuilder: (_, __) => SizedBox(width: 14.w),
                  itemBuilder: (_, i) {
                    final contact = contactsState.contacts[i];
                    return _ContactCircleTile(
                      user: contact.user,
                      isFavorite: contact.isFavorite,
                      showFullName: true,
                      onTap: () => _openRecipient(contact.user),
                      onFavoriteToggle: () => ref
                          .read(contactsProvider.notifier)
                          .toggleFavorite(
                            contact.request.id,
                            !contact.isFavorite,
                          ),
                    );
                  },
                )
              : _buildContactsPrompt(deviceState, contactsState.isLoading),
        ),
      ],
    );
  }

  Widget _buildContactsPrompt(DeviceContactsState deviceState, bool isLoading) {
    if (isLoading) {
      return ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, __) => Container(
          width: 150.w,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: const ShimmerCard(height: 130),
        ),
      );
    }

    final permissionState = deviceState.permission;
    final permissionMissing =
        permissionState != ContactsPermissionStatus.granted;
    final blocked =
        permissionState == ContactsPermissionStatus.permanentlyDenied ||
        permissionState == ContactsPermissionStatus.restricted;
    final title = permissionMissing
        ? 'Allow contacts to sync'
        : 'No contacts yet';
    final subtitle = blocked
        ? 'Enable contacts in Settings to find friends from your phone book.'
        : permissionMissing
        ? 'Grant access to find friends from your phone book.'
        : 'Approved contacts will appear here automatically.';
    final ctaLabel = blocked
        ? 'Open Settings'
        : permissionMissing
        ? 'Allow'
        : 'Import';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.contacts, color: AppColors.primary),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.bodySmallBold.copyWith(
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyles.captionRegular.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            TextButton(
              onPressed: permissionMissing
                  ? _requestContactsPermission
                  : _openDeviceContacts,
              child: Text(ctaLabel),
            ),
          ],
        ),
      ),
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
              style: TextStyles.labelBold.copyWith(color: Colors.black87),
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
                style: TextStyles.captionMedium.copyWith(
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
              style: TextStyles.h2Medium.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'No pending access requests. New requests will appear here when others share their accounts with you.',
              textAlign: TextAlign.center,
              style: TextStyles.bodySmall.copyWith(
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

class _ContactCircleTile extends StatelessWidget {
  final User user;
  final bool isFavorite;
  final bool showFullName;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _ContactCircleTile({
    required this.user,
    required this.isFavorite,
    required this.showFullName,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;
    final name = showFullName && (user.firstName?.isNotEmpty ?? false)
        ? user.firstName!
        : (user.displayName.isNotEmpty ? user.displayName : user.username);
    final initials = user.initials;
    final double outer = 68.r;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(outer / 2),
              child: Container(
                width: outer,
                height: outer,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceColor,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.25),
                    width: 3.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Text(
                            initials,
                            style: TextStyles.bodyBold.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                              fontSize: 18.sp,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              top: -4,
              child: GestureDetector(
                onTap: onFavoriteToggle,
                child: Container(
                  width: 22.r,
                  height: 22.r,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    size: 14.r,
                    color: isFavorite
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: outer + 6.w,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.labelBold.copyWith(
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ApprovedContactsScreen extends ConsumerStatefulWidget {
  const _ApprovedContactsScreen({super.key});

  @override
  ConsumerState<_ApprovedContactsScreen> createState() =>
      _ApprovedContactsScreenState();
}

class _ApprovedContactsScreenState
    extends ConsumerState<_ApprovedContactsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = contactsState.contacts.where((c) {
      if (query.isEmpty) return true;
      final user = c.user;
      final phone = user.phoneNumber ?? '';
      return user.displayName.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query) ||
          phone.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts'), centerTitle: true),
      body: contactsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by username or phone number',
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.textSecondaryColor,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFEFF2F6),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 14.w,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 8.h),
                  child: Text(
                    'APPROVED CONTACTS',
                    style: TextStyles.captionBold.copyWith(
                      letterSpacing: 0.4,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Center(
                            child: EmptyState(
                              icon: Icons.people_outline,
                              title: 'No approved contacts',
                              subtitle:
                                  'Approved contacts will appear here after access is granted.',
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 0.6,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (_, i) {
                            final contact = filtered[i];
                            final user = contact.user;
                            final phone = user.phoneNumber ?? '';
                            final fullName =
                                (user.firstName?.isNotEmpty ?? false)
                                ? user.firstName!
                                : (user.displayName.isNotEmpty
                                      ? user.displayName
                                      : user.username);
                            final subtitleParts = <String>[
                              '@${user.username}',
                              if (phone.isNotEmpty) phone,
                            ];
                            final subtitle = subtitleParts.join(' • ');

                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 6.h,
                              ),
                              leading: CircleAvatar(
                                radius: 24.r,
                                backgroundColor: AppTheme.primaryColor
                                    .withOpacity(0.12),
                                backgroundImage:
                                    user.avatarUrl != null &&
                                        user.avatarUrl!.isNotEmpty
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child:
                                    (user.avatarUrl == null ||
                                        user.avatarUrl!.isEmpty)
                                    ? Text(
                                        user.initials,
                                        style: TextStyles.bodyBold.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                fullName,
                                style: TextStyles.bodyBold.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16.sp,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Text(
                                  subtitle,
                                  style: TextStyles.label.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.recipient,
                                arguments: user,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _UserResultCard extends ConsumerStatefulWidget {
  final User user;
  final VoidCallback onTap;

  const _UserResultCard({required this.user, required this.onTap});

  @override
  ConsumerState<_UserResultCard> createState() => _UserResultCardState();
}

class _UserResultCardState extends ConsumerState<_UserResultCard> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final displayName = user.displayName.isNotEmpty
        ? user.displayName
        : user.username;
    final avatarUrl = user.avatarUrl;
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';
    final currentUser = ref.watch(authProvider).user;

    if (currentUser == null) {
      return _buildCard(
        context,
        displayName: displayName,
        avatarUrl: avatarUrl,
        initials: initials,
        subtitle: '@${user.username}',
        canTap: true,
      );
    }

    final latestAsync = ref.watch(
      latestRequestBetweenProvider((currentUser.id, user.id)),
    );

    return latestAsync.when(
      loading: () => _buildCard(
        context,
        displayName: displayName,
        avatarUrl: avatarUrl,
        initials: initials,
        subtitle: '@${user.username}',
        canTap: false,
        showSpinner: true,
      ),
      error: (_, __) => _buildCard(
        context,
        displayName: displayName,
        avatarUrl: avatarUrl,
        initials: initials,
        subtitle: '@${user.username}',
        canTap: true,
      ),
      data: (latest) {
        final isRevoked = latest?.isRevoked == true;
        final isRevoker = isRevoked && latest?.revokerId == currentUser.id;
        final subtitle = isRevoked ? 'Access Denied' : '@${user.username}';

        return _buildCard(
          context,
          displayName: displayName,
          avatarUrl: avatarUrl,
          initials: initials,
          subtitle: subtitle,
          canTap: !isRevoked || isRevoker,
          isRevoked: isRevoked,
          isRevoker: isRevoker,
          requestId: latest?.id,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String displayName,
    required String? avatarUrl,
    required String initials,
    required String subtitle,
    required bool canTap,
    bool showSpinner = false,
    bool isRevoked = false,
    bool isRevoker = false,
    String? requestId,
  }) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: canTap ? widget.onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                            style: TextStyles.bodyBold.copyWith(
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
                          style: TextStyles.bodySmallBold.copyWith(
                            fontSize: 15.sp,
                            color: AppTheme.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          subtitle,
                          style: TextStyles.label.copyWith(
                            color: isRevoked
                                ? Colors.redAccent
                                : AppTheme.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (showSpinner)
                    SizedBox(
                      height: 18.r,
                      width: 18.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.primaryColor,
                      size: 20.r,
                    ),
                ],
              ),
              if (isRevoked) ...[
                SizedBox(height: 10.h),
                if (isRevoker && requestId != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isCancelling
                          ? null
                          : () => _cancelRevoke(requestId),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        side: BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isCancelling
                          ? SizedBox(
                              height: 16.r,
                              width: 16.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Cancel Revoke',
                              style: TextStyles.bodySmallBold.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                    ),
                  )
                else
                  Text(
                    'Access Denied',
                    style: TextStyles.labelBold.copyWith(
                      color: Colors.red.shade600,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelRevoke(String requestId) async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);

    final updated = await ref
        .read(accessRequestProvider.notifier)
        .cancelRevoke(requestId);

    if (!mounted) return;

    setState(() => _isCancelling = false);

    if (updated != null) {
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        ref.invalidate(
          latestRequestBetweenProvider((currentUser.id, widget.user.id)),
        );
        await Future.wait([
          ref
              .read(accessRequestProvider.notifier)
              .loadSentRequests(currentUser.id),
          ref
              .read(accessRequestProvider.notifier)
              .loadReceivedRequests(currentUser.id),
        ]);
      }
      AppSnackBar.success(context, 'Access restored');
    } else {
      final err =
          ref.read(accessRequestProvider).error ?? 'Failed to cancel revoke';
      AppSnackBar.error(context, err);
    }
  }
}
