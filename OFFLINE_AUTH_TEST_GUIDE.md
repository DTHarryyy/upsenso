# Offline Auth Context Persistence - Test Guide

## Overview
The app now persists critical auth context (userId, email, businessId, roleId, businessName) to a local Drift SQLite database. This ensures that when the app is offline, users can still access their business information without requiring a live Supabase connection.

## Architecture
- **Remote**: Supabase Auth (user session)
- **Local Cache (Memory)**: `AuthRepositoryImpl._cachedUserInMemory` - populated on every auth action (signIn, signUp, verifySignUpOtp)
- **Local Cache (Persistent)**: Drift `auth_context` table - survives app restarts
- **Fallback Chain**: Live Supabase session → In-memory cache → Drift persistent cache

## Test Scenario 1: Offline After Sign-In

### Steps
1. Open the app
2. Sign in with valid credentials
3. Navigate to **Profile** or **Business Profile** screen to confirm user context is visible
4. **Enable Airplane Mode** on your device (or use `adb shell cmd connectivity airplane-mode enable` on Android)
5. **Force close the app** (swipe from recents or `adb shell am force-stop com.ateeba.pos`)
6. Wait 3 seconds
7. **Turn off Airplane Mode** to restore WiFi/mobile
8. **Reopen the app**

### Expected Behavior
- ✅ App loads without errors
- ✅ **Inventory** screen appears (not login screen) - proves `getCurrentUser()` returned cached user
- ✅ **User ID, Email, Business ID** visible in the Inventory debug panel (long-press debug text)
- ✅ Navigate to **Business Profile** → **Business Name**, **Role** visible (proves `getUserBusinessContext()` restored from Drift)
- ✅ No network errors or timeouts

### Validation Points
- Open debug panel: `flutter run -d <device> --dart-define=SHOW_DEBUG_MENU=true`
  - Inventory page has debug row showing: `User ID: <uuid>`, `Email: <email>`, etc.
- Check Drift database directly via DevTools:
  - Run `flutter pub run drift_dev` to inspect database
  - Query shows `auth_context` table with your user record

---

## Test Scenario 2: Offline Cold Start After Business Creation

This tests the critical scenario where users complete SignUp + Business Creation, then go offline before any other auth calls.

### Steps
1. Open the app
2. Sign up with a **new email** and password
3. Verify the sign-up OTP code (check email)
4. **Create a new business** (if prompts) or complete the onboarding flow
5. Confirm you can see your **Business Name**, **Role ID** on the main screen
6. **Enable Airplane Mode** immediately
7. Force close the app
8. Wait 5 seconds
9. **Keep Airplane Mode ON** and reopen the app

### Expected Behavior
- ✅ App restores to Inventory screen (not login)
- ✅ **Business Name** still visible in Business Profile
- ✅ **Role ID** preserved in the cached context
- ✅ No "unauthorized" or "session expired" errors
- ✅ User can still navigate the app and view inventory (if any)

### Why This Scenario Matters
- Before the fix: User database trigger created user_businesses record on Supabase, but it wasn't cached locally until `getUserBusinessContext()` was explicitly called. Offline cold start would lose businessId/roleId.
- After the fix: Auth context is cached immediately on `verifySignUpOtp()`, so offline restart can restore it from Drift.

---

## Test Scenario 3: Graceful Degradation (Offline After Initial Load)

### Steps
1. Sign in and let the app fully load
2. Disable WiFi/mobile connection (Airplane Mode)
3. Navigate through the app (Inventory, Add Item, Business Profile)
4. Try to perform remote operations (add item, update business) - should show "offline" message
5. Re-enable connection

### Expected Behavior
- ✅ Read-only screens (Inventory, Business Profile) show **no errors**
- ✅ Write operations gracefully fail with offline message (handled by app business layer)
- ✅ User info (name, role, businessId) remains visible throughout

---

## Test Scenario 4: Session Rotation (Switch User)

### Steps
1. Sign in as **User A**
2. Go to Settings → **Sign Out**
3. Sign in as **User B** (different email)
4. Navigate to Business Profile
5. Confirm **User B's business context** is shown, not User A's

### Expected Behavior
- ✅ `AuthRepositoryImpl._cachedUserInMemory` cleared on signOut
- ✅ Drift `auth_context` table cleared for User A
- ✅ User B's context cached immediately on sign-in
- ✅ No cached data from User A leaks to User B

### Validation
- Debug panel shows **User B's ID and email**
- Drift database shows only **User B's auth_context record**

---

## Test Scenario 5: Sync Recovery (Offline → Online)

### Steps
1. Sign in and create a business
2. Enable Airplane Mode
3. Force stop app
4. Disable Airplane Mode (go online)
5. Reopen app
6. App should restore offline session

### Expected Behavior
- ✅ Offline session restored from Drift cache
- ✅ When AuthBloc initializes `_onStarted()`, it calls `getCurrentUser()` → gets cached user
- ✅ Then calls `_getUserContextWithRetry()` which:
  - First tries remote fetch (now online) → succeeds and updates cache with latest data
  - If remote fails, falls back to Drift cache
- ✅ UI shows fresh data from Supabase if available, otherwise shows cached data

---

## Debugging & Validation

### View Cached Auth Context (Dart Code)
```dart
// In any async context, inject AuthContextDao and call:
final authContextDao = getIt<AuthContextDao>();
final cachedContext = await authContextDao.getContext('user-id-here');
print('Cached: ${cachedContext?.email}, businessId: ${cachedContext?.businessId}');
```

### View In-Memory Cache (Debug Panel)
- Open Inventory screen
- Long-press on any debug text to see cached values
- Check: `User ID`, `Email`, `Business ID`, `Role ID`

### Check Database File
- Android: `adb shell "sqlite3 /data/data/com.ateeba.pos/databases/pos.db" "SELECT * FROM auth_context;"`
- iOS: Use Xcode Device Organizer → Console, or export container

### Check SharedPreferences (Removal Validation)
- Old code used keys: `USER_ID`, `USER_EMAIL`, `BUSINESS_ID`, `ROLE_ID`, `BUSINESS_NAME`
- These should NO LONGER appear in SharedPreferences
- Validate they're only in Drift now: `SELECT * FROM auth_context;`

---

## Known Issues & Limitations

### 1. In-Memory Cache Not Persisted Between App Restarts
- **Issue**: `_cachedUserInMemory` is volatile (cleared on app kill)
- **Why it's OK**: `AuthBloc._onStarted()` calls `getUserBusinessContext()` on app init, which loads from Drift and populates the in-memory cache
- **Mitigation**: Drift persistent cache is the source of truth for cold starts

### 2. Cache Not Cleared on Remote Auth Token Expiry
- **Issue**: If Supabase session expires but user is offline, they can still see cached context
- **Why it's OK**: This is intentional offline-first behavior
- **When It Matters**: If another device signs out while user is offline, the local cache won't sync until next online session
- **Mitigation**: AuthBloc listens to Supabase auth state changes and clears cache on `!event.isLoggedIn`

### 3. Business Context Lag (Max 30s)
- **Issue**: If business is created on Supabase but trigger hasn't fired yet, offline cold start won't have businessId
- **Why**: Drift cache only has what's been synced from remote
- **Mitigation**: Users should stay online for the first 30+ seconds after business creation to ensure trigger and cache sync
- **Future**: Implement optimistic caching (save businessId immediately on create)

---

## Success Criteria Checklist

- [ ] **Scenario 1 Passed**: User stays authenticated after offline cold restart
- [ ] **Scenario 2 Passed**: Business context survives offline cold restart after signup
- [ ] **Scenario 3 Passed**: UI gracefully handles offline operations (read-only works, writes fail cleanly)
- [ ] **Scenario 4 Passed**: User B's context doesn't see User A's data
- [ ] **Scenario 5 Passed**: Cache syncs when going back online
- [ ] **Dart Analyzer**: `flutter analyze --no-pub` returns "No issues found"
- [ ] **Code Generation**: `flutter pub run build_runner build` completes without errors
- [ ] **Database**: `SELECT COUNT(*) FROM auth_context;` returns 1 (or more if multi-user testing)

---

## Rollback Instructions (If Issues Arise)

If the Drift auth context migration causes issues:

1. **Revert AuthRepositoryImpl** to use SharedPreferences fallback:
   ```bash
   git revert HEAD~1  # Assuming last commit was the migration
   ```

2. **Run migrations backward** (manual):
   - Drop `auth_context` table from database
   - Reset schema version to 2 in `app_database.dart`
   - Run `flutter pub run build_runner build` to regenerate

3. **Validate**: `flutter analyze --no-pub` should return "No issues found"

---

## Next Steps (Post-Validation)

Once all test scenarios pass:

1. **Update repository memory** with auth architecture decision
2. **Add integration tests** for offline auth restoration
3. **Implement optimistic caching** for business creation
4. **Add Drift database watch streams** to UI for reactive offline updates

