# Testing Token Refresh Mechanism

This guide explains how to test the automatic token refresh functionality.

## Prerequisites

1. Make sure you have the latest code with all the fixes
2. Have the app running with debug logging enabled
3. Be logged in to the app

## Testing Methods

### Method 1: Wait for Natural Token Expiration

**Steps:**
1. Log in to the app
2. Check the logs for the JWT token expiration time
3. Wait for the token to expire (check the `exp` claim in the JWT)
4. Try to make any API request (e.g., load teachers, statistics)
5. Observe the logs for automatic token refresh

**What to look for:**
```
🔄 Got 401 error, attempting to refresh token...
🔄 Attempting to refresh access token...
🍪 Loaded X cookie(s) for api.mromarelkholy.com/api/Auth/refresh-token
🍪 Cookie header: refreshToken=...
✅ Token refreshed successfully
✅ Token refreshed, retrying request...
```

### Method 2: Manually Expire the Token (Recommended for Testing)

**Steps:**
1. Log in to the app
2. Note the current token from logs or SharedPreferences
3. Manually clear or corrupt the token in SharedPreferences
4. Or modify the token to be invalid (remove last few characters)
5. Try to make an API request
6. The app should automatically refresh the token

**How to manually expire token:**
- Use a debugger to set `_token` to an expired/invalid value
- Or use Flutter DevTools to modify SharedPreferences
- Or add a temporary button in the app to clear the token

### Method 3: Simulate 401 Response (Advanced)

**Steps:**
1. Use a proxy tool (like Charles Proxy or mitmproxy) to intercept requests
2. Modify the response to return 401 for any API call
3. Observe if the app automatically refreshes and retries

### Method 4: Test with Network Conditions

**Steps:**
1. Make an API request
2. While the request is in flight, manually expire the token on the server side (if you have access)
3. The next request should trigger refresh

## What to Verify

### ✅ Success Indicators

1. **Automatic Refresh Triggered:**
   - Log shows: `🔄 Got 401 error, attempting to refresh token...`

2. **Cookie Sent:**
   - Log shows: `🍪 Loaded X cookie(s) for...`
   - Cookie header is present and has a value

3. **Token Refreshed:**
   - Log shows: `✅ Token refreshed successfully`
   - New token is saved to SharedPreferences

4. **Request Retried:**
   - Log shows: `✅ Token refreshed, retrying request...`
   - Original request succeeds after retry

5. **No User Interruption:**
   - User doesn't see any error messages
   - App continues to work seamlessly

### ❌ Failure Indicators

1. **No Refresh Attempted:**
   - 401 error but no refresh logs
   - User sees error message

2. **Cookie Not Sent:**
   - Log shows: `🍪 No cookies found for...`
   - Or cookie value is empty

3. **Refresh Failed:**
   - Log shows: `❌ Token refresh failed: ...`
   - User is logged out or sees error

4. **Infinite Loop:**
   - Multiple refresh attempts without success
   - App crashes or hangs

## Testing Checklist

- [ ] Login successfully
- [ ] Verify refresh token cookie is saved during login
- [ ] Make an API request with expired token
- [ ] Verify automatic token refresh is triggered
- [ ] Verify cookie is sent with refresh request
- [ ] Verify new token is received and saved
- [ ] Verify original request is retried successfully
- [ ] Verify user experience is seamless (no errors shown)
- [ ] Test with multiple consecutive 401 errors
- [ ] Test refresh failure scenario (expired refresh token)

## Debug Commands

### Check Current Token
```dart
// In Flutter DevTools console or add to app
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('auth_token');
print('Current token: $token');
```

### Check Cookies
```dart
// In Flutter DevTools console
final cookieJar = HttpClientHelper.cookieJar;
final cookies = await cookieJar.loadForRequest(Uri.parse('https://api.mromarelkholy.com/api/Auth/refresh-token'));
print('Cookies: $cookies');
```

### Decode JWT Token (to check expiration)
Use an online JWT decoder or:
```dart
// Add this helper function
String? getTokenExpiration(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    
    final payload = parts[1];
    // Add padding if needed
    String normalizedPayload = payload;
    switch (payload.length % 4) {
      case 1:
        normalizedPayload += '===';
        break;
      case 2:
        normalizedPayload += '==';
        break;
      case 3:
        normalizedPayload += '=';
        break;
    }
    
    final decoded = base64Url.decode(normalizedPayload);
    final json = jsonDecode(utf8.decode(decoded));
    final exp = json['exp'] as int?;
    if (exp != null) {
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return expirationDate.toString();
    }
    return null;
  } catch (e) {
    return null;
  }
}
```

## Expected Log Flow

### Successful Refresh:
```
🔄 Got 401 error, attempting to refresh token...
🔄 Attempting to refresh access token...
🔵 API Request: POST https://api.mromarelkholy.com/api/Auth/refresh-token
🍪 Loaded 1 cookie(s) for api.mromarelkholy.com/api/Auth/refresh-token
   - refreshToken=abc123... (domain: api.mromarelkholy.com, path: /, value length: 100)
🍪 Cookie header: refreshToken=abc123...
🟢 API Response: 200
✅ Token refreshed successfully
✅ Token refreshed, retrying request...
🔵 API Request: GET https://api.mromarelkholy.com/api/Teacher/student/teachers
🟢 API Response: 200
```

### Failed Refresh (no cookie):
```
🔄 Got 401 error, attempting to refresh token...
🔄 Attempting to refresh access token...
🍪 No cookies found for api.mromarelkholy.com/api/Auth/refresh-token
🟢 API Response: 400
❌ Token refresh failed: No refresh token provided
```

## Quick Test Script

Add this to your app temporarily for quick testing:

```dart
// Add to a test screen or debug menu
ElevatedButton(
  onPressed: () async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Force token to be invalid
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', 'invalid_token');
    authService._token = 'invalid_token';
    
    // Try to make a request
    final response = await TeacherService.getStudentTeachers(
      token: 'invalid_token',
      authService: authService,
    );
    
    print('Response: $response');
  },
  child: Text('Test Token Refresh'),
)
```

## Notes

- Token expiration time is typically 15 minutes to 1 hour (check JWT `exp` claim)
- Refresh token expiration is usually much longer (days/weeks)
- If refresh token is expired, user will need to login again
- Cookies are stored in app's document directory: `.cookies/`



