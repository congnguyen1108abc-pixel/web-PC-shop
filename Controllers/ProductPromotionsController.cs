using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.Repositories.Base;
using PC_Store.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace PC_Store.Controllers;

[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/[controller]")]
public sealed class ProductPromotionsController : ControllerBase
{
    private readonly IDbRepository _db;
    private readonly ICacheService _cache;

    public ProductPromotionsController(IDbRepository db, ICacheService cache)
    {
        _db = db;
        _cache = cache;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<object>>> GetAll()
    {
        var sql = @"
            SELECT 
                pp.PromotionID,
                pp.ProductID,
                p.ProductName,
                p.SKU,
                p.Price AS OriginalPrice,
                pp.DiscountType,
                pp.DiscountValue,
                pp.StartDate,
                pp.EndDate,
                pp.Status,
                pp.CreatedAt
            FROM ProductPromotions pp
            JOIN Products p ON pp.ProductID = p.ProductID
            ORDER BY pp.CreatedAt DESC";

        var result = await _db.QueryRawAsync<dynamic>(sql);
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<object>> GetById(int id)
    {
        var sql = @"
            SELECT 
                pp.PromotionID,
                pp.ProductID,
                p.ProductName,
                p.SKU,
                p.Price AS OriginalPrice,
                pp.DiscountType,
                pp.DiscountValue,
                pp.StartDate,
                pp.EndDate,
                pp.Status,
                pp.CreatedAt
            FROM ProductPromotions pp
            JOIN Products p ON pp.ProductID = p.ProductID
            WHERE pp.PromotionID = @Id";

        var result = await _db.QuerySingleOrDefaultAsync<dynamic>(sql, new { Id = id });
        if (result is null)
            return NotFound(new { message = "Không tìm thấy chương trình khuyến mãi" });

        return Ok(result);
    }

    public sealed record CreatePromotionDto(
        int ProductId,
        string DiscountType,
        decimal DiscountValue,
        DateTime StartDate,
        DateTime EndDate,
        string Status);

    [HttpPost]
    public async Task<ActionResult> Create(CreatePromotionDto dto)
    {
        // Kiểm tra sản phẩm tồn tại
        var product = await _db.QuerySingleOrDefaultAsync<dynamic>(
            "SELECT ProductID, Price FROM Products WHERE ProductID = @ProductId", new { dto.ProductId });
        if (product is null)
            return BadRequest(new { message = "Sản phẩm không tồn tại" });

        if (dto.DiscountType != "Percentage" && dto.DiscountType != "FixedAmount")
            return BadRequest(new { message = "Loại giảm giá không hợp lệ (Percentage hoặc FixedAmount)" });

        if (dto.DiscountValue < 0)
            return BadRequest(new { message = "Giá trị giảm giá không được âm" });

        if (dto.DiscountType == "Percentage" && dto.DiscountValue > 100)
            return BadRequest(new { message = "Giảm giá phần trăm không được lớn hơn 100%" });

        if (dto.DiscountType == "FixedAmount" && dto.DiscountValue > (decimal)product.Price)
            return BadRequest(new { message = "Số tiền giảm giá không được lớn hơn giá gốc sản phẩm" });

        if (dto.StartDate >= dto.EndDate)
            return BadRequest(new { message = "Ngày bắt đầu phải trước ngày kết thúc" });

        var sql = @"
            INSERT INTO ProductPromotions (ProductID, DiscountType, DiscountValue, StartDate, EndDate, Status)
            VALUES (@ProductId, @DiscountType, @DiscountValue, @StartDate, @EndDate, @Status);
            SELECT CAST(SCOPE_IDENTITY() AS INT);";

        var id = await _db.QuerySingleOrDefaultAsync<int>(sql, dto);

        // Làm mới cache sản phẩm và báo cáo
        _cache.RemoveByPrefix("products");
        _cache.RemoveByPrefix("dashboard");

        return Ok(new { message = "Tạo chương trình khuyến mãi thành công", promotionId = id });
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult> Update(int id, CreatePromotionDto dto)
    {
        var promo = await _db.QuerySingleOrDefaultAsync<dynamic>(
            "SELECT PromotionID FROM ProductPromotions WHERE PromotionID = @Id", new { Id = id });
        if (promo is null)
            return NotFound(new { message = "Không tìm thấy chương trình khuyến mãi" });

        var product = await _db.QuerySingleOrDefaultAsync<dynamic>(
            "SELECT ProductID, Price FROM Products WHERE ProductID = @ProductId", new { dto.ProductId });
        if (product is null)
            return BadRequest(new { message = "Sản phẩm không tồn tại" });

        if (dto.DiscountType != "Percentage" && dto.DiscountType != "FixedAmount")
            return BadRequest(new { message = "Loại giảm giá không hợp lệ" });

        if (dto.DiscountValue < 0)
            return BadRequest(new { message = "Giá trị giảm giá không được âm" });

        if (dto.DiscountType == "Percentage" && dto.DiscountValue > 100)
            return BadRequest(new { message = "Giảm giá phần trăm không được lớn hơn 100%" });

        if (dto.DiscountType == "FixedAmount" && dto.DiscountValue > (decimal)product.Price)
            return BadRequest(new { message = "Số tiền giảm giá không được lớn hơn giá gốc sản phẩm" });

        if (dto.StartDate >= dto.EndDate)
            return BadRequest(new { message = "Ngày bắt đầu phải trước ngày kết thúc" });

        var sql = @"
            UPDATE ProductPromotions
            SET ProductID = @ProductId,
                DiscountType = @DiscountType,
                DiscountValue = @DiscountValue,
                StartDate = @StartDate,
                EndDate = @EndDate,
                Status = @Status
            WHERE PromotionID = @Id";

        await _db.ExecuteRawAsync(sql, new
        {
            Id = id,
            dto.ProductId,
            dto.DiscountType,
            dto.DiscountValue,
            dto.StartDate,
            dto.EndDate,
            dto.Status
        });

        // Làm mới cache sản phẩm và báo cáo
        _cache.RemoveByPrefix("products");
        _cache.RemoveByPrefix("dashboard");

        return Ok(new { message = "Cập nhật chương trình khuyến mãi thành công" });
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult> Delete(int id)
    {
        var sql = "DELETE FROM ProductPromotions WHERE PromotionID = @Id";
        var affected = await _db.ExecuteRawAsync(sql, new { Id = id });

        if (affected == 0)
            return NotFound(new { message = "Không tìm thấy chương trình khuyến mãi" });

        // Làm mới cache sản phẩm và báo cáo
        _cache.RemoveByPrefix("products");
        _cache.RemoveByPrefix("dashboard");

        return Ok(new { message = "Xóa chương trình khuyến mãi thành công" });
    }
}
