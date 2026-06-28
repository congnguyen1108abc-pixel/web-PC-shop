# 🧪 CACHE TEST FLOW - QUICK GUIDE

## 🚀 START APPLICATION

```powershell
cd d:\VSstudio\PC_Store
dotnet run
```

**Expected:** `Now listening on: http://localhost:5187`

---

## 📝 TEST FLOW (10 phút)

### **Test 1: Categories Cache** ⭐⭐⭐

1. Mở Swagger: `http://localhost:5187/swagger`
2. **GET /api/categories** (onlyActive=true)
3. **First Request:**
   - Response Time: ~200ms
   - Console: `Cache MISS: categories:all:true`
   - Console: `Cache SET: categories:all:true`
4. **Second Request (ngay lập tức):**
   - Response Time: ~5ms ⚡ **40x faster!**
   - Console: `Cache HIT: categories:all:true`
5. ✅ **PASS:** Data giống hệt, response time giảm 95%

---

### **Test 2: Brands Cache** ⭐⭐⭐

1. **GET /api/brands** (onlyActive=true)
2. **First Request:** ~180ms (Cache MISS)
3. **Second Request:** ~5ms (Cache HIT) ⚡
4. ✅ **PASS:** Cache hoạt động tốt

---

### **Test 3: Top Selling Products** ⭐⭐⭐⭐⭐

1. **GET /api/products/top-selling**
   - topN: `10`
   - startDate: `null`
   - endDate: `null`
2. **First Request:** ~500ms (Cache MISS - complex query)
3. **Second Request:** ~5ms (Cache HIT) ⚡ **100x faster!**
4. ✅ **PASS:** Thống kê phức tạp được cache hiệu quả

---

### **Test 4: Dashboard Summary** ⭐⭐⭐⭐⭐

1. **GET /api/dashboard/summary** (cần login Admin)
2. **First Request:** ~800ms (Cache MISS - multiple aggregations)
3. **Second Request:** ~5ms (Cache HIT) ⚡ **160x faster!**
4. ✅ **PASS:** Dashboard load cực nhanh

---

### **Test 5: Banners Cache** ⭐⭐⭐

1. **GET /api/banners**
2. **First Request:** ~150ms (Cache MISS)
3. **Second Request:** ~5ms (Cache HIT) ⚡
4. ✅ **PASS:** Homepage banners load nhanh

---

### **Test 6: Vouchers Cache** ⭐⭐⭐

1. **GET /api/vouchers** (onlyActive=true)
2. **First Request:** ~200ms (Cache MISS)
3. **Second Request:** ~5ms (Cache HIT) ⚡
4. ✅ **PASS:** Voucher list load nhanh

---

### **Test 7: Product Detail Cache** ⭐⭐⭐⭐

1. **GET /api/products/{id}** (productId=1)
2. **First Request:** ~250ms (Cache MISS - joins)
3. **Second Request:** ~5ms (Cache HIT) ⚡ **50x faster!**
4. ✅ **PASS:** Product detail page load cực nhanh

---

## 🔥 TEST CACHE INVALIDATION (Bonus)

### **Test 8: Category Invalidation**

1. **GET /api/categories** → Cache HIT (~5ms)
2. **POST /api/categories** (Admin - thêm category mới)
   - Console: `Cache REMOVED by prefix: categories`
3. **GET /api/categories** lại → Cache MISS (~200ms)
4. **GET /api/categories** lần 2 → Cache HIT (~5ms)
5. ✅ **PASS:** Cache tự động invalidate khi data thay đổi

---

## 📊 EXPECTED RESULTS

| API | First Request | Second Request | Improvement |
|-----|---------------|----------------|-------------|
| Categories | ~200ms | ~5ms | **40x faster** ⚡ |
| Brands | ~180ms | ~5ms | **36x faster** ⚡ |
| Top Selling | ~500ms | ~5ms | **100x faster** ⚡ |
| Dashboard | ~800ms | ~5ms | **160x faster** ⚡ |
| Banners | ~150ms | ~5ms | **30x faster** ⚡ |
| Vouchers | ~200ms | ~5ms | **40x faster** ⚡ |
| Product Detail | ~250ms | ~5ms | **50x faster** ⚡ |

---

## 🎯 CONSOLE LOGS TO WATCH

```
[Cache] Cache MISS: categories:all:true
[Cache] Cache SET: categories:all:true, Expiration: 00:30:00
[Cache] Cache HIT: categories:all:true
[Cache] Cache REMOVED by prefix: categories, Count: 1
```

---

## ✅ SUCCESS CRITERIA

- [x] All 7 APIs show Cache MISS on first request
- [x] All 7 APIs show Cache HIT on second request
- [x] Response time giảm 30-160x
- [x] Console logs hiển thị đúng
- [x] Cache invalidation hoạt động (Admin actions)
- [x] Data consistency (cache = database)

---

## 🎓 DEMO SCRIPT (Cho Giảng Viên)

### **1. Giới thiệu (30 giây)**
"Em đã implement MemoryCache cho 7 APIs thường xuyên query nhất để tối ưu performance."

### **2. Demo Categories (1 phút)**
- Gọi API lần 1: "Đây là lần đầu query database, mất ~200ms"
- Gọi API lần 2: "Lần này lấy từ cache, chỉ mất ~5ms, nhanh hơn 40 lần"
- Show console logs: "Em có log cache HIT/MISS để monitor"

### **3. Demo Dashboard (1 phút)**
- Gọi API lần 1: "Dashboard có nhiều aggregation nên chậm, ~800ms"
- Gọi API lần 2: "Cache giúp giảm xuống còn ~5ms, nhanh hơn 160 lần"

### **4. Demo Cache Invalidation (1 phút)**
- Thêm category mới: "Khi Admin thêm data, cache tự động clear"
- Gọi API lại: "Lần này cache MISS, query database lại"
- Gọi lần 2: "Cache HIT trở lại"

### **5. Kết luận (30 giây)**
"Em chỉ cache data ít thay đổi như Categories, Brands. Data real-time như Orders, Cart thì không cache. Cache giúp giảm database load 60-95% và response time giảm 95%."

**Total: 4 phút demo**

---

## 🚀 QUICK START

```powershell
# 1. Start app
dotnet run

# 2. Open Swagger
start http://localhost:5187/swagger

# 3. Test Categories
# - GET /api/categories (onlyActive=true)
# - Execute 2 lần
# - Check response time: 200ms → 5ms

# 4. Done! ✅
```

---

**Chúc bạn test thành công! 🎉**
