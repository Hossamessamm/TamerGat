# Backend API Documentation

**Base URL:** `https://api.ibrahim-magdy.com/api`

This document provides comprehensive documentation for all available API endpoints extracted from the ASP.NET Core backend.

---

## 📋 Table of Contents

1. [Authentication APIs](#authentication-apis)
2. [Student APIs](#student-apis)
3. [Course APIs](#course-apis)
4. [Lesson APIs](#lesson-apis)
5. [Quiz & Questions APIs](#quiz--questions-apis)
6. [Statistics APIs](#statistics-apis)
7. [Data Models](#data-models)

---

## 🔐 Authentication APIs

### Base Route: `/api/Auth`

#### 1. **Register Student**
- **Endpoint:** `POST /api/Auth/register`
- **Authorization:** None (Public)
- **Content-Type:** `multipart/form-data`
- **Description:** Register a new student account

**Request Body (FormData):**
```json
{
  "UserName": "string (required)",
  "Password": "string (required)",
  "Email": "string (required)",
  "PhoneNumber": "string (required)",
  "AcademicYear": "enum (required) - See GradeEnum",
  "ConfirmPassword": "string (optional)",
  "ParentPhone": "string (required)",
  "Image": "file (optional)",
  "IsOnline": "boolean (optional)"
}
```

**GradeEnum Values:**
- `0` = Primary1
- `1` = Primary2
- `2` = Primary3
- `3` = Primary4
- `4` = Primary5
- `5` = Primary6
- `6` = Prep1
- `7` = Prep2
- `8` = Prep3
- `9` = Secondary1
- `10` = Secondary2
- `11` = Secondary3

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": null
}
```

**Error Response (400 Bad Request):**
```json
{
  "success": false,
  "message": "Error message",
  "data": null
}
```

---

#### 2. **Login**
- **Endpoint:** `POST /api/Auth/login`
- **Authorization:** None (Public)
- **Content-Type:** `application/json`
- **Description:** Login with email or mobile number

**Request Body:**
```json
{
  "EmailOrMobile": "string (email or phone number)",
  "Password": "string (required)"
}
```

**Success Response (200 OK):**
```json
{
  "token": "JWT_ACCESS_TOKEN",
  "user": {
    "id": "user_guid",
    "name": "User Name",
    "email": "user@example.com",
    "phoneNumber": "01234567890",
    "parentPhone": "01234567890",
    "imagePath": "path/to/image.jpg",
    "academicYear": "Secondary1",
    "registrationDate": "2024-01-01T00:00:00Z"
  }
}
```

**Error Responses:**
- `400 Bad Request`: Invalid credentials
- `403 Forbidden`: Account is inactive

**Notes:**
- Sets HTTP-only cookie named `refreshToken` for token refresh
- Access token should be stored and sent in `Authorization: Bearer {token}` header

---

#### 3. **Logout**
- **Endpoint:** `POST /api/Auth/logout`
- **Authorization:** Required (Student roles)
- **Content-Type:** `application/json`
- **Description:** Logout current user and invalidate tokens

**Headers:**
```
Authorization: Bearer {access_token}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Logged out successfully",
  "data": null
}
```

---

#### 4. **Refresh Token**
- **Endpoint:** `POST /api/Auth/refresh-token`
- **Authorization:** None (uses HTTP-only cookie)
- **Content-Type:** `application/json`
- **Description:** Get new access token using refresh token from cookie

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Token refreshed",
  "data": {
    "token": "NEW_JWT_ACCESS_TOKEN",
    "user": { /* UserInfoDto */ }
  }
}
```

**Error Response (400 Bad Request):**
- Clears the refresh token cookie
- Returns error message

---

#### 5. **Change Password**
- **Endpoint:** `POST /api/Auth/ChangePassword`
- **Authorization:** Required (Student roles)
- **Content-Type:** `application/json`

**Request Body:**
```json
{
  "currentPassword": "string",
  "newPassword": "string",
  "confirmPassword": "string"
}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Password changed successfully",
  "data": null
}
```

---

#### 6. **Forgot Password**
- **Endpoint:** `POST /api/Auth/forgot-password` or `POST /api/Auth/ForgotPassword`
- **Authorization:** None (Public)
- **Content-Type:** `application/json` or Query String
- **Description:** Request password reset OTP

**Request (Option 1 - Query String):**
```
POST /api/Auth/forgot-password?email=user@example.com
```

**Request (Option 2 - Body):**
```json
{
  "Email": "user@example.com"
}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP sent to your email",
  "data": null
}
```

---

#### 7. **Reset Password**
- **Endpoint:** `POST /api/Auth/reset-password` or `POST /api/Auth/ResetPassword`
- **Authorization:** None (Public)
- **Content-Type:** `application/json`
- **Description:** Reset password using OTP

**Request Body:**
```json
{
  "Email": "user@example.com",
  "Otp": "123456",
  "NewPassword": "newPassword123",
  "ConfirmPassword": "newPassword123"
}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Password reset successfully",
  "data": null
}
```

---

#### 8. **Reset Student Devices** (Moderator Only)
- **Endpoint:** `DELETE /api/Auth/reset-student-devices/{studentId}`
- **Authorization:** Required (Moderator role)
- **Description:** Reset device limit for a student

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Student devices reset successfully",
  "data": null
}
```

---

## 👨‍🎓 Student APIs

### Base Route: `/api/Student`

#### 1. **Add Course by Code**
- **Endpoint:** `POST /api/Student/add-course-by-code`
- **Authorization:** Required (Student or Moderator)
- **Content-Type:** `application/json`
- **Description:** Enroll in a course using a course code

**Query Parameters:**
```
Code: string (course code)
StudentId: string (student GUID)
```

**Example:**
```
POST /api/Student/add-course-by-code?Code=ABC123&StudentId=guid-here
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Course added successfully",
  "data": { /* Course data */ }
}
```

---

#### 2. **Add Unit by Code**
- **Endpoint:** `POST /api/Student/add-Unit-by-code`
- **Authorization:** Required (Student or Moderator)
- **Content-Type:** `application/json`
- **Description:** Enroll in a unit using a unit code

**Query Parameters:**
```
Code: string (unit code)
StudentId: string (student GUID)
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Unit added successfully",
  "data": { /* Unit data */ }
}
```

---

#### 3. **Get Student Enrolled Courses**
- **Endpoint:** `GET /api/Student/Student-Enrolled-Courses`
- **Authorization:** Required (Student or Moderator)
- **Description:** Get all courses a student is enrolled in

**Query Parameters:**
```
studentId: string (required)
pagenumber: int (default: 1)
pagesize: int (default: 10)
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "courseId": "guid",
        "courseName": "Course Name",
        "imageUrl": "url",
        "progress": 75.5,
        "enrollmentDate": "2024-01-01T00:00:00Z"
      }
    ],
    "totalCount": 10,
    "pageNumber": 1,
    "pageSize": 10
  }
}
```

---

#### 4. **Get Lesson Content**
- **Endpoint:** `GET /api/Student/contentlesson/{lessonId}`
- **Authorization:** Required (Student or Moderator)
- **Description:** Get lesson content (video URL, quiz, etc.)

**Path Parameters:**
```
lessonId: int (required)
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "lessonId": 1,
    "lessonName": "Introduction",
    "lessonType": "Video", // or "Quiz"
    "videoUrl": "youtube_video_id",
    "description": "Lesson description",
    "questions": [ /* if quiz */ ]
  }
}
```

---

#### 5. **Get Lesson Completion Status**
- **Endpoint:** `GET /api/Student/contentlessonCompletionStatus/{lessonId}`
- **Authorization:** Required (Student or Moderator)
- **Description:** Check if student completed a lesson

**Path Parameters:**
```
lessonId: int (required)
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "isCompleted": true,
    "completionDate": "2024-01-15T10:30:00Z",
    "score": 85.5 // if quiz
  }
}
```

---

#### 6. **Get Student Lessons Progress**
- **Endpoint:** `GET /api/Student/GetStudentLessonsProgress/{studentId}`
- **Authorization:** Public
- **Description:** Get all video lessons progress for a student

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "lessonId": 1,
      "lessonName": "Lesson 1",
      "courseName": "Course Name",
      "isCompleted": true,
      "completionDate": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

#### 7. **Get Student Quizzes Progress**
- **Endpoint:** `GET /api/Student/GetStudentQuizzesProgress/{studentId}`
- **Authorization:** Public
- **Description:** Get all quiz progress for a student

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "quizId": 1,
      "quizName": "Quiz 1",
      "courseName": "Course Name",
      "score": 85.5,
      "completionDate": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

#### 8. **Get Student Videos Progress by Parent**
- **Endpoint:** `GET /api/Student/GetStudentVideosProgressByParent/{parentphone}`
- **Authorization:** Public
- **Description:** Parents can check their child's video progress

**Query Parameters:**
```
parentPhone: string (path parameter)
studentPhone: string (query parameter)
```

---

#### 9. **Get Student Quizzes Progress by Parent**
- **Endpoint:** `GET /api/Student/GetStudentQuizzesProgressByParent/{parentphone}`
- **Authorization:** Public
- **Description:** Parents can check their child's quiz progress

**Query Parameters:**
```
parentPhone: string (path parameter)
studentPhone: string (query parameter)
```

---

## 📚 Course APIs

### Base Route: `/api/Course`

#### 1. **Get Course Tree** (Public)
- **Endpoint:** `GET /api/Course/tree`
- **Authorization:** None
- **Description:** Get complete course structure (units, lessons)

**Query Parameters:**
```
courseid: guid (required)
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "courseId": "guid",
    "courseName": "Course Name",
    "description": "Description",
    "imageUrl": "url",
    "units": [
      {
        "unitId": 1,
        "unitName": "Unit 1",
        "lessons": [
          {
            "lessonId": 1,
            "lessonName": "Lesson 1",
            "lessonType": "Video",
            "order": 1
          }
        ]
      }
    ]
  }
}
```

---

#### 2. **Get Course Tree with Progress** (Student)
- **Endpoint:** `GET /api/Course/tree-course-with-progress`
- **Authorization:** Required (Student roles)
- **Description:** Get course structure with student's progress

**Query Parameters:**
```
courseid: guid (required)
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "courseId": "guid",
    "courseName": "Course Name",
    "overallProgress": 45.5,
    "units": [
      {
        "unitId": 1,
        "unitName": "Unit 1",
        "progress": 60.0,
        "lessons": [
          {
            "lessonId": 1,
            "lessonName": "Lesson 1",
            "lessonType": "Video",
            "isCompleted": true,
            "completionDate": "2024-01-15T10:30:00Z"
          }
        ]
      }
    ]
  }
}
```

---

#### 3. **Get Unit Tree with Progress** (Student)
- **Endpoint:** `GET /api/Course/tree-unit-with-progress`
- **Authorization:** Required (Student roles)
- **Description:** Get unit structure with student's progress

**Query Parameters:**
```
unitId: int (required)
```

---

#### 4. **Get Available Free Courses** (Student)
- **Endpoint:** `GET /api/Course/free-courses`
- **Authorization:** Required (Student roles)
- **Description:** Get all free courses available to the student

**Query Parameters:**
```
pageNumber: int (default: 1)
pageSize: int (default: 10)
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "courseId": "guid",
        "courseName": "Free Course",
        "description": "Description",
        "imageUrl": "url",
        "isOpenToAll": true
      }
    ],
    "totalCount": 5,
    "pageNumber": 1,
    "pageSize": 10
  }
}
```

---

## 📖 Lesson APIs

### Base Route: `/api/Lesson`

*(To be documented based on LessonController.cs)*

---

## 📝 Quiz & Questions APIs

### Base Route: `/api/QuizResult`

*(To be documented based on QuizResultController.cs and QuestionController.cs)*

---

## 📊 Statistics APIs

### Base Route: `/api/Statistics`

*(To be documented based on StatisticsController.cs)*

---

## 📦 Data Models

### UserInfoDto
```typescript
{
  id: string;
  name: string;
  email: string;
  phoneNumber: string;
  parentPhone: string;
  imagePath: string;
  academicYear: string;
  registrationDate: DateTime;
}
```

### LoginResponseDto
```typescript
{
  token: string;
  user: UserInfoDto;
}
```

### ApiResponse<T>
```typescript
{
  success: boolean;
  message: string;
  data: T | null;
}
```

---

## 🔑 Authentication Flow

1. **Register** → Receive success message
2. **Login** → Receive access token + user info + HTTP-only refresh token cookie
3. **Store** access token in secure storage (SharedPreferences/SecureStorage)
4. **Use** access token in Authorization header: `Bearer {token}`
5. **Refresh** token when expired using `/api/Auth/refresh-token`
6. **Logout** → Clear tokens and cookies

---

## 🛡️ Authorization Roles

**Student Roles:**
- `Prim1Student` to `Prim6Student` (Primary 1-6)
- `Prep1Student` to `Prep3Student` (Preparatory 1-3)
- `Sec1Student` to `Sec3Student` (Secondary 1-3)

**Admin Role:**
- `Moderator`

---

## 🌐 Base Configuration

**Production API Base URL:**
```
https://api.ibrahim-magdy.com/api
```

**JWT Configuration:**
- Issuer: `https://api.ibrahim-magdy.com/`
- Audience: `https://api.ibrahim-magdy.com/`

---

## 📝 Notes

1. **Multi-Tenant Architecture**: The backend uses a multi-tenant system with separate databases per tenant
2. **Device Limit**: Students may have device registration limits
3. **Image Uploads**: Use `multipart/form-data` for endpoints accepting images
4. **Pagination**: Most list endpoints support `pageNumber` and `pageSize` parameters
5. **Error Handling**: All endpoints return consistent `ApiResponse` structure

---

*Last Updated: 2025-12-28*
*Extracted from: BackendIbrahim ASP.NET Core Project*
