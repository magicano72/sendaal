import 'package:Sendaal/services/device_contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../../providers/access_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contacts_provider.dart';

class DeviceContactsScreen extends ConsumerStatefulWidget {
  const DeviceContactsScreen({super.key});

  @override
  ConsumerState<DeviceContactsScreen> createState() =>
      _DeviceContactsScreenState();
}

class _DeviceContactsScreenState extends ConsumerState<DeviceContactsScreen> {
  final Map<String, bool> _requesting = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceContactsProvider.notifier).loadContacts();
    });
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DeviceContactView> _filterContacts(List<DeviceContactView> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    return contacts.where((c) {
      final name = c.contact.name.toLowerCase();
      final phone = (c.contact.phone ?? '').toLowerCase();
      final username = c.matchedUser?.username.toLowerCase() ?? '';
      return name.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          username.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceContactsProvider);
    final approvedIds = ref
        .watch(contactsProvider)
        .contacts
        .map((c) => c.user.id)
        .toSet();

    final permissionDenied =
        deviceState.permission == ContactsPermissionStatus.denied;

    final filteredContacts = _filterContacts(deviceState.contacts);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Device Contacts',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18.sp),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(deviceContactsProvider.notifier).loadContacts(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Search bar
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              sliver: SliverToBoxAdapter(child: _buildSearchBar()),
            ),

            if (permissionDenied)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                sliver: SliverToBoxAdapter(child: _buildPermissionCard()),
              ),

            if (deviceState.isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              )
            else if (deviceState.contacts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  child: _buildEmptyCard(permissionDenied),
                ),
              )
            else ...[
              // Section header
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 4.h),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),

              if (filteredContacts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                    child: Center(
                      child: Text(
                        'No contacts match "$_searchQuery"',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final contact = filteredContacts[index];
                      return _buildContactTile(
                        contact,
                        approvedIds,
                        permissionDenied,
                      );
                    }, childCount: filteredContacts.length),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: 'Search by username or phone',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20.sp),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, size: 18.sp, color: Colors.grey[400]),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 14.h),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allow contacts access',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              'We use your phone contacts to find friends already on Sendaal.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13.sp),
            ),
            SizedBox(height: 10.h),
            FilledButton(
              onPressed: () =>
                  ref.read(deviceContactsProvider.notifier).requestPermission(),
              child: const Text('Allow Contacts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(bool permissionDenied) {
    return Card(
      margin: EdgeInsets.only(bottom: 14.h),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              permissionDenied ? 'No permission' : 'No contacts found',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              permissionDenied
                  ? 'Grant permission to list your device contacts.'
                  : 'We could not find contacts with phone numbers.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(
    DeviceContactView contact,
    Set<String> approvedIds,
    bool permissionDenied,
  ) {
    final matchedUser = contact.matchedUser;
    final alreadyApproved =
        matchedUser != null && approvedIds.contains(matchedUser.id);
    final isSending =
        matchedUser != null && (_requesting[matchedUser.id] ?? false);

    final String name;
    final String? phone;
    final String? avatarUrl;
    final String actionLabel;
    final VoidCallback onAction;
    final VoidCallback onTap;

    if (!contact.hasAccount) {
      name = contact.contact.name;
      phone = contact.contact.phone;
      avatarUrl = null;
      actionLabel = 'Invite';
      onAction = () => _invite(contact.contact);
      onTap = () => _invite(contact.contact);
    } else {
      final user = matchedUser!;
      name = user.displayName ?? user.username;
      phone = user.phone?.isNotEmpty == true ? user.phone : '@${user.username}';
      avatarUrl = user.avatar;
      actionLabel = alreadyApproved ? 'View' : 'Request';
      onAction = alreadyApproved
          ? () => _openContactDetails(user)
          : () => _requestAccess(user);
      onTap = alreadyApproved
          ? () => _openContactDetails(user)
          : () => _requestAccess(user);
    }

    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    Widget tile = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24.r,
              backgroundColor: Colors.blue[50],
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            // Name + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (phone != null && phone.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 10.w),
            // Action button
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[600],
                side: BorderSide(color: Colors.blue[300]!, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    ).wrapWithLoader(isSending);

    return Column(
      children: [
        tile,
        Divider(height: 1.h, thickness: 0.5, color: Colors.grey[200]),
      ],
    );
  }

  Future<void> _requestAccess(User user) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    setState(() => _requesting[user.id] = true);
    final (success, error) = await ref
        .read(accessRequestProvider.notifier)
        .createAccessRequest(requesterId: currentUser.id, receiverId: user.id);

    if (!mounted) return;
    setState(() => _requesting[user.id] = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Access request sent to ${user.displayName}'
              : error ?? 'Unable to send request',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await ref.read(contactsProvider.notifier).load();
    }
  }

  void _invite(DeviceContact contact) {
    final message =
        'Join me on Sendaal to share accounts easily. My number is ${contact.phone}.';
    Share.share(message, subject: 'Invite to Sendaal');
  }

  void _openContactDetails(User user) {
    Navigator.pushNamed(context, AppRoutes.contactDetails, arguments: user);
  }
}

extension on Widget {
  Widget wrapWithLoader(bool isLoading) {
    if (!isLoading) return this;
    return Stack(
      children: [
        Opacity(opacity: 0.5, child: this),
        Positioned.fill(
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
