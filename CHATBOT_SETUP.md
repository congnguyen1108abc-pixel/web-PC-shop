# 🚀 HƯỚNG DẪN CẤU HÌNH CHATBOT AI PC_STORE

## ✅ Hiện tại đã hoàn thành:

### 1. **Files đã tạo:**
- ✅ `Services/ChatbotService.cs` - Service xử lý AI
- ✅ `Controllers/ChatbotController.cs` - API Controller
- ✅ `Page/chatbot.html` - Standalone chatbot page
- ✅ **Tích hợp chatbot vào `Page/homepage.html`** - Floating chatbot button
- ✅ `Program.cs` - Đã config dependency injection + CORS
- ✅ `PC_Store.csproj` - Đã thêm NuGet package Google.Generative.AI
- ✅ `appsettings.json` - Đã thêm Gemini config

### 2. **Tính năng đã có:**
- 💬 Floating chatbot button ở góc dưới phải homepage
- 🎨 Beautiful modal dialog với gradient design
- ⚡ Real-time message với animation
- 🤖 AI response từ Google Gemini API
- 📱 Responsive design (mobile-friendly)
- ⌨️ Support Enter key để gửi tin nhắn
- 🔄 Loading animation khi chờ AI response
- 🛠️ Error handling & logging

---

## 🔑 BƯỚC 1: Lấy Google Gemini API Key

### Cách 1: Sử dụng Google AI Studio (FREE - Easiest)
1. Truy cập: **https://aistudio.google.com/app/apikeys**
2. Click "Create API key"
3. Chọn "Create API key in new Google Cloud project"
4. Copy API Key (dạng: `AIzaXXXXXXXXXXXXXXXXXXXXXXXX`)
5. **KHÔNG** push API key lên GitHub - giữ bí mật!

### Cách 2: Sử dụng Google Cloud Console
1. Truy cập: https://console.cloud.google.com/
2. Tạo project mới hoặc chọn project có sẵn
3. Enable "Generative Language API"
4. Tạo API key ở "Credentials"
5. Copy API Key

---

## ⚙️ BƯỚC 2: Cấu hình API Key

### **Option A: Cấu hình qua appsettings.json (Development)**

Mở file `appsettings.json` và cập nhật:

```json
{
  "Logging": {
	"LogLevel": {
	  "Default": "Information",
	  "Microsoft.AspNetCore": "Warning"
	}
  },
  "AllowedHosts": "*",
  "Gemini": {
	"ApiKey": "AIzaXXXXXXXXXXXXXXXXXXXXXXXX"
  }
}
```

**⚠️ CẢNH BÁO:** Không commit file này lên GitHub nếu có API key thực!

### **Option B: Cấu hình qua Environment Variable (Bảo mật hơn)**

#### Trên Windows (PowerShell):
```powershell
$env:Gemini__ApiKey = "AIzaXXXXXXXXXXXXXXXXXXXXXXXX"
```

#### Trên Windows (Command Prompt):
```cmd
set Gemini__ApiKey=AIzaXXXXXXXXXXXXXXXXXXXXXXXX
```

#### Trên Linux/Mac:
```bash
export Gemini__ApiKey="AIzaXXXXXXXXXXXXXXXXXXXXXXXX"
```

#### Trên Visual Studio:
1. Mở **Tools** → **Options** → **Debugging** → **General**
2. Hoặc cấu hình trong `launchSettings.json`:

```json
{
  "profiles": {
	"PC_Store": {
	  "environmentVariables": {
		"ASPNETCORE_ENVIRONMENT": "Development",
		"Gemini__ApiKey": "AIzaXXXXXXXXXXXXXXXXXXXXXXXX"
	  }
	}
  }
}
```

### **Option C: Sử dụng User Secrets (Recommended - NHẤT)**

Dùng User Secrets để lưu API key an toàn (không lên GitHub):

```powershell
# Tại thư mục project
cd G:\PC_Store

# Khởi tạo User Secrets
dotnet user-secrets init

# Set API Key
dotnet user-secrets set "Gemini:ApiKey" "AIzaXXXXXXXXXXXXXXXXXXXXXXXX"

# Kiểm tra
dotnet user-secrets list
```

---

## 🚀 BƯỚC 3: Chạy Application

### Cách 1: Chạy từ Visual Studio
1. Mở project trong Visual Studio
2. **F5** hoặc click **Run** button
3. App sẽ start ở: `https://localhost:5001` hoặc `http://localhost:5000`

### Cách 2: Chạy từ PowerShell
```powershell
cd G:\PC_Store
dotnet run
```

### Cách 3: Chạy với environment variable
```powershell
$env:Gemini__ApiKey = "AIzaXXXXXXXXXXXXXXXXXXXXXXXX"
dotnet run
```

---

## 🧪 BƯỚC 4: Test Chatbot

### Test trên Homepage:
1. Mở: `https://localhost:5001/` hoặc `https://localhost:5001/Homepage`
2. Tìm **💬 button** ở góc dưới phải
3. Click để mở chatbot
4. Nhập câu hỏi và gửi
5. Chatbot sẽ trả lời

### Test Standalone Chatbot Page:
1. Mở: `https://localhost:5001/Chatbot`
2. Nhập câu hỏi và gửi

### Test API trực tiếp:
1. Mở: `https://localhost:5001/api/chatbot/health`
   - Kết quả: `{"status":"Chatbot API is running"}`

2. Dùng Postman hoặc curl để test:
```bash
curl -X POST "https://localhost:5001/api/chatbot/message" \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"Giá CPU i9 bao nhiêu?\"}"
```

---

## 💡 Các Câu Hỏi Test:

Thử hỏi chatbot:
- ✅ "Bạn là ai?"
- ✅ "Giá GPU RTX 5090 bao nhiêu?"
- ✅ "Có khuyến mãi không?"
- ✅ "Hướng dẫn chọn laptop gaming?"
- ✅ "SSD nào tốt nhất hiện nay?"
- ✅ "Hỗ trợ giờ mấy?"
- ✅ "Bảo hành mấy năm?"
- ✅ "Có giao hàng toàn quốc không?"

---

## 🔍 Troubleshooting:

### ❌ Error: "Gemini:ApiKey không được cấu hình"
**Giải pháp:**
- Kiểm tra appsettings.json hoặc environment variable
- Đảm bảo API Key không để trống

### ❌ Error: 401 Unauthorized
**Giải pháp:**
- API Key bị sai hoặc expired
- Lấy API Key mới từ https://aistudio.google.com/app/apikeys

### ❌ Error: "Cannot connect to Chatbot API"
**Giải pháp:**
- Kiểm tra server đã start chưa
- Kiểm tra port (5000/5001)
- Xem browser console (F12) để xem chi tiết error

### ❌ Chatbot không trả lời
**Giải pháp:**
- Kiểm tra internet connection
- Kiểm tra Google Gemini API quota
- Xem VS Output window để xem logs

---

## 📊 Cấu trúc API:

### **POST** `/api/chatbot/message`
```json
Request:
{
  "message": "Giá sản phẩm X bao nhiêu?"
}

Response:
{
  "reply": "Sản phẩm X có giá ... VNĐ"
}
```

### **GET** `/api/chatbot/health`
```json
Response:
{
  "status": "Chatbot API is running"
}
```

---

## 🎨 Tùy chỉnh Chatbot:

### 1. Thay đổi System Prompt (personality)
- File: `Services/ChatbotService.cs`
- Method: `GetSystemPrompt()`
- Sửa đoạn text để thay đổi cách chatbot trả lời

### 2. Thay đổi giao diện:
- File: `Page/homepage.html` (dòng CSS Chatbot)
- Hoặc `Page/chatbot.html`
- Sửa colors, sizes, animations

### 3. Thay đổi Model AI:
- File: `Services/ChatbotService.cs`
- Dòng: `model: "gemini-pro"` → `model: "gemini-pro-vision"` (với image)

---

## 📈 Nâng cao - Training thêm:

### Thêm Vector Database (Optional):
- Lưu knowledge base về sản phẩm PC Store
- Sử dụng Pinecone, Weaviate, hoặc Milvus
- Chatbot sẽ trả lời chính xác hơn

### Thêm Database để lưu history:
- Lưu conversation history
- Analytics: Câu hỏi phổ biến, user engagement
- Feedback từ user

### Thêm Multi-language Support:
- Tự động detect language
- Trả lời bằng language của user
- Support English, Vietnamese, etc.

### Thêm Button commands:
- Quick reply buttons ("🛍️ Xem sản phẩm", "❓ FAQ", etc.)
- Suggest các câu hỏi phổ biến

---

## ✨ Features đã hoàn thành:

| Feature | Status |
|---------|--------|
| Floating Chatbot Button | ✅ |
| Beautiful Modal Dialog | ✅ |
| Real-time AI Response | ✅ |
| Error Handling | ✅ |
| Loading Animation | ✅ |
| Responsive Design | ✅ |
| Enter Key Support | ✅ |
| Message History (Session) | ✅ |
| Welcome Message | ✅ |
| Health Check API | ✅ |
| Standalone Chatbot Page | ✅ |
| System Prompt Training | ✅ |

---

## 🎉 Kế tiếp:

Sau khi cấu hình API Key, bạn có thể:
1. ✅ Chat với AI trực tiếp trên homepage
2. ✅ Tùy chỉnh personality của chatbot
3. ✅ Thêm knowledge base về sản phẩm
4. ✅ Tích hợp database để lưu history
5. ✅ Deploy lên server

---

**Bắt đầu test ngay: https://localhost:5001/**
