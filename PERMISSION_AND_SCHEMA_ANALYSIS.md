# Permission & Schema Analysis - Sendaal API Issues

## Executive Summary

The Flutter app is receiving **403 Forbidden** errors for two reasons:

1. **Collection Name Mismatch** ❌ `user_devices` vs `user_device`
2. **User Role Permissions** ⚠️ Missing or insufficient READ permissions

---

## Issues Found

### 1. ❌ CRITICAL: Collection Name Mismatch

**Problem:**
- App attempts: `POST/GET/PATCH /items/user_devices` (plural)
- Directus has: `/items/user_device` (singular)

**Evidence:**
From Directus schema query, the actual collection is:
```json
{
  "collection":"user_device",  // ← SINGULAR!
  "meta":{"collection":"user_device",...}
}
```

**Impact:**
- Device registration fails with 403/404
- Device tracking feature is completely broken

**Solution:**
Update the app in **two places**:
1. [lib/services/auth_session_service.dart](lib/services/auth_session_service.dart#L241) - Lines 241, 260, 264, 297, 313
2. [lib/services/endpoint.dart](lib/services/endpoint.dart) - Add correct endpoint

---

### 2. ⚠️ User Role Permissions

**Current State:**
- **notifications** collection: ✅ Read, update, delete, share permissions exist
- **user_device** collection: ✅ Create, read, update, share permissions exist

**Policy Configuration:**
- Policy ID: `abf8a154-5b1c-4a46-ac9c-7300570f4f17`
- Name: Public/Guest policy
- Assigned to: Guest user (739407ba-616a-4e2f-b038-b1a2b2ffd719)

**Root Cause of Errors:**
The logged-in user likely has a different role without proper permissions, OR the app is not sending the correct authentication token.

---

## Directus Collections Verified ✅

| Collection | Exists | Type |
|-----------|--------|------|
| `access_requests` | ✅ | Data |
| `access_request_accounts` | ✅ | Data |
| `notifications` | ✅ | Data |
| `user_device` | ✅ | Data |
| `financial_accounts` | ✅ | Data |
| `countries` | ✅ | Data |
| `account_types` | ✅ | Data |
| `providers` | ✅ | Data |
| `provider_availability` | ✅ | Data |
| `system_limits` | ✅ | Data |

---

## Action Items

### Priority 1: Fix Collection Name (EASY FIX)
Replace all instances of `user_devices` with `user_device`:

Files to update:
- [lib/services/auth_session_service.dart](lib/services/auth_session_service.dart)
  - Line 241: GET endpoint
  - Line 260: POST endpoint
  - Line 264: PATCH endpoint
  - Line 297: GET endpoint
  - Line 313: PATCH endpoint
  
- [lib/services/endpoint.dart](lib/services/endpoint.dart)
  - Add: `static const String userDevices = '/items/user_device';`

### Priority 2: Verify User Token & Permissions
- Verify the logged-in user has the "user" role assigned
- Check that user role has necessary permissions
- Run: GET `/users/me` with user token to see current user role
- If user has wrong role, reassign to "user" role in Directus

### Priority 3: Test 
- After fixes, test in mobile app:
  1. Login with regular user account
  2. Verify device registration succeeds
  3. Verify notifications can be fetched

---

## Recommendation

Fix the collection naming immediately:
```dart
// FROM (WRONG)
await _apiClient.get('/items/user_devices', ...)

// TO (CORRECT)
await _apiClient.get('/items/user_device', ...)
```

This is a straightforward search-and-replace that will resolve the 403 errors for device tracking.
