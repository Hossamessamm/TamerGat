# API Call Flow Diagram

## Before Updates

```
┌──────────────┐
│    Screen    │
└──────┬───────┘
       │
       │ API Call
       ▼
┌──────────────────┐
│     Service      │
└──────┬───────────┘
       │
       │ HTTP Request + Token
       ▼
┌──────────────────┐
│  HttpClientHelper│
└──────┬───────────┘
       │
       │ Network
       ▼
┌──────────────────┐
│     Backend      │
└──────┬───────────┘
       │
       │ 401 Unauthorized
       ▼
❌ User sees error
❌ Must log in again
```

---

## After Updates

```
┌──────────────┐
│    Screen    │
└──────┬───────┘
       │
       │ API Call + AuthService
       ▼
┌──────────────────┐
│     Service      │
└──────┬───────────┘
       │
       │ Uses AuthenticatedApiClient
       ▼
┌────────────────────────┐
│ AuthenticatedApiClient │
└──────┬─────────────────┘
       │
       │ HTTP Request + Token
       ▼
┌──────────────────┐
│  HttpClientHelper│
└──────┬───────────┘
       │
       │ Network
       ▼
┌──────────────────┐
│     Backend      │
└──────┬───────────┘
       │
       │ 401 Unauthorized? 
       ▼
┌────────────────────────┐
│ AuthenticatedApiClient │
│  Detects 401 Error     │
└──────┬─────────────────┘
       │
       │ Refresh Token
       ▼
┌──────────────────┐
│   AuthService    │
│ refreshToken()   │
└──────┬───────────┘
       │
       │ POST /api/Auth/refresh-token
       ▼
┌──────────────────┐
│     Backend      │
└──────┬───────────┘
       │
       │ New Token
       ▼
┌────────────────────────┐
│ AuthenticatedApiClient │
│  Retry Original Request│
└──────┬─────────────────┘
       │
       │ Network with New Token
       ▼
┌──────────────────┐
│     Backend      │
└──────┬───────────┘
       │
       │ 200 OK
       ▼
✅ User continues seamlessly
✅ No interruption!
```

---

## Token Refresh Sequence

```
Request Flow:

1. Screen → Service(token, authService)
   │
2. Service → AuthenticatedApiClient
   │
3. AuthenticatedApiClient → Backend API
   │
4. Backend → 401 Unauthorized
   │
5. AuthenticatedApiClient detects 401
   │
6. AuthenticatedApiClient → AuthService.refreshToken()
   │
7. AuthService → POST /api/Auth/refresh-token
   │
8. Backend → New Access Token
   │
9. AuthService saves new token
   │
10. AuthenticatedApiClient retries original request
    │
11. Backend → 200 OK with data
    │
12. Service → Screen
    │
13. ✅ User sees data (never knew token expired!)
```

---

## Service Method Pattern

### All authenticated methods now follow this pattern:

```dart
class ExampleService {
  static Future<ResponseType?> methodName({
    required String param1,
    required String token,
    AuthService? authService,  // ← Optional parameter
    // ... other optional params
  }) async {
    
    // 1. Log request
    ApiDebugService().logRequest(...);
    
    // 2. Choose client based on authService availability
    http.Response response;
    if (authService != null) {
      // Use authenticated client (auto token refresh)
      final client = AuthenticatedApiClient(authService);
      response = await client.get(uri);
    } else {
      // Use regular client (backward compatible)
      response = await HttpClientHelper.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
    }
    
    // 3. Log response
    ApiDebugService().logResponse(...);
    
    // 4. Parse and return
    if (response.statusCode == 200) {
      return ResponseType.fromJson(json.decode(response.body));
    }
    
    return null;
  }
}
```

---

## JsonHelper Usage Pattern

### Before (Complex):

```dart
// Handling case-insensitive keys manually
final success = jsonData['success'] ?? 
                jsonData['Success'] ?? 
                jsonData['SUCCESS'] ?? 
                false;

final data = jsonData['data'] ?? 
             jsonData['Data'] ?? 
             jsonData['DATA'];

if (data != null && data is Map) {
  final token = data['token'] ?? 
                data['Token'] ?? 
                data['TOKEN'];
  
  if (data.containsKey('user') || 
      data.containsKey('User') || 
      data.containsKey('USER')) {
    final user = data['user'] ?? 
                 data['User'] ?? 
                 data['USER'];
    // ... more nesting
  }
}
```

### After (Clean):

```dart
// Using JsonHelper
final success = JsonHelper.getBool(jsonData, 'success') ?? false;
final data = JsonHelper.getMap(jsonData, 'data');

if (data != null) {
  final token = JsonHelper.getString(data, 'token');
  final userData = JsonHelper.getMap(data, 'user');
  if (userData != null) {
    final user = UserInfoDto.fromJson(userData);
  }
}
```

---

## Component Relationships

```
┌─────────────────────────────────────────────┐
│              Application Layer              │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │  Home    │  │ Courses  │  │ Profile  │ │
│  │  Screen  │  │  Screen  │  │  Screen  │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘ │
│       │             │              │       │
└───────┼─────────────┼──────────────┼───────┘
        │             │              │
        └─────────────┼──────────────┘
                      │
        ┌─────────────▼──────────────┐
        │      AuthService            │
        │  (Provider ChangeNotifier)  │
        └─────────────┬───────────────┘
                      │
        ┌─────────────▼──────────────┐
        │                            │
┌───────▼────────┐    ┌──────────────▼──────┐
│ SubjectService │    │   CourseService     │
│                │    │                     │
│ • getSubjects  │    │ • getEnrolledCourses│
└───────┬────────┘    │ • getCourseTree     │
        │             │ • enrollInCourse    │
        │             └──────────┬──────────┘
        │                        │
        └────────────┬───────────┘
                     │
        ┌────────────▼──────────────────┐
        │  AuthenticatedApiClient       │
        │                               │
        │  • Automatic 401 detection    │
        │  • Token refresh              │
        │  • Request retry              │
        └────────────┬──────────────────┘
                     │
        ┌────────────▼──────────────────┐
        │     HttpClientHelper          │
        │                               │
        │  • SSL handling               │
        │  • Cookie management          │
        │  • HTTP operations            │
        └────────────┬──────────────────┘
                     │
        ┌────────────▼──────────────────┐
        │         Backend API           │
        │   api.mromarelkholy.com       │
        └───────────────────────────────┘
```

---

## Error Handling Flow

```
API Call
  │
  ├─ 200 OK ──────────────────────────────► Success
  │
  ├─ 401 Unauthorized
  │   │
  │   ├─ Has AuthService?
  │   │   │
  │   │   ├─ Yes → Refresh Token
  │   │   │   │
  │   │   │   ├─ Refresh Success → Retry Request
  │   │   │   │   │
  │   │   │   │   ├─ 200 OK ────────────► Success
  │   │   │   │   └─ Error ─────────────► Failure
  │   │   │   │
  │   │   │   └─ Refresh Failed ────────► Logout User
  │   │   │
  │   │   └─ No → Return 401 Error ─────► Show Error
  │   │
  │   └─ (Old behavior without AuthService)
  │
  ├─ 4xx Client Error ───────────────────► Show Error Message
  │
  ├─ 5xx Server Error
  │   │
  │   └─ Has Retry Logic?
  │       │
  │       ├─ Yes → Retry with Backoff ──► Continue
  │       └─ No → Show Error ───────────► Show Error
  │
  └─ Network Error ──────────────────────► Show Network Error
```

---

## Coverage Statistics

### Service Methods with Auto Token Refresh

```
Before:  ███░░░░░░░  27% (3/11)
After:   ██████████  100% (11/11) ✅
```

### Screens Using AuthService

```
Before:  ███░░░░░░░  33% (1/3)
After:   ██████████  100% (3/3) ✅
```

### API Logging Coverage

```
Before:  █████░░░░░  55% (6/11)
After:   ██████████  100% (11/11) ✅
```

---

## Key Files Reference

### Core Authentication
- `lib/services/auth_service.dart` - Authentication & token management
- `lib/utils/authenticated_api_client.dart` - Auto refresh wrapper

### Service Layer
- `lib/services/subject_service.dart` - Subject operations
- `lib/services/course_service.dart` - Course operations
- `lib/services/api_debug_service.dart` - API logging

### Utilities
- `lib/utils/json_helper.dart` - JSON parsing utilities ✨ NEW
- `lib/utils/http_client_helper.dart` - HTTP client wrapper

### Configuration
- `lib/config/api_config.dart` - API endpoints & configuration

---

This diagram provides a complete visual reference for the updated API calling cycle.
