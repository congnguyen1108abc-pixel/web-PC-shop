# API Pagination & Response Format Guide

## 📋 Tổng Quan

Tất cả các API danh sách đã được cập nhật để hỗ trợ **phân trang** và **response chuẩn hóa**. Điều này giúp:
- ✅ Tối ưu hiệu năng khi dữ liệu lớn
- ✅ Giảm tải bandwidth
- ✅ Cải thiện UX (load từng trang)
- ✅ Chống DoS attack (giới hạn PageSize max 100)

---

## 🔄 Response Format

### Thành công (200 OK)
```json
{
  "items": [
    { "id": 1, "name": "Product 1", ... },
    { "id": 2, "name": "Product 2", ... }
  ],
  "totalRecords": 250,
  "pageNumber": 1,
  "pageSize": 10,
  "totalPages": 25,
  "hasPreviousPage": false,
  "hasNextPage": true
}
```

### Lỗi (400/500)
```json
{
  "success": false,
  "statusCode": 400,
  "message": "PageSize không được vượt quá 100",
  "errors": null
}
```

---

## 📌 Các API Có Phân Trang

### 1. **Products - Danh sách sản phẩm**
```
GET /api/products?pageNumber=1&pageSize=10&categoryId=1&sortBy=Newest
```

**Query Parameters:**
| Param | Type | Default | Max | Mô tả |
|-------|------|---------|-----|-------|
| `pageNumber` | int | 1 | - | Trang hiện tại (bắt đầu từ 1) |
| `pageSize` | int | 10 | 100 | Số items mỗi trang |
| `categoryId` | int? | null | - | Lọc theo danh mục |
| `brandId` | int? | null | - | Lọc theo thương hiệu |
| `keyword` | string? | null | - | Tìm kiếm theo tên/SKU |
| `minPrice` | decimal? | null | - | Giá tối thiểu |
| `maxPrice` | decimal? | null | - | Giá tối đa |
| `sortBy` | string | "Newest" | - | Sắp xếp: Newest, PriceLowHigh, PriceHighLow, BestSelling, Name |

**Ví dụ:**
```
GET /api/products?pageNumber=1&pageSize=20&categoryId=5&sortBy=BestSelling
```

---

### 2. **Orders - Lịch sử đơn hàng User**
```
GET /api/orders/history/{userId}?pageNumber=1&pageSize=10&status=Hoàn tất
```

**Query Parameters:**
| Param | Type | Default | Max | Mô tả |
|-------|------|---------|-----|-------|
| `pageNumber` | int | 1 | - | Trang hiện tại |
| `pageSize` | int | 10 | 100 | Số items mỗi trang |
| `status` | string? | null | - | Lọc theo trạng thái |

**Ví dụ:**
```
GET /api/orders/history/5?pageNumber=1&pageSize=15&status=Hoàn tất
```

---

### 3. **Admin Orders - Quản lý đơn hàng**
```
GET /api/admin/orders?pageNumber=1&pageSize=10&status=Chờ xác nhận
```

**Query Parameters:**
| Param | Type | Default | Max | Mô tả |
|-------|------|---------|-----|-------|
| `pageNumber` | int | 1 | - | Trang hiện tại |
| `pageSize` | int | 10 | 100 | Số items mỗi trang |
| `status` | string? | null | - | Lọc theo trạng thái |
| `userId` | int? | null | - | Lọc theo user |
| `keyword` | string? | null | - | Tìm kiếm theo tên/email/OrderID |
| `dateFrom` | datetime? | null | - | Từ ngày |
| `dateTo` | datetime? | null | - | Đến ngày |

**Ví dụ:**
```
GET /api/admin/orders?pageNumber=1&pageSize=20&status=Đang giao&dateFrom=2024-01-01
```

---

### 4. **Reviews - Đánh giá sản phẩm**
```
GET /api/reviews/product/{productId}?pageNumber=1&pageSize=10
```

**Query Parameters:**
| Param | Type | Default | Max | Mô tả |
|-------|------|---------|-----|-------|
| `pageNumber` | int | 1 | - | Trang hiện tại |
| `pageSize` | int | 10 | 100 | Số items mỗi trang |

**Ví dụ:**
```
GET /api/reviews/product/42?pageNumber=1&pageSize=15
```

---

### 5. **Admin Reviews - Quản lý đánh giá**
```
GET /api/admin/reviews?pageNumber=1&pageSize=10&isApproved=false
```

**Query Parameters:**
| Param | Type | Default | Max | Mô tả |
|-------|------|---------|-----|-------|
| `pageNumber` | int | 1 | - | Trang hiện tại |
| `pageSize` | int | 10 | 100 | Số items mỗi trang |
| `productId` | int? | null | - | Lọc theo sản phẩm |
| `isApproved` | bool? | null | - | Lọc theo trạng thái duyệt |
| `keyword` | string? | null | - | Tìm kiếm |

**Ví dụ:**
```
GET /api/admin/reviews?pageNumber=1&pageSize=20&isApproved=false
```

---

### 6. **Notifications - Thông báo**
```
GET /api/notifications/user/{userId}?pageNumber=1&pageSize=20&isRead=false
```

**Query Parameters:**
| Param | Type | Default | Max | Mô tả |
|-------|------|---------|-----|-------|
| `pageNumber` | int | 1 | - | Trang hiện tại |
| `pageSize` | int | 20 | 100 | Số items mỗi trang |
| `isRead` | bool? | null | - | Lọc theo trạng thái đã đọc |

**Ví dụ:**
```
GET /api/notifications/user/5?pageNumber=1&pageSize=30&isRead=false
```

---

## ⚙️ Validation Rules

### PageNumber
- ✅ Phải >= 1
- ❌ Nếu < 1 → tự động set = 1

### PageSize
- ✅ Phải >= 1 và <= 100
- ❌ Nếu < 1 → tự động set = default (10 hoặc 20)
- ❌ Nếu > 100 → tự động set = 100 (chống DoS)

### Ví dụ Validation
```csharp
// Input: pageNumber=-5, pageSize=200
// Output: pageNumber=1, pageSize=100
```

---

## 📊 Metadata Trả Về

Mỗi response phân trang chứa:

| Field | Type | Mô tả |
|-------|------|-------|
| `items` | Array | Danh sách items trong trang hiện tại |
| `totalRecords` | int | Tổng số bản ghi (không phân trang) |
| `pageNumber` | int | Trang hiện tại |
| `pageSize` | int | Số items mỗi trang |
| `totalPages` | int | Tổng số trang |
| `hasPreviousPage` | bool | Có trang trước không |
| `hasNextPage` | bool | Có trang sau không |

---

## 🔍 Ví Dụ Thực Tế

### Lấy trang 2 sản phẩm, 15 items/trang, lọc theo danh mục 3
```bash
curl -X GET "https://api.pcstore.com/api/products?pageNumber=2&pageSize=15&categoryId=3" \
  -H "Accept: application/json"
```

**Response:**
```json
{
  "items": [
    {
      "productId": 16,
      "productName": "RTX 4070",
      "price": 15000000,
      "discountPrice": 14500000,
      "stockQuantity": 25,
      "soldCount": 150,
      "avgRating": 4.8,
      "reviewCount": 45
    },
    ...
  ],
  "totalRecords": 287,
  "pageNumber": 2,
  "pageSize": 15,
  "totalPages": 20,
  "hasPreviousPage": true,
  "hasNextPage": true
}
```

---

## 🛡️ Rate Limiting

Các API danh sách áp dụng rate limiting:

| Endpoint | Limit | Window |
|----------|-------|--------|
| GET /api/products | 300 | 1 phút (global) |
| GET /api/orders/history | 300 | 1 phút (global) |
| GET /api/admin/orders | 300 | 1 phút (global) |
| GET /api/reviews | 300 | 1 phút (global) |
| GET /api/notifications | 300 | 1 phút (global) |

---

## 📝 Frontend Implementation

### JavaScript/Fetch
```javascript
async function getProducts(pageNumber = 1, pageSize = 10, filters = {}) {
  const params = new URLSearchParams({
    pageNumber,
    pageSize,
    ...filters
  });
  
  const response = await fetch(`/api/products?${params}`);
  const data = await response.json();
  
  return {
    items: data.items,
    totalPages: data.totalPages,
    currentPage: data.pageNumber
  };
}

// Sử dụng
const result = await getProducts(1, 20, { categoryId: 5, sortBy: 'BestSelling' });
```

### React Hook
```javascript
const [products, setProducts] = useState([]);
const [page, setPage] = useState(1);
const [totalPages, setTotalPages] = useState(0);

useEffect(() => {
  fetch(`/api/products?pageNumber=${page}&pageSize=10`)
    .then(r => r.json())
    .then(data => {
      setProducts(data.items);
      setTotalPages(data.totalPages);
    });
}, [page]);
```

---

## ✅ Checklist Triển Khai

- [ ] Chạy DATABASE_PC.sql để tạo stored procedures
- [ ] Build project C# để compile DTOs mới
- [ ] Test các endpoint với Postman/Swagger
- [ ] Cập nhật frontend để xử lý PagedResult
- [ ] Kiểm tra rate limiting hoạt động
- [ ] Monitor performance trên production

---

## 🐛 Troubleshooting

### Lỗi: "PageSize không được vượt quá 100"
→ Giảm PageSize xuống <= 100

### Lỗi: "PageNumber phải >= 1"
→ Đảm bảo PageNumber >= 1

### Response trống (items = [])
→ Kiểm tra filters có quá hạn chế không, hoặc page vượt quá totalPages

### Performance chậm
→ Giảm PageSize, thêm filters để giảm dữ liệu

---

**Cập nhật lần cuối:** 2024
**Phiên bản API:** v1.0
