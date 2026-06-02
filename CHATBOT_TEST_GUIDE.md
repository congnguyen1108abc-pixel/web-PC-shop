# ✅ HƯỚNG DẪN TEST CHATBOT AI - HOÀN CHỈNH

## 🔧 FIX ĐÃ THỰC HIỆN:

### 1. **Tạo file JavaScript riêng** (`wwwroot/js/chatbot.js`)
   - ✅ Quản lý logic chatbot độc lập
   - ✅ Tránh trùng lặp code
   - ✅ Dễ debug và maintain

### 2. **Fix event listeners**
   - ✅ Dùng class `ChatbotManager` để quản lý
   - ✅ Chờ DOM ready trước khi init
   - ✅ Kiểm tra elements tồn tại
   - ✅ Console log chi tiết

### 3. **Fix HTML structure**
   - ✅ Xóa code JavaScript cũ khỏi homepage.html
   - ✅ Thêm reference tới `chatbot.js`
   - ✅ Giữ HTML elements sạch sẽ

---

## 🚀 HƯỚNG DẪN TEST:

### Bước 1: Cấu hình API Key

Mở file `.env.local` (ở thư mục root `G:\PC_Store\`):

```
OpenAI__ApiKey=sk-proj-YOUR_API_KEY_HERE
```

**Thay** `YOUR_API_KEY_HERE` **bằng API Key thực của bạn**
(Ví dụ: `OpenAI__ApiKey=sk-proj-abc123xyz789...`)

### Bước 2: Chạy Application

**PowerShell:**
```powershell
cd G:\PC_Store
dotnet run
```

**Hoặc Visual Studio:**
- Nhấn **F5** để start debugging

**Hoặc button Run:**
- Click nút **Run** (play icon) ở toolbar

### Bước 3: Mở Browser

Truy cập:
```
https://localhost:5001/Homepage
```

hoặc

```
https://localhost:5001/
```

### Bước 4: Tìm Chatbot Button

- Tìm button **"💬"** ở **góc dưới phải** màn hình
- Nó sẽ **nổi lên** và **lấp láy** (float animation)

### Bước 5: Test Chức Năng

#### Test 1: Mở/Đóng Chatbot
```
✅ Click button "💬"
✅ Modal chatbot mở (nên thấy animation slide up)
✅ Button thay đổi thành "X" xoay
✅ Click lại hoặc button "✕" để đóng
```

#### Test 2: Nhập Tin Nhắn + Enter Key
```
✅ Input field: "Nhập câu hỏi..."
✅ Nhập: "Xin chào"
✅ Nhấn ENTER
✅ Nên thấy:
   - Tin nhắn "Xin chào" hiển thị (màu blue, góc phải)
   - Loading animation (3 chấm nhảy)
   - AI response hiển thị (màu xám, góc trái)
```

#### Test 3: Click Button "Gửi"
```
✅ Nhập tin nhắn
✅ Click nút "Gửi" (bên phải input)
✅ Chatbot phản hồi
```

#### Test 4: Câu Hỏi Đặc Biệt (Test AI)
Hỏi chatbot:
```
- "Giá CPU i9 bao nhiêu?"
- "Tôi muốn chọn laptop gaming"
- "Có khuyến mãi không?"
- "Hỗ trợ giờ mấy?"
- "Bạn là ai?"
- Bất kỳ câu hỏi nào
```

**Chatbot sẽ trả lời chi tiết dựa trên Knowledge Base**

#### Test 5: Error Handling
```
✅ Không viết gì, nhấn ENTER
   → Không gửi (input empty)

✅ Tắt server, gửi tin nhắn
   → Thấy error message

✅ API Key sai
   → Thấy error kết nối
```

---

## 🐛 DEBUG - Nếu gặp lỗi:

### 1. Mở Developer Console (F12)

**Chrome/Edge:**
- Nhấn **F12**
- Tab **Console**

**Firefox:**
- Nhấn **F12**
- Tab **Console**

### 2. Xem logs:

Nên thấy:
```
🤖 Initializing Chatbot Manager...
✅ All chatbot elements found
✅ Event listeners setup complete
✅ Chatbot API is ready
```

### 3. Nếu không thấy logs:

**Kiểm tra:**
```javascript
// Gõ vào Console:
document.getElementById("chatbot-button")
document.getElementById("chatbot-modal")
document.getElementById("chatbot-input")
document.getElementById("chatbot-send")

// Nếu return null → elements không tìm thấy
// Nếu return object → elements OK
```

### 4. Test API trực tiếp:

```javascript
// Gõ vào Console:
fetch("/api/chatbot/health")
  .then(r => r.json())
  .then(d => console.log(d))
```

Nên thấy:
```
{status: "Chatbot API is running"}
```

---

## 📋 CHECKLIST TEST:

- [ ] Button "💬" xuất hiện ở góc dưới phải
- [ ] Click button → modal mở
- [ ] Modal có 3 phần: header, messages, input
- [ ] Header: "🤖 AI Assistant" + nút "✕"
- [ ] Có welcome message từ bot
- [ ] Input field focus khi mở
- [ ] Nhập tin nhắn + Enter → gửi được
- [ ] Click "Gửi" button → gửi được
- [ ] Tin nhắn user hiển thị (blue, phải)
- [ ] Loading animation hiển thị
- [ ] AI response hiển thị (gray, trái)
- [ ] Scroll xuống auto khi có tin nhắn mới
- [ ] Click "✕" → modal đóng
- [ ] Có error handling

---

## ✨ EXPECTED BEHAVIOR:

```
User: "Giá GPU RTX 5090?"
↓
[Loading...]
↓
Bot: "GPU NVIDIA RTX 5090 là card cao cấp nhất hiện nay...
	   Giá tại PC Store: 45-50 triệu đ
	   Bạn có muốn tư vấn cấu hình PC gaming phù hợp không?"
```

---

## 🔑 Nếu lỗi "Chatbot API is offline":

1. **Kiểm tra API Key:**
   ```powershell
   dotnet user-secrets list
   ```
   Nên thấy: `OpenAI:ApiKey = sk-proj-...`

2. **Kiểm tra .env.local:**
   ```
   cat .env.local
   ```
   Nên thấy: `OpenAI__ApiKey=sk-proj-...`

3. **Kiểm tra appsettings:**
   ```
   cat appsettings.json
   ```
   Nên có: `"OpenAI": { "ApiKey": "..." }`

4. **Restart server:**
   ```powershell
   # Stop (Ctrl+C)
   # Rồi chạy lại
   dotnet run
   ```

---

## 📞 LIÊN HỆ/SUPPORT:

Nếu gặp lỗi, kiểm tra:

1. ✅ API Key đã set chưa?
   ```powershell
   dotnet user-secrets list
   ```

2. ✅ Server đang chạy?
   ```
   https://localhost:5001
   ```

3. ✅ Browser console có error?
   ```
   F12 → Console → Xem logs
   ```

4. ✅ Network tab show API call?
   ```
   F12 → Network → Filter "chatbot"
   ```

---

## 🎉 HOÀN THÀNH!

Khi mọi thứ hoạt động, bạn có:
- ✅ Chatbot UI đẹp mắt
- ✅ Real-time AI responses
- ✅ Knowledge base đầy đủ
- ✅ Error handling hoàn chỉnh
- ✅ Mobile responsive

**Bắt đầu test: `dotnet run` 🚀**
