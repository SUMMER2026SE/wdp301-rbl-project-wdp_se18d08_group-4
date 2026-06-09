# Update Profile API Documentation

## Endpoint
**PATCH** `/api/customers/me`

## Authentication
- Required: `Authorization: Bearer {accessToken}`
- Only authenticated customers can update their own profile
- Returns 401 if not authenticated

## Request Body (all fields optional)
```json
{
  "full_name": "string (1-255 chars)",
  "phone": "string (Vietnamese phone format)",
  "avatar_url": "string (valid URL)",
  "date_of_birth": "string (YYYY-MM-DD format)",
  "gender": "enum (male | female)",
  "address": "string (1-255 chars)",
  "student_id": "string",
  "university": "string"
}
```

## Field Validation Rules

### full_name
- Optional
- If provided: cannot be empty or whitespace only
- Max 255 characters
- Stored in `profiles.full_name`

### phone
- Optional
- Vietnamese phone number format (accepts various formats)
- Normalized to `+84X` format before storage
- Throws error if invalid
- Stored in `profiles.phone`

### avatar_url
- Optional
- Must be a valid URL if provided
- Throws error if not a valid URL
- Stored in `profiles.avatar_url`

### date_of_birth
- Optional
- Must be in `YYYY-MM-DD` format
- Date must be valid (e.g., not 2024-02-30)
- Date cannot be in the future
- Age must be at least 13 years old
- Stored in `profiles.date_of_birth`

### gender
- Optional
- Enum: `male` or `female` (case-insensitive)
- Stored in `profiles.gender`

### address
- Optional
- Max 255 characters
- Stored in `customer_profiles.address`

### student_id
- Optional
- Stored in `customer_profiles.student_id`

### university
- Optional
- Stored in `customer_profiles.university`

## Protected Fields (Cannot Update)
The following fields cannot be updated via this endpoint:
- `id` - User ID
- `email` - Email address
- `role` - User role
- `status` - Account status
- `password` - Password
- `created_at` - Creation timestamp
- `updated_at` - Update timestamp
- `total_orders` - Order count (calculated)
- `total_spent` - Total spending (calculated)
- `loyalty_points` - Loyalty points (calculated)
- `referral_code` - Referral code (system-generated)

Attempting to update these fields returns 400 error.

## Response (Success)
**Status: 200 OK**

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "full_name": "Updated Name",
    "phone": "+84901234567",
    "avatar_url": "https://example.com/avatar.jpg",
    "date_of_birth": "1990-01-15",
    "gender": "male",
    "role": "customer",
    "status": "active",
    "referral_code": "REF123",
    "last_seen_at": "2024-01-15T10:30:00Z",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T10:35:00Z",
    "student_id": "STU123",
    "university": "FPT University",
    "address": "123 Main St, City",
    "city": "Ho Chi Minh",
    "district": "District 1",
    "ward": "Ward 1",
    "total_orders": 5,
    "total_spent": 500000,
    "loyalty_points": 1000,
    "preferred_payment_method": "credit_card"
  }
}
```

## Error Responses

### 400 Bad Request
**Reason:** Validation error or invalid input

```json
{
  "success": false,
  "message": "Tên đầy đủ không được để trống"
}
```

Possible error messages:
- "Tên đầy đủ không được để trống" - full_name is empty
- "Tên đầy đủ không được vượt quá 255 ký tự" - full_name too long
- "Invalid phone number" - Invalid phone format
- "Giới tính chỉ có thể là male hoặc female" - Invalid gender
- "Ngày sinh phải có format YYYY-MM-DD" - Invalid date format
- "Ngày sinh không hợp lệ" - Invalid date
- "Ngày sinh không thể ở trong tương lai" - Date in future
- "Tuổi phải từ 13 tuổi trở lên" - User too young
- "URL avatar không hợp lệ" - Invalid URL
- "Địa chỉ không được vượt quá 255 ký tự" - Address too long
- "Không được sửa email hoặc role" - Attempt to update email/role
- "Không được sửa field {fieldName}" - Attempt to update protected field
- "Không có trường hợp lệ để cập nhật" - Empty request body

### 401 Unauthorized
**Reason:** Missing or invalid authentication token

```json
{
  "success": false,
  "message": "Thiếu access token"
}
```

or

```json
{
  "success": false,
  "message": "Token không hợp lệ hoặc đã hết hạn",
  "code": "invalid_token"
}
```

### 403 Forbidden
**Reason:** User is not a customer or account is disabled

```json
{
  "success": false,
  "message": "Không có quyền truy cập"
}
```

### 404 Not Found
**Reason:** User profile not found

```json
{
  "success": false,
  "message": "Không tìm thấy profile"
}
```

### 500 Internal Server Error
**Reason:** Database or server error

```json
{
  "success": false,
  "message": "Database error message"
}
```

## Partial Update
- Only provided fields are updated
- Omitted fields retain their current values
- Empty request body (JSON `{}`) returns 400 error

## Example Usage

### Update single field
```bash
curl -X PATCH http://localhost:3000/api/customers/me \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"full_name": "New Name"}'
```

### Update multiple fields
```bash
curl -X PATCH http://localhost:3000/api/customers/me \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "New Name",
    "phone": "0901234567",
    "gender": "male",
    "date_of_birth": "1990-01-15",
    "address": "123 Main St"
  }'
```

## Architecture Notes
- **Controller**: [customers.controller.js](../src/controllers/customers.controller.js) - Thin layer, delegates to service
- **Service**: [customers.service.js](../src/services/customers.service.js) - Business logic and validation
- **Route**: [customers.routes.js](../src/routes/customers.routes.js) - Route definition with auth middleware
- **Auth Middleware**: [auth.middleware.js](../src/middleware/auth.middleware.js) - `requireAuth`, `requireRole('customer')`
- **Database Tables**:
  - `profiles` - User profile (full_name, phone, avatar_url, date_of_birth, gender, etc.)
  - `customer_profiles` - Customer-specific data (student_id, university, address, etc.)

## Implementation Notes
1. Uses whitelist approach for updatable fields
2. Blacklist approach for protected fields
3. Full validation at service layer
4. Phone normalization using `normalizePhone()` utility
5. Partial updates supported - only provided fields are updated
6. Database errors wrapped with appropriate HTTP status codes
7. Sensitive data not exposed in response
8. User ID taken from JWT token (not from request body)
