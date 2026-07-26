using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.Repositories.Base;
using PC_Store.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace PC_Store.Controllers;

[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/[controller]")]
public sealed class PriceHistoriesController : ControllerBase
{
    private readonly IDbRepository _db;
    private readonly ICacheService _cache;

    public PriceHistoriesController(IDbRepository db, ICacheService cache)
    {
        _db = db;
        _cache = cache;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<object>>> GetHistory()
    {
        var sql = @"
            SELECT 
                ph.HistoryID,
                ph.ProductID,
                p.ProductName,
                p.SKU,
                ph.OldPrice,
                ph.NewPrice,
                ph.ChangedBy,
                u.FullName AS ChangedByName,
                ph.ChangedAt,
                ph.EffectiveStartDate,
                ph.EffectiveEndDate,
                ph.Notes
            FROM PriceHistories ph
            JOIN Products p ON ph.ProductID = p.ProductID
            LEFT JOIN Users u ON ph.ChangedBy = u.UserID
            ORDER BY ph.ChangedAt DESC";

        var result = await _db.QueryRawAsync<dynamic>(sql);
        return Ok(result);
    }

    public sealed record ChangePriceRequest(
        int ProductId, 
        string NewPriceStr, 
        DateTime EffectiveStartDate,
        DateTime? EffectiveEndDate,
        string? Notes);

    [HttpPost("change-price")]
    public async Task<ActionResult> ChangePrice(ChangePriceRequest request)
    {
        // 1. Lấy thông tin người dùng đổi giá từ Token
        var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdStr, out var userId))
        {
            return Unauthorized(new { message = "Không xác định danh tính Admin" });
        }

        // 2. Lấy thông tin sản phẩm hiện tại
        var product = await _db.QuerySingleOrDefaultAsync<dynamic>(
            "SELECT Price, CostPrice, ProductName FROM Products WHERE ProductID = @ProductId", 
            new { request.ProductId });

        if (product is null)
            return BadRequest(new { message = "Sản phẩm không tồn tại" });

        // 3. Làm sạch chuỗi tiền tệ nhập vào (bỏ dấu chấm, dấu phẩy phân tách hàng nghìn)
        var cleanedPriceStr = (request.NewPriceStr ?? "")
            .Replace(",", "")
            .Replace(".", "")
            .Trim();

        if (!decimal.TryParse(cleanedPriceStr, out var newPrice) || newPrice < 0)
            return BadRequest(new { message = "Giá mới không hợp lệ. Vui lòng nhập số dương." });

        decimal oldPrice = (decimal)product.Price;

        // Nếu giá mới khác giá cũ hoặc có thời hạn hiệu lực mới
        if (newPrice != oldPrice)
        {
            // 4. Đóng ngày kết thúc hiệu lực của lịch sử cũ (nếu lịch sử cũ chưa kết thúc)
            var closeSql = @"
                UPDATE PriceHistories 
                SET EffectiveEndDate = @EffectiveStartDate 
                WHERE ProductID = @ProductId AND (EffectiveEndDate IS NULL OR EffectiveEndDate > @EffectiveStartDate)";
            await _db.ExecuteRawAsync(closeSql, new { request.ProductId, request.EffectiveStartDate });

            // 5. Thêm bản ghi lịch sử đổi giá mới
            var insertHistorySql = @"
                INSERT INTO PriceHistories 
                (ProductID, OldPrice, NewPrice, ChangedBy, ChangedAt, EffectiveStartDate, EffectiveEndDate, Notes)
                VALUES 
                (@ProductId, @OldPrice, @NewPrice, @ChangedBy, GETDATE(), @EffectiveStartDate, @EffectiveEndDate, @Notes)";

            await _db.ExecuteRawAsync(insertHistorySql, new
            {
                request.ProductId,
                OldPrice = oldPrice,
                NewPrice = newPrice,
                ChangedBy = userId,
                request.EffectiveStartDate,
                request.EffectiveEndDate,
                Notes = string.IsNullOrWhiteSpace(request.Notes) ? "Đổi giá thủ công qua trang Admin" : request.Notes
            });

            // 6. Cập nhật giá mới vào bảng Products (Nếu thời gian bắt đầu là hiện tại hoặc quá khứ)
            if (request.EffectiveStartDate <= DateTime.Now)
            {
                var updateProductSql = "UPDATE Products SET Price = @NewPrice, UpdatedAt = GETDATE() WHERE ProductID = @ProductId";
                await _db.ExecuteRawAsync(updateProductSql, new { NewPrice = newPrice, request.ProductId });
            }

            // 7. Xóa cache sản phẩm và báo cáo
            _cache.RemoveByPrefix("products");
            _cache.RemoveByPrefix("dashboard");

            return Ok(new
            {
                message = "Cập nhật giá bán thành công và đã ghi lịch sử đổi giá.",
                oldPrice = oldPrice,
                newPrice = newPrice
            });
        }

        return Ok(new { message = "Giá bán mới bằng với giá hiện hành. Không có thay đổi nào được thực hiện." });
    }
}
