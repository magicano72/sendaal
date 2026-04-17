# Privacy Policy & Terms Implementation - Quick Reference

## 🚀 Quick Start

### For Users

#### In Settings
1. Navigate to Settings from Profile screen
2. Scroll to "Privacy & Legal" section
3. Tap on "Privacy Policy" or "Terms & Conditions"
4. View full policy with HTML formatting

#### During Registration
1. Fill registration form
2. See checkbox: "I agree to the Terms of Service and Privacy Policy"
3. Click blue links to view full policies
4. Check box to enable Register button

### For Developers

#### Add New Policy Type

1. **In Directus**, create a new policy with `type='custom'`
2. **In Code**, create a getter method:

```dart
Future<PolicyModel?> getCustomPolicy() => getPolicyByType('custom');
```

#### Navigate to Policy Programmatically

```dart
// From any screen
Navigator.pushNamed(
  context,
  AppRoutes.policyDetails,
  arguments: 'privacy', // or 'terms', 'about', etc.
);
```

#### Fetch Policy Data

```dart
final service = PolicyService();
final policy = await service.getPrivacyPolicy();
if (policy != null) {
  print(policy.title);      // "Privacy Policy"
  print(policy.content);    // "<html>...</html>"
  print(policy.status);     // "published"
}
```

#### Clear Cache

```dart
final service = PolicyService();
service.clearCache();  // Clear all
service.clearCacheForType('privacy');  // Clear specific type
```

## 📁 File Locations

| Purpose | File |
|---------|------|
| Data Model | `lib/models/policy_model.dart` |
| API Service | `lib/services/policy_service.dart` |
| Policy Viewer | `lib/screens/profile/policy_details_screen.dart` |
| Settings | `lib/screens/profile/settings_screen.dart` |
| Registration | `lib/screens/auth/register_screen.dart` |
| Routing | `lib/core/router/app_router.dart` |

## 🔗 Routes

```dart
AppRoutes.policyDetails  // '/policy-details'

// Usage
Navigator.pushNamed(
  context,
  AppRoutes.policyDetails,
  arguments: 'privacy',  // Policy type
);
```

## 🎯 Policy Types

| Type | Description | Use Case |
|------|-------------|----------|
| `privacy` | Privacy Policy | Directus type: privacy |
| `terms` | Terms of Service | Directus type: terms |
| `about` | About Company | Directus type: about |
| Custom | Any custom policy | Custom type in Directus |

## 🔄 API Flow

```
PolicyDetailsScreen
    ↓
PolicyService.getPolicyByType(type)
    ↓
Check Cache (24-hour)
    ↓
If Not Cached: ApiClient.getPublic('/items/policies?filter...')
    ↓
Parse PolicyModel
    ↓
Cache & Return
    ↓
PolicyDetailsScreen renders HTML
```

## ⚙️ Configuration

### Cache Duration
- **File**: `lib/services/policy_service.dart`
- **Default**: 24 hours
- **To Change**: Modify `_cacheDuration = Duration(hours: 24)`

### API Timeout
- **File**: `lib/services/policy_service.dart`
- **Default**: 15 seconds
- **To Change**: Modify `.timeout(const Duration(seconds: 15))`

### HTML Styling
- **File**: `lib/screens/profile/policy_details_screen.dart`
- **Customizable**: `Html` widget `style` property
- **Defaults**: Uses AppTheme colors and TextStyles

## 🛠️ Troubleshooting

### Policy Not Showing

**Check:**
1. Is policy published in Directus? (`status='published'`)
2. Is type correct? (`type='privacy'`, `type='terms'`, etc.)
3. Does Directus have public read access?

**Fix:**
```dart
// Debug: Check what's in Directus
final service = PolicyService();
final all = await service.getPoliciesByType('privacy');
print(all);  // See all privacy policies
```

### HTML Not Rendering

**Check:**
1. Is HTML valid?
2. Are tags supported by flutter_html?
3. Any JavaScript in HTML? (Not supported)

**Common Issues:**
- `<script>` tags → Remove before uploading
- `<style>` tags → Use inline styles instead
- `<iframe>` → Not supported, use links instead

### Cache Issues

**Clear Cache:**
```dart
final service = PolicyService();
service.clearCache();
```

**Disable Cache (Development Only):**
```dart
// In getPolicyByType(), comment out cache check:
// if (_policyCache.containsKey(type)) { ... }
```

## 📊 Directus Schema

### Collection: `policies`

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `title` | String | Display name |
| `content` | Text/HTML | Rich content |
| `type` | Selection | privacy, terms, about |
| `status` | Selection | draft, published |
| `date_created` | Timestamp | Auto |
| `date_updated` | Timestamp | Auto |

### Permissions

```
Public Role:
  ✅ READ (items where status='published')
  ✅ BROWSE collection

Admin Role:
  ✅ CREATE
  ✅ READ
  ✅ UPDATE
  ✅ DELETE
```

## 🎓 Code Snippets

### Show Policy in Dialog

```dart
showDialog(
  context: context,
  builder: (_) => Dialog(
    child: PolicyDetailsScreen(policyType: 'privacy'),
  ),
);
```

### Show Policy in Modal Bottom Sheet

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => PolicyDetailsScreen(policyType: 'terms'),
);
```

### Add Policy Link to Custom Widget

```dart
GestureDetector(
  onTap: () => Navigator.pushNamed(
    context,
    AppRoutes.policyDetails,
    arguments: 'privacy',
  ),
  child: Text(
    'View Privacy Policy',
    style: TextStyle(
      color: AppTheme.primary,
      decoration: TextDecoration.underline,
    ),
  ),
)
```

### Show Policies in ListView

```dart
FutureBuilder<List<PolicyModel>>(
  future: PolicyService().getPoliciesByType('privacy'),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return ListView.builder(
      itemCount: snapshot.data!.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(snapshot.data![i].title),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.policyDetails,
          arguments: 'privacy',
        ),
      ),
    );
  },
)
```

## ✅ Checklist for Integration

- [ ] Directus setup with policies collection
- [ ] At least one policy published for each type
- [ ] Test Settings screen navigation
- [ ] Test Registration screen links
- [ ] Test error scenarios
- [ ] Verify HTML rendering
- [ ] Test on different screen sizes
- [ ] Check performance (loading time)
- [ ] Verify translations if multilingual

## 📞 Support

For issues or questions:
1. Check this guide
2. Review code comments in files
3. Check Directus API documentation
4. Review flutter_html documentation

---

**Last Updated**: April 2026
**Status**: ✅ Production Ready
