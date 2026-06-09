// Update Profile API - Usage Examples
// For Flutter/Dart client or any REST client

// 1. UPDATE SINGLE FIELD - Full Name
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "full_name": "Nguyễn Văn A"
}

Response (200 OK):
{
  "success": true,
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "full_name": "Nguyễn Văn A",
    "phone": "+84901234567",
    "avatar_url": null,
    "date_of_birth": null,
    "gender": null,
    "role": "customer",
    "status": "active",
    ...
  }
}

// 2. UPDATE MULTIPLE FIELDS
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "full_name": "Nguyễn Văn A",
  "phone": "0909876543",
  "date_of_birth": "1990-01-15",
  "gender": "male",
  "address": "Tầng 3, 123 Đường ABC, Quận 1, TP HCM"
}

Response (200 OK):
{
  "success": true,
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "full_name": "Nguyễn Văn A",
    "phone": "+84909876543",
    "avatar_url": null,
    "date_of_birth": "1990-01-15",
    "gender": "male",
    "address": "Tầng 3, 123 Đường ABC, Quận 1, TP HCM",
    "role": "customer",
    "status": "active",
    ...
  }
}

// 3. UPDATE AVATAR URL
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "avatar_url": "https://cloudinary.com/avatar/user-123.jpg"
}

Response (200 OK):
{
  "success": true,
  "data": {
    "id": "user-uuid",
    "avatar_url": "https://cloudinary.com/avatar/user-123.jpg",
    ...
  }
}

// 4. PARTIAL UPDATE - Only update student_id and university
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "student_id": "STU123456",
  "university": "FPT University"
}

Response (200 OK):
{
  "success": true,
  "data": {
    "student_id": "STU123456",
    "university": "FPT University",
    ...
  }
}

// 5. ERROR - Empty request body
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{}

Response (400 Bad Request):
{
  "success": false,
  "message": "Không có trường hợp lệ để cập nhật"
}

// 6. ERROR - Invalid phone number
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "phone": "not-a-phone"
}

Response (400 Bad Request):
{
  "success": false,
  "message": "Invalid phone number"
}

// 7. ERROR - Invalid gender
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "gender": "other"
}

Response (400 Bad Request):
{
  "success": false,
  "message": "Giới tính chỉ có thể là male hoặc female"
}

// 8. ERROR - Invalid date format
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "date_of_birth": "01/15/1990"
}

Response (400 Bad Request):
{
  "success": false,
  "message": "Ngày sinh phải có format YYYY-MM-DD"
}

// 9. ERROR - Invalid date (too young)
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "date_of_birth": "2015-01-15"
}

Response (400 Bad Request):
{
  "success": false,
  "message": "Tuổi phải từ 13 tuổi trở lên"
}

// 10. ERROR - Invalid avatar URL
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "avatar_url": "not-a-valid-url"
}

Response (400 Bad Request):
{
  "success": false,
  "message": "URL avatar không hợp lệ"
}

// 11. ERROR - Try to update email (forbidden)
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "email": "newemail@example.com"
}

Response (400 Bad Request):
{
  "success": false,
  "message": "Không được sửa email hoặc role"
}

// 12. ERROR - Try to update role (forbidden)
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "role": "admin"
}

Response (400 Bad Request):
{
  "success": false,
  "message": "Không được sửa email hoặc role"
}

// 13. ERROR - Try to update password (forbidden)
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "password": "NewPassword123"
}

Response (400 Bad Request):
{
  "success": false,
  "message": "Không được sửa field password"
}

// 14. ERROR - Missing authentication
PATCH /api/customers/me
Content-Type: application/json

{
  "full_name": "Hacker"
}

Response (401 Unauthorized):
{
  "success": false,
  "message": "Thiếu access token"
}

// 15. ERROR - Invalid token
PATCH /api/customers/me
Authorization: Bearer invalid.token.here
Content-Type: application/json

{
  "full_name": "Hacker"
}

Response (401 Unauthorized):
{
  "success": false,
  "message": "Token không hợp lệ hoặc đã hết hạn",
  "code": "invalid_token"
}

// 16. ERROR - User not found (account deleted)
PATCH /api/customers/me
Authorization: Bearer {validTokenForDeletedUser}
Content-Type: application/json

{
  "full_name": "Test"
}

Response (404 Not Found):
{
  "success": false,
  "message": "Không tìm thấy profile"
}

// 17. REQUEST WITH WHITESPACE
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "full_name": "   "
}

Response (400 Bad Request):
{
  "success": false,
  "message": "Tên đầy đủ không được để trống"
}

// 18. FULL PROFILE UPDATE
PATCH /api/customers/me
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "full_name": "Nguyễn Văn A",
  "phone": "0909876543",
  "date_of_birth": "1990-01-15",
  "gender": "male",
  "avatar_url": "https://example.com/avatar.jpg",
  "address": "123 Main St",
  "student_id": "STU123456",
  "university": "FPT University"
}

Response (200 OK):
{
  "success": true,
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "full_name": "Nguyễn Văn A",
    "phone": "+84909876543",
    "avatar_url": "https://example.com/avatar.jpg",
    "date_of_birth": "1990-01-15",
    "gender": "male",
    "role": "customer",
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:35:00Z",
    "referral_code": "REF123",
    "last_seen_at": "2024-01-15T10:35:00Z",
    "student_id": "STU123456",
    "university": "FPT University",
    "address": "123 Main St",
    "city": null,
    "district": null,
    "ward": null,
    "total_orders": 0,
    "total_spent": 0,
    "loyalty_points": 0,
    "preferred_payment_method": null
  }
}
