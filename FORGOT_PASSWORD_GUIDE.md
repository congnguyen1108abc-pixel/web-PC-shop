# 🔐 Forgot Password / Reset Password - Complete Guide

**Status:** ✅ Hoàn thành  
**Email Service:** Brevo (SendInBlue)  
**Token Expiry:** 15 phút  
**Token Usage:** 1 lần duy nhất

---

## 📋 Tổng Quan

Tính năng cho phép user reset mật khẩu qua email khi quên mật khẩu.

### Flow Hoạt Động

```
1. User nhập email → POST /api/auth/forgot-password
2. Backend tạo token (15 phút) → Gửi email qua Brevo
3. User nhận email → Click link reset
4. Frontend verify token → GET /api/auth/verify-reset-token?token=xxx
5. User nhập mật khẩu mới → POST /api/auth/reset-password
6. Backend reset password → Gửi email xác nhận
7. User đăng nhập với mật khẩu mới
```

---

## 🗄️ Database Changes

### Bảng Mới: `PasswordResetTokens`
```sql
CREATE TABLE PasswordResetTokens (
    TokenID       INT PRIMARY KEY IDENTITY(1,1),
    UserID        INT NOT NULL,
    ResetToken    NVARCHAR(100) UNIQUE NOT NULL,
    ExpiresAt     DATETIME NOT NULL,
    IsUsed        BIT DEFAULT 0,
    CreatedAt     DATETIME DEFAULT GETDATE()
);
```

### Stored Procedures Mới
1. `sp_Auth_ForgotPassword` - Tạo token reset
2. `sp_Auth_ResetPassword` - Đặt lại mật khẩu
3. `sp_Auth_VerifyResetToken` - Kiểm tra token hợp lệ
4. `sp_Auth_CleanupExpiredTokens` - Xóa token hết hạn (chạy định kỳ)

---

## 🚀 Setup Instructions

### Bước 1: Chạy SQL Script
```bash
# Mở SSMS
# Chạy DATABASE_PC.sql (phần cuối file)
# Hoặc chỉ chạy phần "PHẦN BỔ SUNG: FORGOT PASSWORD"
```

### Bước 2: Lấy Brevo API Key
1. Đăng ký tài khoản tại: https://www.brevo.com/
2. Vào **Settings** → **SMTP & API** → **API Keys**
3. Tạo API Key mới
4. Copy API Key

### Bước 3: Cấu Hình appsettings.json
```json
{
  "Brevo": {
    "ApiKey": "xkeysib-YOUR_ACTUAL_API_KEY_HERE",
    "SenderEmail": "noreply@pcstore.com",
    "SenderName": "PC Store",
    "FrontendUrl": "http://localhost:3000"
  }
}
```

**Lưu ý:**
- `ApiKey`: API Key từ Brevo (bắt đầu bằng `xkeysib-`)
- `SenderEmail`: Email đã verify trong Brevo
- `SenderName`: Tên hiển thị khi gửi email
- `FrontendUrl`: URL frontend để tạo link reset

### Bước 4: Verify Sender Email trong Brevo
1. Vào **Senders** → **Add a Sender**
2. Nhập email (vd: noreply@pcstore.com)
3. Verify email qua link Brevo gửi
4. Đợi approved

### Bước 5: Build & Run
```bash
cd d:\VSstudio\PC_Store
dotnet build
dotnet run
```

---

## 📡 API Endpoints

### 1. Forgot Password (Gửi Email)
```http
POST /api/auth/forgot-password
Content-Type: application/json

{
  "email": "user@example.com"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Nếu email tồn tại trong hệ thống, bạn sẽ nhận được email hướng dẫn đặt lại mật khẩu."
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Có lỗi xảy ra khi gửi email. Vui lòng thử lại sau."
}
```

**Rate Limit:** 5 requests / phút / IP

---

### 2. Verify Reset Token
```http
GET /api/auth/verify-reset-token?token=abc123-xyz789
```

**Response (Valid):**
```json
{
  "isValid": true,
  "email": "user@example.com",
  "message": "Token hợp lệ"
}
```

**Response (Invalid):**
```json
{
  "isValid": false,
  "email": null,
  "message": "Token đã hết hạn"
}
```

---

### 3. Reset Password
```http
POST /api/auth/reset-password
Content-Type: application/json

{
  "resetToken": "abc123-xyz789",
  "newPasswordHash": "hashed_password_here"
}
```

**Response (Success):**
```json
{
  "message": "Đặt lại mật khẩu thành công. Bạn có thể đăng nhập ngay bây giờ.",
  "updatedUserId": 5
}
```

**Response (Error):**
```json
{
  "message": "Token không hợp lệ, đã hết hạn hoặc đã được sử dụng."
}
```

**Rate Limit:** 5 requests / phút / IP

---

## 🧪 Testing Flow

### Test Case 1: Happy Path (Thành công)

#### Step 1: Forgot Password
```bash
curl -X POST http://localhost:5000/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

**Expected:**
- Response: `{"success":true,"message":"..."}`
- Email được gửi đến test@example.com
- Check inbox (hoặc Brevo logs)

#### Step 2: Lấy Token từ Email
- Mở email
- Click link hoặc copy token từ URL
- Ví dụ: `http://localhost:3000/reset-password?token=abc123-xyz789`
- Token: `abc123-xyz789`

#### Step 3: Verify Token
```bash
curl http://localhost:5000/api/auth/verify-reset-token?token=abc123-xyz789
```

**Expected:**
```json
{
  "isValid": true,
  "email": "test@example.com",
  "message": "Token hợp lệ"
}
```

#### Step 4: Reset Password
```bash
curl -X POST http://localhost:5000/api/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "resetToken":"abc123-xyz789",
    "newPasswordHash":"new_hashed_password"
  }'
```

**Expected:**
```json
{
  "message": "Đặt lại mật khẩu thành công...",
  "updatedUserId": 5
}
```

#### Step 5: Verify Email Confirmation
- Check inbox
- Email xác nhận "Mật khẩu đã được đặt lại" được gửi

#### Step 6: Login với mật khẩu mới
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email":"test@example.com",
    "passwordHash":"new_hashed_password"
  }'
```

**Expected:** Login thành công, nhận JWT token

---

### Test Case 2: Email không tồn tại

```bash
curl -X POST http://localhost:5000/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"notexist@example.com"}'
```

**Expected:**
- Response: `{"success":true,"message":"..."}`
- **Không gửi email** (bảo mật - không tiết lộ email có tồn tại hay không)

---

### Test Case 3: Token hết hạn

#### Step 1: Tạo token
```bash
curl -X POST http://localhost:5000/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
```

#### Step 2: Đợi 16 phút (hoặc update ExpiresAt trong DB)
```sql
-- Trong SSMS, set token hết hạn
UPDATE PasswordResetTokens
SET ExpiresAt = DATEADD(MINUTE, -1, GETDATE())
WHERE ResetToken = 'abc123-xyz789'
```

#### Step 3: Verify token
```bash
curl http://localhost:5000/api/auth/verify-reset-token?token=abc123-xyz789
```

**Expected:**
```json
{
  "isValid": false,
  "email": null,
  "message": "Token đã hết hạn"
}
```

---

### Test Case 4: Token đã sử dụng

#### Step 1: Reset password lần 1
```bash
curl -X POST http://localhost:5000/api/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "resetToken":"abc123-xyz789",
    "newPasswordHash":"password1"
  }'
```

**Expected:** Success

#### Step 2: Thử reset lại với cùng token
```bash
curl -X POST http://localhost:5000/api/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "resetToken":"abc123-xyz789",
    "newPasswordHash":"password2"
  }'
```

**Expected:**
```json
{
  "message": "Token không hợp lệ, đã hết hạn hoặc đã được sử dụng."
}
```

---

### Test Case 5: Rate Limiting

```bash
# Gửi 6 requests trong 1 phút
for i in {1..6}; do
  curl -X POST http://localhost:5000/api/auth/forgot-password \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com"}'
done
```

**Expected:**
- Request 1-5: Success
- Request 6: `429 Too Many Requests`

---

## 📧 Email Templates

### Email 1: Reset Password Link

**Subject:** 🔐 Đặt Lại Mật Khẩu - PC Store

**Content:**
```
Xin chào [FullName],

Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn.

[Đặt Lại Mật Khẩu] (Button)

Hoặc copy link: http://localhost:3000/reset-password?token=abc123

⚠️ Lưu ý:
- Link có hiệu lực trong 15 phút
- Link chỉ sử dụng được 1 lần
- Nếu bạn không yêu cầu, vui lòng bỏ qua email này
```

### Email 2: Reset Confirmation

**Subject:** ✅ Mật Khẩu Đã Được Đặt Lại - PC Store

**Content:**
```
Xin chào [FullName],

✅ Mật khẩu của bạn đã được đặt lại thành công.

Bạn có thể đăng nhập ngay bây giờ với mật khẩu mới.

⚠️ Nếu bạn không thực hiện thay đổi này, vui lòng liên hệ ngay.
```

---

## 🔒 Security Features

✅ **Token Security**
- Token ngẫu nhiên (GUID)
- Hết hạn sau 15 phút
- Chỉ dùng được 1 lần
- Tự động vô hiệu hóa token cũ

✅ **Email Privacy**
- Không tiết lộ email có tồn tại hay không
- Response luôn là "success" (cả khi email không tồn tại)

✅ **Rate Limiting**
- 5 requests / phút / IP
- Chặn brute force

✅ **SQL Injection Prevention**
- Parameterized queries
- Transaction với XACT_ABORT

✅ **Logging**
- Log mọi action (forgot, reset, verify)
- Không log sensitive data (password, token)

---

## 🛠️ Troubleshooting

### Issue 1: Email không được gửi

**Kiểm tra:**
```bash
# 1. API Key đúng chưa
# 2. Sender email đã verify chưa
# 3. Check logs
```

**Logs:**
```
Lỗi gửi email: 401 - {"message":"Invalid API key"}
```

**Giải pháp:**
- Kiểm tra `Brevo:ApiKey` trong appsettings.json
- Đảm bảo API Key bắt đầu bằng `xkeysib-`

---

### Issue 2: Token không hợp lệ

**Kiểm tra:**
```sql
-- Trong SSMS
SELECT * FROM PasswordResetTokens
WHERE ResetToken = 'abc123-xyz789'
```

**Kiểm tra:**
- `IsUsed = 0` (chưa dùng)
- `ExpiresAt > GETDATE()` (chưa hết hạn)

---

### Issue 3: Frontend không nhận được token

**Kiểm tra:**
- Email có đến inbox không (check spam)
- Link trong email có đúng format không
- `FrontendUrl` trong appsettings.json đúng chưa

---

## 📊 Database Queries

### Xem tất cả token
```sql
SELECT 
    t.TokenID,
    t.UserID,
    u.Email,
    t.ResetToken,
    t.ExpiresAt,
    t.IsUsed,
    t.CreatedAt,
    CASE 
        WHEN t.IsUsed = 1 THEN 'Đã dùng'
        WHEN t.ExpiresAt < GETDATE() THEN 'Hết hạn'
        ELSE 'Còn hiệu lực'
    END AS Status
FROM PasswordResetTokens t
JOIN Users u ON t.UserID = u.UserID
ORDER BY t.CreatedAt DESC
```

### Xóa token hết hạn
```sql
EXEC sp_Auth_CleanupExpiredTokens
```

### Vô hiệu hóa token thủ công
```sql
UPDATE PasswordResetTokens
SET IsUsed = 1
WHERE ResetToken = 'abc123-xyz789'
```

---

## 📝 Frontend Implementation

### React Example

```javascript
// 1. Forgot Password Page
const handleForgotPassword = async (email) => {
  const response = await fetch('/api/auth/forgot-password', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email })
  });
  
  const data = await response.json();
  alert(data.message);
};

// 2. Reset Password Page
const handleResetPassword = async (token, newPassword) => {
  // Hash password trước khi gửi
  const passwordHash = await hashPassword(newPassword);
  
  const response = await fetch('/api/auth/reset-password', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      resetToken: token,
      newPasswordHash: passwordHash
    })
  });
  
  if (response.ok) {
    alert('Đặt lại mật khẩu thành công!');
    navigate('/login');
  } else {
    alert('Token không hợp lệ hoặc đã hết hạn');
  }
};

// 3. Verify Token khi load page
useEffect(() => {
  const token = new URLSearchParams(window.location.search).get('token');
  
  fetch(`/api/auth/verify-reset-token?token=${token}`)
    .then(r => r.json())
    .then(data => {
      if (!data.isValid) {
        alert(data.message);
        navigate('/forgot-password');
      }
    });
}, []);
```

---

## ✅ Checklist

### Setup
- [ ] Chạy DATABASE_PC.sql
- [ ] Đăng ký Brevo account
- [ ] Lấy API Key
- [ ] Verify sender email
- [ ] Cấu hình appsettings.json
- [ ] Build project

### Testing
- [ ] Test forgot password (email tồn tại)
- [ ] Test forgot password (email không tồn tại)
- [ ] Test verify token (hợp lệ)
- [ ] Test verify token (hết hạn)
- [ ] Test reset password (thành công)
- [ ] Test reset password (token đã dùng)
- [ ] Test rate limiting
- [ ] Test email delivery

### Production
- [ ] Update `FrontendUrl` to production URL
- [ ] Update `SenderEmail` to real domain
- [ ] Setup Brevo production plan
- [ ] Setup cron job cho `sp_Auth_CleanupExpiredTokens`
- [ ] Monitor email delivery rate

---

**Status:** ✅ Ready for Testing  
**Last Updated:** 2024  
**Version:** 1.0
