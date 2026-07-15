# 🖥️ PC Store - Website Bán Linh Kiện Máy Tính

Website thương mại điện tử chuyên bán linh kiện máy tính, gaming gear, xây dựng cấu hình PC.

## 🛠️ Yêu cầu hệ thống

- **.NET 8.0 SDK** — [Tải tại đây](https://dotnet.microsoft.com/download/dotnet/8.0)
- **SQL Server** (Express hoặc Developer) — [Tải tại đây](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
- **SQL Server Management Studio (SSMS)** — Khuyến nghị để chạy script SQL

## 🚀 Hướng dẫn cài đặt & chạy

### 1. Clone project

```bash
git clone https://github.com/GBYTE23/PC_Store.git
cd PC_Store
```

### 2. Tạo Database

Mở **SSMS**, kết nối vào SQL Server và chạy lần lượt các file SQL:

```
1. DATABASE_PC.sql          — Tạo database PC_Store, tables, indexes, triggers, stored procedures
2. SEED_GAMING_GEAR_PC_BUILD.sql  — Dữ liệu mẫu cho sản phẩm Gaming Gear & PC Build
3. create_admin.sql         — Tạo tài khoản Admin mặc định
4. alter_sp.sql             — Cập nhật stored procedures bổ sung
```

> ⚠️ **Lưu ý:** File `DATABASE_PC.sql` sẽ tạo database tên `PC_Store`. Nếu bạn dùng SQL Server instance khác `localhost\SQLEXPRESS`, hãy sửa connection string trong `appsettings.json`.

### 3. Cấu hình appsettings.json

Kiểm tra và cập nhật connection string phù hợp với SQL Server của bạn:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost\\SQLEXPRESS;Database=PC_Store;Trusted_Connection=True;TrustServerCertificate=True"
  }
}
```

**Các cấu hình khác** (tùy chọn, có thể bỏ qua nếu chỉ test local):
- `Gemini:ApiKey` — API key Google Gemini cho chatbot AI
- `Brevo` / `Smtp` — Gửi email (quên mật khẩu, thông báo)
- `SePay` — Thanh toán online
- `GHN` — Giao hàng nhanh

### 4. Restore NuGet packages & chạy project

```bash
dotnet restore
dotnet run
```

Hoặc mở file `PC_Store.sln` bằng **Visual Studio 2022** và nhấn `F5`.

### 5. Truy cập website

- **Website:** http://localhost:5062 (hoặc port hiển thị trên terminal)
- **Swagger API:** http://localhost:5062/swagger

## 📁 Cấu trúc project

```
PC_Store/
├── Controllers/         # API Controllers (Auth, Products, Orders, Cart, ...)
├── Models/              # Entity models
├── DTOs/                # Data Transfer Objects
├── Services/            # Business logic layer
├── Repositories/        # Data access layer (Dapper + Stored Procedures)
├── Helpers/             # Utilities (DbHelper, ...)
├── Hubs/                # SignalR Hubs (Notification real-time)
├── Middleware/           # Custom middleware (Exception handling, ...)
├── Migrations/          # EF Core migrations (legacy)
├── Page/                # HTML pages (Homepage, Products, Admin, ...)
├── wwwroot/             # Static files (CSS, JS, Images)
├── Program.cs           # Application entry point & configuration
├── DATABASE_PC.sql      # Full database script
└── appsettings.json     # App configuration
```

## ✨ Tính năng chính

- 🏠 Trang chủ với banner slider, sản phẩm nổi bật
- 🛒 Giỏ hàng & Thanh toán (COD, Banking/SePay)
- 👤 Đăng ký / Đăng nhập (JWT + Refresh Token)
- 🔐 Quên mật khẩu qua email
- 📦 Quản lý đơn hàng & theo dõi trạng thái
- 🛡️ Bảo hành điện tử tự động
- ⭐ Đánh giá sản phẩm
- 🎮 Trang Gaming Gear & PC Build
- 🎟️ Hệ thống Voucher giảm giá
- 🤖 Chatbot AI (Google Gemini)
- 🔔 Thông báo real-time (SignalR)
- 📊 Admin Dashboard (quản lý sản phẩm, đơn hàng, người dùng, banner, ...)
- 🚚 Tích hợp GHN (Giao Hàng Nhanh)

## 👥 Nhóm phát triển

**GBYTE23**
