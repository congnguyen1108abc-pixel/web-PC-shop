# 📹 Hướng Dẫn Tải Lên Banner Video Clip

## 🎯 Tổng Quan
Hệ thống cho phép bạn tải lên video clip mới cho banner trang chủ và lưu thông tin vào SQL database.

## 📋 Các Thành Phần

### 1. **SQL Database Updates** (`UPDATE_BANNERS_WITH_VIDEO.sql`)
```sql
-- Thêm các cột mới:
- VideoURL: Lưu đường dẫn video
- VideoThumbnail: Lưu ảnh thumbnail
- BannerType: Phân biệt giữa Image/Video

-- Stored Procedures:
- sp_GetHomepageBanners: Lấy banner video cho trang chủ
- sp_UpsertBanner: Thêm/cập nhật banner
```

### 2. **API Controller** (`BannerController.cs`)
Endpoints:
```
POST   /api/banner/upload-video    → Upload video + thumbnail
GET    /api/banner/videos           → Lấy danh sách video
DELETE /api/banner/video/{id}       → Xóa video banner
```

### 3. **Admin Upload Page** (`admin-banner-upload.html`)
- Giao diện đẹp, dễ sử dụng
- Preview video/thumbnail trước khi upload
- Hỗ trợ các định dạng: MP4, AVI, MOV, WEBM

---

## 🚀 Hướng Dẫn Sử Dụng

### Step 1: Chạy SQL Update
```sql
-- Mở SQL Server Management Studio
-- Chạy file: UPDATE_BANNERS_WITH_VIDEO.sql
```

**Kết quả:**
- Cột VideoURL, VideoThumbnail, BannerType được thêm vào Banners table
- Tạo View vw_ActiveBanners
- Tạo 2 Stored Procedures

### Step 2: Truy Cập Upload Page
```
URL: https://localhost:7190/admin-banner-upload
hoặc: http://localhost:7190/admin-banner-upload
```

### Step 3: Upload Video
1. **Nhập Tiêu đề**: VD "ROG Astral RTX 5090"
2. **Chọn Video File**: Click button chọn file video (.mp4, .avi, etc)
3. **Chọn Thumbnail (Tùy chọn)**: Ảnh 16:9 sẽ tốt nhất
4. **Nhập Link URL (Tùy chọn)**: VD "/Products"
5. **Nhập Thứ tự**: Số hiển thị (1 = hiển thị đầu tiên)
6. **Click "Tải Lên"**

### Step 4: Kiểm Tra Kết Quả
Sau khi upload thành công, bạn sẽ thấy:
```json
{
  "success": true,
  "message": "Video uploaded successfully",
  "data": {
    "title": "ROG Astral GeForce RTX 5090",
    "videoUrl": "/assets/video/banner_video_20240115143022_a1b2c3d4.mp4",
    "thumbnailUrl": "/assets/image/banner_thumb_20240115143022_e5f6g7h8.jpg",
    "linkUrl": null,
    "displayOrder": 1,
    "bannerType": "Video",
    "isActive": true
  }
}
```

### Step 5: Cập Nhật Database (SQL)
Sử dụng Stored Procedure sp_UpsertBanner:

```sql
EXEC sp_UpsertBanner
    @Title = 'ROG Astral GeForce RTX 5090',
    @ImageURL = '/assets/video/banner_video_20240115143022_a1b2c3d4.mp4',
    @VideoURL = '/assets/video/banner_video_20240115143022_a1b2c3d4.mp4',
    @VideoThumbnail = '/assets/image/banner_thumb_20240115143022_e5f6g7h8.jpg',
    @DisplayOrder = 1,
    @BannerType = 'Video',
    @IsActive = 1;
```

---

## 📁 Cấu Trúc Thư Mục

```
wwwroot/
├── assets/
│   ├── video/              ← Video clips được lưu ở đây
│   │   ├── banner_video_20240115143022_a1b2c3d4.mp4
│   │   └── banner_video_20240115143025_x9y8z7w6.mp4
│   └── image/              ← Thumbnail được lưu ở đây
│       ├── banner_thumb_20240115143022_e5f6g7h8.jpg
│       └── ...
```

---

## 💾 Database Schema

### Banners Table
```sql
CREATE TABLE Banners (
    BannerID          INT PRIMARY KEY IDENTITY(1,1),
    Title             NVARCHAR(200) NOT NULL,
    ImageURL          NVARCHAR(500) NOT NULL,
    VideoURL          NVARCHAR(500) NULL,                    -- ← Mới
    VideoThumbnail    NVARCHAR(500) NULL,                    -- ← Mới
    BannerType        NVARCHAR(50) DEFAULT 'Image',          -- ← Mới
    LinkURL           NVARCHAR(500) NULL,
    DisplayOrder      INT DEFAULT 0,
    StartDate         DATETIME NULL,
    EndDate           DATETIME NULL,
    IsActive          BIT DEFAULT 1,
    CreatedAt         DATETIME DEFAULT GETDATE()
);
```

### View: vw_ActiveBanners
```sql
-- Lấy tất cả banner active
SELECT * FROM vw_ActiveBanners;
-- Kết quả: BannerID, Title, VideoURL, VideoThumbnail, BannerType, LinkURL, ...
```

---

## 🔧 Stored Procedures

### 1. sp_GetHomepageBanners
```sql
EXEC sp_GetHomepageBanners;
```
**Output:** Video banner đầu tiên (theo DisplayOrder) để hiển thị trên homepage

### 2. sp_UpsertBanner
```sql
-- Thêm banner mới
EXEC sp_UpsertBanner
    @Title = 'Video Name',
    @ImageURL = '/assets/video/...',
    @VideoURL = '/assets/video/...',
    @VideoThumbnail = '/assets/image/...',
    @DisplayOrder = 1,
    @BannerType = 'Video',
    @IsActive = 1;

-- Cập nhật banner
EXEC sp_UpsertBanner
    @BannerID = 5,
    @Title = 'Updated Title',
    @ImageURL = '/assets/video/...',
    @VideoURL = '/assets/video/...',
    @VideoThumbnail = '/assets/image/...',
    @DisplayOrder = 2,
    @BannerType = 'Video',
    @IsActive = 1;
```

---

## 🌐 Lấy Banner Video Trên Homepage

### Frontend (JavaScript)
```javascript
// Lấy video banner
async function getHomepageBanner() {
    const response = await fetch('/api/banner/videos');
    const data = await response.json();
    
    if (data.success && data.data.length > 0) {
        const banner = data.data[0];
        document.querySelector('.hero video').src = banner.videoUrl;
    }
}

getHomepageBanner();
```

### Backend (C# Controller)
```csharp
[HttpGet("video/{bannerID}")]
public async Task<IActionResult> GetBannerVideo(int bannerID)
{
    using (SqlConnection conn = new SqlConnection(_connectionString))
    {
        using (SqlCommand cmd = new SqlCommand("sp_GetHomepageBanners", conn))
        {
            cmd.CommandType = CommandType.StoredProcedure;
            conn.Open();
            
            SqlDataReader reader = cmd.ExecuteReader();
            var banner = new { };
            
            while (reader.Read())
            {
                banner = new
                {
                    videoUrl = reader["VideoURL"].ToString(),
                    thumbnail = reader["VideoThumbnail"].ToString(),
                };
            }
            
            return Ok(banner);
        }
    }
}
```

---

## ✅ Checklist

- [x] SQL database update (thêm cột VideoURL, VideoThumbnail, BannerType)
- [x] Tạo BannerController API
- [x] Tạo Admin Upload Page
- [x] Hỗ trợ upload video + thumbnail
- [x] Lưu file vào thư mục assets/video
- [ ] Kết nối API với database (INSERT banner info)
- [ ] Hiển thị video banner trên homepage từ database
- [ ] Tạo admin panel để quản lý danh sách banner

---

## 🐛 Troubleshooting

### Video không hiển thị
1. Kiểm tra VideoURL trong database
2. Kiểm tra file tồn tại trong wwwroot/assets/video
3. Kiểm tra browser console có lỗi gì

### Upload lỗi
1. Kiểm tra file size < 500MB
2. Kiểm tra định dạng video (.mp4, .avi, .mov, .webm)
3. Kiểm tra thư mục assets/video có quyền ghi

### Database lỗi
1. Chạy UPDATE_BANNERS_WITH_VIDEO.sql lại
2. Kiểm tra connection string trong appsettings.json

---

## 📞 Hỗ Trợ
Nếu có vấn đề, kiểm tra:
- Browser Console (F12 → Console tab)
- Server Logs
- SQL Server Error Logs
