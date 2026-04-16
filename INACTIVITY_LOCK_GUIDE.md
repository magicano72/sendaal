# Inactivity Lock Mechanism - Implementation Guide

## 📋 Overview

This implementation provides a production-ready inactivity lock mechanism for your Flutter app. When users leave the app and return after 3 minutes, they're prompted to enter their PIN before accessing the app.

---

## 🏗️ Architecture

### Components

#### 1. **SessionManager** (`lib/services/session_manager.dart`)
- **Purpose**: Core business logic for inactivity tracking
- **Responsibilities**:
  - Track app activity timestamps
  - Calculate inactivity duration
  - Determine if app should be locked
  - Manage lock state

**Key Methods**:
```dart
// Mark app as actively used
sessionManager.markAppActive();

// Record when app goes to background
sessionManager.markAppBackground();

// Check if app exceeds inactivity threshold
bool shouldLock = sessionManager.shouldLockApp();

// Reset lock state (on successful PIN/biometric)
sessionManager.resetLockState();

// Get remaining seconds until lock
int? secondsUntilLock = sessionManager.getSecondsUntilLock();
```

#### 2. **Session Provider** (`lib/providers/session_provider.dart`)
- **Purpose**: Riverpod integration for state management
- **Provides**:
  - `sessionManagerProvider` - Access to SessionManager singleton
  - `appLockStateProvider` - Stream of lock state changes

**Usage**:
```dart
final sessionManager = ref.watch(sessionManagerProvider);
final lockState = ref.watch(appLockStateProvider);
```

#### 3. **AppLifecycleObserver** (`lib/widgets/app_lifecycle_observer.dart`)
- **Purpose**: Watches app lifecycle and enforces lock policy
- **Behavior**:
  - Implements `WidgetsBindingObserver`
  - Monitors `AppLifecycleState` changes
  - Prevents duplicate navigation attempts
  - Safely navigates to PIN screen when needed

**Lifecycle Flow**:
```
AppPaused/Inactive
    ↓
markAppBackground() [timestamp saved]
    ↓
AppResumed
    ↓
Check shouldLockApp()
    ├─ YES (>3 min) → Navigate to PIN screen
    └─ NO (<3 min) → Continue normally
```

---

## 🔧 Configuration

### Inactivity Threshold

To change the 3-minute threshold, modify `SessionManager`:

```dart
// In lib/services/session_manager.dart
static const int inactivityThresholdMinutes = 3; // Change this value
```

### Customization Examples

**5-minute threshold**:
```dart
static const int inactivityThresholdMinutes = 5;
```

**1-minute threshold (for testing)**:
```dart
static const int inactivityThresholdMinutes = 1;
```

---

## 🔐 Lock Behavior Details

### When App Is Locked

1. **PIN screen is shown** with message: "Session expired. Please verify your PIN"
2. **Navigation stack is preserved** - users can press back after unlocking
3. **Tokens are NOT cleared** - session remains valid
4. **Background process stops** - timers, listeners are paused

### When User Unlocks (PIN or Biometric)

1. `SessionManager.resetLockState()` is called
2. Lock state is cleared
3. User navigates to home screen or previous screen
4. Active timestamp is reset

### Safe Window (within 3 minutes)

1. Background timestamp is recorded
2. No PIN prompt on app resume
3. User continues from current screen
4. Session remains continuous

---

## 🚀 Integration Points

### 1. **Main App** (`lib/main.dart`)
✅ Already integrated:
```dart
AppLifecycleObserver(
  child: MaterialApp(
    // ...
  ),
)
```

### 2. **PIN Login Screen** (`lib/screens/auth/pin_login_screen.dart`)
✅ Already integrated:
- `SessionManager` imported
- `resetLockState()` called on successful PIN verification
- `resetLockState()` called on successful biometric authentication

---

## 🛡️ Production Safety Features

### 1. **Duplicate Navigation Prevention**
```dart
bool _lockNavigationInProgress = false;

// Prevents multiple simultaneous lock navigation attempts
if (_lockNavigationInProgress) {
  return;
}
```

### 2. **Context Safety Checks**
```dart
// Ensures context is ready after app resume
await Future.delayed(const Duration(milliseconds: 500));

// Checks if already on PIN screen
if (currentRoute == AppRoutes.pinLogin) {
  return;
}
```

### 3. **PIN Hash Verification**
```dart
// Ensures user has PIN setup before forcing lock
final pinHash = await AuthSessionService.instance
    .secureStorage.read(key: 'pin_hash');
if (pinHash == null) {
  return; // Don't lock if no PIN exists
}
```

### 4. **Navigation Stack Preservation**
```dart
// Uses pushNamedAndRemoveUntil to preserve ALL routes
navigator.pushNamedAndRemoveUntil(
  AppRoutes.pinLogin,
  (route) => true, // Keep all previous routes
  arguments: {'isInactivityLock': true},
);
```

---

## 🧪 Testing Scenarios

### Test 1: Within Safe Window (< 3 minutes)
```
1. Open app and navigate to Transfer screen
2. Press home button (app goes to background)
3. Wait 2 minutes
4. Reopen app
✓ Expected: Stay on Transfer screen (no PIN prompt)
```

### Test 2: Exceeds Inactivity Window (> 3 minutes)
```
1. Open app and navigate to Accounts screen
2. Press home button (app goes to background)
3. Wait 4 minutes (or longer)
4. Reopen app
✓ Expected: Navigated to PIN screen, forced to unlock
✓ After PIN: Can navigate back to previous screens
```

### Test 3: Biometric Unlock
```
1. Setup biometric authentication
2. Trigger inactivity lock (wait > 3 min in background)
3. Reopen app → forced to PIN screen
4. Use biometric unlock
✓ Expected: Successfully authenticate and navigate to home
```

### Test 4: Multiple App Resumes
```
1. Go to background → Wait 1 min → Resume (no lock expected)
2. Go to background → Wait 2 min more → Resume (no lock expected)
   [Note: Lock timer resets with each resume]
✓ Expected: No lock triggered, safe window resets
```

### Test 5: Lock Countdown
```
1. Trigger lock (> 3 minutes in background)
2. Observe PIN lock screen appearance time
3. Check debug logs for lifecycle events
✓ Expected: ~500ms delay from app resume to PIN screen
```

---

## 📊 Debug Logs

The implementation includes comprehensive debug logging. Look for these patterns:

```
[SessionManager] App marked as active at <timestamp>
[SessionManager] App went to background at <timestamp>
[SessionManager] Inactivity check: inactivity=<X>m, threshold=3m, shouldLock=<bool>
[AppLifecycleObserver] App paused
[AppLifecycleObserver] App resumed
[AppLifecycleObserver] Lock navigation already in progress
[AppLifecycleObserver] Navigated to PIN lock screen
```

### Enable Debug Output
```dart
// In SessionManager.dart — uses Flutter's built-in debugPrint
// Already enabled, visible in Android Studio / VS Code console
```

---

## ⚙️ Advanced Customization

### Custom Lock Duration Calculation

If you need more complex logic (e.g., different durations based on user role):

```dart
// Add to SessionManager
bool shouldLockAppCustom(UserRole userRole) {
  if (_lastActiveTime == null || _backupgroundTime == null) {
    return false;
  }

  final inactivityDuration = _backupgroundTime!.difference(_lastActiveTime!);
  
  final threshold = userRole == UserRole.admin 
    ? Duration(minutes: 5)
    : Duration(minutes: 3);
  
  return inactivityDuration > threshold;
}
```

### Event Notifications

Add callbacks when lock is triggered:

```dart
// Add to SessionManager
VoidCallback? onAppLocked;
VoidCallback? onAppUnlocked;

void _handleLock() {
  _isAppLocked = true;
  onAppLocked?.call();
}

void resetLockState() {
  _isAppLocked = false;
  onAppUnlocked?.call();
}
```

### Custom Navigator Handling

For apps with multiple navigators:

```dart
// Update AppLifecycleObserver._navigateToPinLock()
final navigator = rootNavigator ?? secondaryNavigator;
navigator.pushNamedAndRemoveUntil(
  AppRoutes.pinLogin,
  (route) => true,
);
```

---

## 🐛 Troubleshooting

### Issue: PIN Screen Appears Unexpectedly
**Solution**:
1. Check SessionManager logs for timestamp calculations
2. Verify `inactivityThresholdMinutes` value
3. Ensure system time hasn't jumped backward
4. Check if `markAppBackground()` is being called correctly

### Issue: Multiple PIN Screens Appear
**Solution**: The `_lockNavigationInProgress` flag prevents this. If still occurring:
1. Check for custom navigation code
2. Ensure only one `AppLifecycleObserver` exists
3. Verify no manual lock-triggering calls

### Issue: User Can Access App Without PIN
**Solution**:
1. Verify PIN is saved (`pinHash` exists in secure storage)
2. Check `shouldLockApp()` logic
3. Ensure `NavigatorState` is available

### Issue: Navigation Stack Lost After Unlock
**Solution**: This shouldn't happen with current implementation. If it does:
1. Check that `pushNamedAndRemoveUntil(route) => true` is used
2. Verify no clearHistoryOnLock flags elsewhere
3. Look for other navigation happening during lock

---

## 📚 File Structure

```
lib/
├── services/
│   ├── session_manager.dart          ← Core inactivity logic
│   └── auth_session_service.dart     ← Existing (updated)
├── providers/
│   └── session_provider.dart         ← Riverpod integration
├── widgets/
│   └── app_lifecycle_observer.dart   ← Lifecycle observer
├── screens/
│   └── auth/
│       └── pin_login_screen.dart     ← Updated to reset lock state
└── main.dart                         ← App entry with observer
```

---

## 🔄 Flow Diagram

```
USER INTERACTION
    ↓
[App Running]
    ↓ (Press Home)
AppLifecycleObserver.didChangeAppLifecycleState(paused)
    ↓
SessionManager.markAppBackground() [save timestamp]
    ↓
[Wait in Background]
    ↓ (Reopen App)
AppLifecycleObserver.didChangeAppLifecycleState(resumed)
    ↓
SessionManager.shouldLockApp() [check time difference]
    ├─ FALSE (< 3 min)
    │   └─ Continue to app
    │
    └─ TRUE (> 3 min)
        └─ Navigate to PIN screen
            ↓
        User enters PIN
            ↓
        SessionManager.resetLockState()
            ↓
        Navigate to home/previous screen
```

---

## 💾 Persistence

**What's Stored**:
- Last active timestamp (in memory only, not persisted)
- App lock state (in memory)
- PIN hash (secure storage, existing)

**What's NOT Stored**:
- Background timestamp (cleared on resume)
- No persistent lock state files

This design ensures:
- Memory efficiency
- No data left after app termination
- Clean state on each app launch

---

## 🚫 Known Limitations

1. **System Time Changes**: If system time jumps backward, lock might not trigger
   - *Mitigation*: Add system time validation if needed

2. **No Cross-Device Sync**: Lock state not synced across devices
   - *Mitigation*: Tokens provide secondary security

3. **No Customizable Lock Message**: PIN screen shows generic message
   - *Mitigation*: Extend PinLoginScreen with custom banner if needed

---

## 🎯 Next Steps (Optional Enhancements)

1. **Lock Notification**: Show notification while in background
2. **Biometric UI**: Add fingerprint icon to PIN screen when locked
3. **Analytics**: Track lock events for security insights
4. **Configurable Threshold**: Allow users to set inactivity duration
5. **Backend Sync**: Validate lock state with backend on resume

---

## 📞 Support

For issues or questions:
1. Check debug logs for lifecycle events
2. Verify SessionManager singleton is accessible
3. Ensure AppLifecycleObserver is mounted in widget tree
4. Check that PIN is saved in secure storage before locking
